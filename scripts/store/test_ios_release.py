#!/usr/bin/env python3
"""Offline tests for iOS release switches, build waiting, listing and build selection.

No network: every App Store Connect call goes to an in-memory fake.
Run: python3 -m unittest scripts/store/test_ios_release.py
"""
from __future__ import annotations

import hashlib
import io
import json
import os
import struct
import sys
import tempfile
import unittest
import zlib
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))

import asc_release  # noqa: E402
import ios_release  # noqa: E402
import release_notes  # noqa: E402
import validate_catalog  # noqa: E402
from ios_release import ReleaseError, resolve_gates  # noqa: E402

ROOT = HERE.parents[1]
TAG = "v1.0.1"
VERSION = "1.0.1"
ALL_ON = {
    "IOS_RELEASE_AUTOMATION": "true",
    "IOS_UPLOAD_BUILD": "true",
    "IOS_UPLOAD_LISTING": "true",
    "IOS_UPLOAD_WHATS_NEW": "true",
    "IOS_UPLOAD_SCREENSHOTS": "true",
    "IOS_SUBMIT_REVIEW": "true",
    "IOS_PUBLIC_RELEASE": "true",
}
OPS = ("upload_build", "listing", "whats_new", "screenshots", "submit", "public_release")
FLAG_NAMES = {"UPLOAD_LISTING", "UPLOAD_WHATS_NEW", "UPLOAD_SCREENSHOTS", "SUBMIT_IOS_REVIEW", "PUBLIC_RELEASE"}


def gates(env: dict[str, str], *, event: str = "push", ref: str = TAG) -> dict:
    return resolve_gates(env, event=event, ref_name=ref, marketing_version=VERSION)


def quiet(fn, *args, **kwargs):
    with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
        return fn(*args, **kwargs)


class GateTests(unittest.TestCase):
    def test_missing_settings_mean_everything_off(self) -> None:
        result = gates({})
        self.assertEqual(result["mode"], "release")
        self.assertFalse(result["master"])
        self.assertFalse(result["build"])
        self.assertFalse(result["asc"])
        for key in OPS:
            self.assertFalse(result[key], key)
        self.assertEqual(result["poll_seconds"], 30)
        self.assertEqual(result["wait_minutes"], 120)

    def test_master_off_ignores_operation_switches(self) -> None:
        result = gates({**ALL_ON, "IOS_RELEASE_AUTOMATION": "false"})
        for key in OPS:
            self.assertFalse(result[key], key)
        self.assertFalse(result["build"])
        self.assertTrue(any("ignored" in note for note in result["notes"]))

    def test_each_operation_is_independent(self) -> None:
        result = gates({"IOS_RELEASE_AUTOMATION": "yes", "IOS_UPLOAD_LISTING": "on"})
        self.assertTrue(result["listing"])
        self.assertTrue(result["asc"])
        self.assertFalse(result["whats_new"])
        self.assertFalse(result["upload_build"])
        self.assertFalse(result["build"])

    def test_upload_build_alone_builds_without_touching_the_listing(self) -> None:
        result = gates({"IOS_RELEASE_AUTOMATION": "1", "IOS_UPLOAD_BUILD": "1"})
        self.assertTrue(result["build"])
        self.assertFalse(result["asc"])

    def test_all_on(self) -> None:
        result = gates(ALL_ON)
        for key in OPS:
            self.assertTrue(result[key], key)
        self.assertTrue(result["build"])

    def test_invalid_values_are_rejected_even_when_master_is_off(self) -> None:
        for name in ("IOS_RELEASE_AUTOMATION", "IOS_SUBMIT_REVIEW", "IOS_UPLOAD_WHATS_NEW", "IOS_UPLOAD_SCREENSHOTS"):
            with self.subTest(name=name), self.assertRaisesRegex(ReleaseError, name):
                gates({name: "maybe"})
        with self.assertRaisesRegex(ReleaseError, "IOS_UPLOAD_BUILD"):
            gates({"IOS_RELEASE_AUTOMATION": "false", "IOS_UPLOAD_BUILD": "enabled"})

    def test_switch_values_are_case_and_space_insensitive(self) -> None:
        result = gates({"IOS_RELEASE_AUTOMATION": " TRUE ", "IOS_UPLOAD_LISTING": "Yes"})
        self.assertTrue(result["listing"])
        self.assertFalse(gates({"IOS_RELEASE_AUTOMATION": "Off"})["master"])

    def test_bad_timing_values_are_rejected(self) -> None:
        for env in (
            {"IOS_BUILD_POLL_SECONDS": "5"},
            {"IOS_BUILD_POLL_SECONDS": "601"},
            {"IOS_BUILD_POLL_SECONDS": "thirty"},
            {"IOS_BUILD_POLL_SECONDS": "٣٠"},
            {"IOS_BUILD_WAIT_MINUTES": "0"},
            {"IOS_BUILD_WAIT_MINUTES": "999"},
            {"IOS_BUILD_WAIT_MINUTES": "-30"},
        ):
            with self.subTest(env=env), self.assertRaises(ReleaseError):
                gates(env)
        result = gates({"IOS_BUILD_POLL_SECONDS": "45", "IOS_BUILD_WAIT_MINUTES": "90"})
        self.assertEqual((result["poll_seconds"], result["wait_minutes"]), (45, 90))
        bounds = gates({"IOS_BUILD_POLL_SECONDS": "10", "IOS_BUILD_WAIT_MINUTES": "300"})
        self.assertEqual((bounds["poll_seconds"], bounds["wait_minutes"]), (10, 300))

    def test_submit_requires_this_runs_build(self) -> None:
        env = {"IOS_RELEASE_AUTOMATION": "true", "IOS_SUBMIT_REVIEW": "true"}
        with self.assertRaisesRegex(ReleaseError, "IOS_UPLOAD_BUILD"):
            gates(env)

    def test_public_release_requires_submit(self) -> None:
        env = {"IOS_RELEASE_AUTOMATION": "true", "IOS_UPLOAD_BUILD": "true", "IOS_PUBLIC_RELEASE": "true"}
        with self.assertRaisesRegex(ReleaseError, "IOS_SUBMIT_REVIEW"):
            gates(env)

    def test_tag_must_equal_marketing_version_exactly(self) -> None:
        self.assertEqual(gates({}, ref="v1.0.1")["marketing_version"], VERSION)
        for tag in ("v1.0.2", "v1.0", "v1.0.1.0", "v1.0.1-beta", "v01.0.1"):
            with self.subTest(tag=tag), self.assertRaisesRegex(ReleaseError, "does not match"):
                gates({}, ref=tag)
        for tag in ("ios-v1.0.1", "1.0.1", "release-1.0.1"):
            with self.subTest(tag=tag), self.assertRaisesRegex(ReleaseError, r"v\* tag"):
                gates({}, ref=tag)

    def test_historical_tag_style_no_longer_matches(self) -> None:
        # v1.0.0 was pushed for MARKETING_VERSION 1.0; the rule is now exact.
        with self.assertRaisesRegex(ReleaseError, "needs v1.0"):
            resolve_gates({}, event="push", ref_name="v1.0.0", marketing_version="1.0")

    def test_manual_run_validates_only(self) -> None:
        result = gates(ALL_ON, event="workflow_dispatch", ref="main")
        self.assertEqual(result["mode"], "validate")
        self.assertTrue(result["build"])
        self.assertFalse(result["master"])
        self.assertFalse(result["asc"])
        for key in OPS:
            self.assertFalse(result[key], key)

    def test_manual_run_still_rejects_invalid_switches(self) -> None:
        with self.assertRaisesRegex(ReleaseError, "IOS_UPLOAD_LISTING"):
            gates({"IOS_UPLOAD_LISTING": "sure"}, event="workflow_dispatch", ref="main")

    def test_manual_run_can_validate_a_future_version(self) -> None:
        result = resolve_gates({}, event="workflow_dispatch", ref_name="main",
                               marketing_version="1.0", validation_version="1.0.1")
        self.assertEqual(result["mode"], "validate")
        self.assertEqual(result["marketing_version"], "1.0.1")
        self.assertFalse(result["asc"])
        default = resolve_gates({}, event="workflow_dispatch", ref_name="main", marketing_version="1.0")
        self.assertEqual(default["marketing_version"], "1.0")

    def test_version_override_is_rejected_for_releases_and_bad_values(self) -> None:
        with self.assertRaisesRegex(ReleaseError, "manual validation"):
            resolve_gates({}, event="push", ref_name=TAG, marketing_version=VERSION, validation_version="1.0.2")
        for bad in ("1.x", "v1.0.1", "1.0.1.2", "1.0.1 beta", "١.٠"):
            with self.subTest(bad=bad), self.assertRaisesRegex(ReleaseError, "must look like"):
                resolve_gates({}, event="workflow_dispatch", ref_name="main",
                              marketing_version=VERSION, validation_version=bad)

    def test_other_events_are_refused(self) -> None:
        for event in ("pull_request", "schedule", ""):
            with self.subTest(event=event), self.assertRaisesRegex(ReleaseError, "unsupported event"):
                gates({}, event=event)

    def test_project_versions_are_consistent(self) -> None:
        self.assertRegex(ios_release.single_project_value("MARKETING_VERSION"), r"^\d+(\.\d+){0,2}$")
        self.assertRegex(ios_release.single_project_value("CURRENT_PROJECT_VERSION"), r"^\d+$")
        with tempfile.TemporaryDirectory() as tmp:
            pbx = Path(tmp) / "project.pbxproj"
            pbx.write_text("MARKETING_VERSION = 1.0;\nMARKETING_VERSION = 1.1;\n")
            with self.assertRaisesRegex(ReleaseError, "identical"):
                ios_release.single_project_value("MARKETING_VERSION", pbx)

    def test_cli_writes_outputs_for_the_workflow(self) -> None:
        env = {"GITHUB_EVENT_NAME": "workflow_dispatch", "GITHUB_REF_NAME": "main",
               "VALIDATION_MARKETING_VERSION": "1.0.1"}
        with tempfile.NamedTemporaryFile("r", suffix=".out") as out, mock.patch.dict(
            os.environ, {**env, "GITHUB_OUTPUT": out.name}, clear=True
        ), redirect_stdout(io.StringIO()):
            ios_release.main(["gates"])
            written = dict(line.split("=", 1) for line in Path(out.name).read_text().split())
        self.assertEqual(written["mode"], "validate")
        self.assertEqual(written["build"], "true")
        self.assertEqual(written["marketing_version"], "1.0.1")
        self.assertEqual(written["upload_build"], "false")

    def test_cli_exits_non_zero_on_a_bad_switch(self) -> None:
        env = {"GITHUB_EVENT_NAME": "push", "GITHUB_REF_NAME": TAG, "IOS_SUBMIT_REVIEW": "maybe"}
        with mock.patch.dict(os.environ, env, clear=True), self.assertRaises(SystemExit) as raised:
            quiet(ios_release.main, ["gates"])
        self.assertEqual(raised.exception.code, 1)


class BuildNumberTests(unittest.TestCase):
    def test_next_build_number(self) -> None:
        self.assertEqual(ios_release.next_build_number(39, ["13", "35", "12"]), 39)
        self.assertEqual(ios_release.next_build_number(39, ["13", "39"]), 40)
        self.assertEqual(ios_release.next_build_number(1, []), 1)
        self.assertEqual(ios_release.next_build_number(5, ["7.1", "abc", "9"]), 10)
        self.assertEqual(ios_release.next_build_number(5, ["٩٩"]), 5)  # only ASCII digits count

    def test_pcm_notes_continues_after_the_xcode_cloud_builds(self) -> None:
        # Xcode Cloud uploaded 1.0 builds 1, 2, 3, 4 and 7; the project still says 1.
        self.assertEqual(ios_release.next_build_number(1, ["1", "2", "3", "4", "7"]), 8)


APP = asc_release.APP_STORE_APP_ID
STARTED = 1_800_000_000.0  # this run's upload start (epoch seconds)


def iso(epoch: float) -> str:
    import datetime as dt

    return dt.datetime.fromtimestamp(epoch, dt.timezone.utc).isoformat()


def build_row(
    build_id: str = "B1",
    *,
    number: str = "8",
    state: str = "VALID",
    expired: bool = False,
    uploaded: float = STARTED + 60,
    app: str = APP,
    pre: str = "P1",
) -> dict:
    return {
        "type": "builds",
        "id": build_id,
        "attributes": {
            "version": number,
            "processingState": state,
            "expired": expired,
            "uploadedDate": iso(uploaded),
        },
        "relationships": {
            "preReleaseVersion": {"data": {"type": "preReleaseVersions", "id": pre}},
            "app": {"data": {"type": "apps", "id": app}},
        },
    }


def pre_row(pre_id: str = "P1", version: str = VERSION, platform: str = "IOS") -> dict:
    return {"type": "preReleaseVersions", "id": pre_id, "attributes": {"version": version, "platform": platform}}


class FakeClock:
    def __init__(self, start: float) -> None:
        self.time = start
        self.sleeps: list[float] = []

    def now(self) -> float:
        return self.time

    def sleep(self, seconds: float) -> None:
        self.sleeps.append(seconds)
        self.time += seconds


class SequenceClient:
    """Returns queued /builds payloads (or raises queued exceptions) per GET."""

    def __init__(self, responses: list) -> None:
        self.responses = list(responses)
        self.paths: list[str] = []

    def get(self, path: str) -> dict:
        self.paths.append(path)
        item = self.responses.pop(0) if len(self.responses) > 1 else self.responses[0]
        if isinstance(item, BaseException):
            raise item
        return item


def wait(client: SequenceClient, clock: FakeClock, *, minutes: int = 120, transient=None) -> dict:
    with redirect_stdout(io.StringIO()):
        return ios_release.wait_for_build(
            client,
            app_id=APP,
            marketing_version=VERSION,
            build_number="8",
            uploaded_after=STARTED,
            deadline=STARTED + minutes * 60,
            poll_seconds=30,
            now=clock.now,
            sleep=clock.sleep,
            is_transient=transient,
        )


class WaitForBuildTests(unittest.TestCase):
    def test_waits_through_missing_and_processing_then_returns_build(self) -> None:
        client = SequenceClient(
            [
                {"data": []},
                {"data": [build_row(state="PROCESSING")], "included": [pre_row()]},
                {"data": [build_row()], "included": [pre_row()]},
            ]
        )
        clock = FakeClock(STARTED + 120)
        build = wait(client, clock)
        self.assertEqual(build["id"], "B1")
        self.assertEqual(clock.sleeps, [30, 30])
        self.assertIn("filter%5Bversion%5D=8", client.paths[0])
        self.assertIn(f"filter%5Bapp%5D={APP}", client.paths[0])

    def test_times_out_without_using_another_build(self) -> None:
        client = SequenceClient([{"data": [build_row(state="PROCESSING")], "included": [pre_row()]}])
        clock = FakeClock(STARTED)
        with self.assertRaisesRegex(ReleaseError, "timed out"):
            wait(client, clock, minutes=10)
        self.assertLessEqual(clock.time, STARTED + 10 * 60 + 30)

    def test_ready_build_after_the_deadline_is_still_a_timeout(self) -> None:
        client = SequenceClient([{"data": [build_row()], "included": [pre_row()]}])
        clock = FakeClock(STARTED + 121 * 60)  # job started after the 120-minute budget
        with self.assertRaisesRegex(ReleaseError, "timed out"):
            wait(client, clock)
        self.assertEqual(client.paths, [], "must not poll once the budget is spent")

    def test_processing_failure_stops(self) -> None:
        for state in ("FAILED", "INVALID"):
            client = SequenceClient([{"data": [build_row(state=state)], "included": [pre_row()]}])
            with self.subTest(state=state), self.assertRaisesRegex(ReleaseError, state):
                wait(client, FakeClock(STARTED))

    def test_expired_build_is_rejected(self) -> None:
        client = SequenceClient([{"data": [build_row(expired=True)], "included": [pre_row()]}])
        with self.assertRaisesRegex(ReleaseError, "expired"):
            wait(client, FakeClock(STARTED))

    def test_ambiguous_match_stops(self) -> None:
        client = SequenceClient(
            [{"data": [build_row("B1"), build_row("B2")], "included": [pre_row()]}]
        )
        with self.assertRaisesRegex(ReleaseError, "ambiguous"):
            wait(client, FakeClock(STARTED))

    def test_older_upload_is_never_substituted(self) -> None:
        old = build_row(uploaded=STARTED - 3600)
        client = SequenceClient([{"data": [old], "included": [pre_row()]}])
        with self.assertRaisesRegex(ReleaseError, "older build"):
            wait(client, FakeClock(STARTED))

    def test_other_versions_and_platforms_are_ignored(self) -> None:
        other_version = build_row("BX", pre="P2")
        other_platform = build_row("BY", pre="P3")
        client = SequenceClient(
            [
                {
                    "data": [other_version, other_platform],
                    "included": [pre_row("P2", "1.0"), pre_row("P3", VERSION, "MAC_OS")],
                },
                {"data": [other_version, build_row("B1")], "included": [pre_row("P2", "1.0"), pre_row()]},
            ]
        )
        self.assertEqual(wait(client, FakeClock(STARTED))["id"], "B1")

    def test_build_from_another_app_is_a_mismatch(self) -> None:
        client = SequenceClient([{"data": [build_row(app="OTHER")], "included": [pre_row()]}])
        with self.assertRaisesRegex(ReleaseError, "another app"):
            wait(client, FakeClock(STARTED))

    def test_transient_errors_are_retried_and_others_raise(self) -> None:
        transient = asc_release.AscHttpError(503, "unavailable")
        client = SequenceClient([transient, {"data": [build_row()], "included": [pre_row()]}])
        with redirect_stderr(io.StringIO()):
            build = wait(client, FakeClock(STARTED), transient=lambda exc: getattr(exc, "status", 0) == 503)
        self.assertEqual(build["id"], "B1")
        fatal = SequenceClient([asc_release.AscHttpError(401, "unauthorized")])
        with self.assertRaises(SystemExit):
            wait(fatal, FakeClock(STARTED), transient=lambda exc: getattr(exc, "status", 0) == 503)


class SelectionClient:
    """Fake ASC client for build verification and selection."""

    def __init__(self, *, build: dict, included: list, attached: str | None, sticky: bool = True) -> None:
        self.build = build
        self.included = included
        self.attached = attached
        self.sticky = sticky
        self.calls: list[tuple[str, str, dict | None]] = []

    def get(self, path: str) -> dict:
        self.calls.append(("GET", path, None))
        if path.startswith(f"/builds/{self.build['id']}"):
            return {"data": self.build, "included": self.included}
        if path.endswith("/build"):
            return {"data": {"type": "builds", "id": self.attached} if self.attached else None}
        raise AssertionError(f"unexpected GET {path}")

    def patch(self, path: str, body: dict) -> dict:
        self.calls.append(("PATCH", path, body))
        return {"data": body["data"]}

    def request(self, method: str, path: str, body: dict | None = None):
        self.calls.append((method, path, body))
        if method == "PATCH" and path.endswith("/relationships/build") and self.sticky:
            self.attached = body["data"]["id"]
        return None


class BuildSelectionTests(unittest.TestCase):
    def test_selects_and_reads_back_this_runs_build(self) -> None:
        client = SelectionClient(build=build_row("B9"), included=[pre_row()], attached="OLD")
        quiet(asc_release.select_build, client, "V1", "B9", VERSION, "8")
        self.assertEqual(client.attached, "B9")
        methods = [(m, p) for m, p, _ in client.calls]
        self.assertIn(("PATCH", "/appStoreVersions/V1/relationships/build"), methods)
        self.assertEqual(methods[-1], ("GET", "/appStoreVersions/V1/build"))

    def test_selection_that_does_not_stick_fails(self) -> None:
        client = SelectionClient(build=build_row("B9"), included=[pre_row()], attached="OLD", sticky=False)
        with self.assertRaises(SystemExit):
            quiet(asc_release.select_build, client, "V1", "B9", VERSION, "8")

    def test_unprocessed_expired_or_wrong_build_is_refused(self) -> None:
        cases = {
            "processing": (build_row("B9", state="PROCESSING"), [pre_row()]),
            "expired": (build_row("B9", expired=True), [pre_row()]),
            "number": (build_row("B9", number="9"), [pre_row()]),
            "version": (build_row("B9"), [pre_row(version="1.0")]),
            "platform": (build_row("B9"), [pre_row(platform="TV_OS")]),
        }
        for label, (build, included) in cases.items():
            client = SelectionClient(build=build, included=included, attached=None)
            with self.subTest(label), self.assertRaises(SystemExit):
                quiet(asc_release.select_build, client, "V1", "B9", VERSION, "8")
            self.assertFalse([c for c in client.calls if c[0] == "PATCH"], label)

    def test_release_type(self) -> None:
        for public, expected in ((True, "AFTER_APPROVAL"), (False, "MANUAL")):
            client = SelectionClient(build=build_row(), included=[], attached=None)
            quiet(asc_release.set_release_type, client, "V1", public_release=public)
            body = client.calls[-1][2]
            self.assertEqual(body["data"]["attributes"]["releaseType"], expected)


class TokenRefreshTests(unittest.TestCase):
    def test_token_is_reminted_during_long_waits(self) -> None:
        minted: list[str] = []

        def factory() -> str:
            minted.append(f"t{len(minted)}")
            return minted[-1]

        with mock.patch.object(asc_release.time, "monotonic", side_effect=[0, 100, 700, 700, 800]):
            client = asc_release.AscClient(token_factory=factory)
            self.assertEqual(client._authorization(), "Bearer t0")
            self.assertEqual(client._authorization(), "Bearer t1")
            self.assertEqual(client._authorization(), "Bearer t1")

    def test_minted_token_is_an_es256_app_store_connect_jwt(self) -> None:
        try:
            import jwt
            from cryptography.hazmat.primitives import serialization
            from cryptography.hazmat.primitives.asymmetric import ec
        except ImportError:  # pragma: no cover - CI installs requirements-store.txt
            self.skipTest("PyJWT[crypto] is not installed (pip install --require-hashes -r requirements-store.txt)")
        key = ec.generate_private_key(ec.SECP256R1())
        pem = key.private_bytes(
            serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8, serialization.NoEncryption()
        ).decode()
        token = asc_release.make_asc_token("KEY123", "issuer-uuid", pem)
        header = jwt.get_unverified_header(token)
        self.assertEqual((header["alg"], header["kid"], header["typ"]), ("ES256", "KEY123", "JWT"))
        claims = jwt.decode(token, key.public_key(), algorithms=["ES256"], audience="appstoreconnect-v1")
        self.assertEqual(claims["iss"], "issuer-uuid")
        self.assertLessEqual(claims["exp"] - claims["iat"], 1200)  # Apple's 20-minute maximum

    def test_escaped_newlines_in_the_secret_are_restored(self) -> None:
        env = {
            "APP_STORE_CONNECT_API_KEY_ID": "KEY123",
            "APP_STORE_CONNECT_ISSUER_ID": "issuer",
            "APP_STORE_CONNECT_API_KEY_P8": "-----BEGIN PRIVATE KEY-----\\nabc\\n-----END PRIVATE KEY-----",
        }
        with mock.patch.dict(os.environ, env, clear=True):
            _, _, key = asc_release.load_credentials()
        self.assertEqual(key.count("\n"), 2)

    def test_missing_credentials_fail(self) -> None:
        with mock.patch.dict(os.environ, {}, clear=True), self.assertRaises(SystemExit):
            quiet(asc_release.load_credentials)


class FindAppTests(unittest.TestCase):
    def client(self, rows: list[dict]) -> mock.Mock:
        client = mock.Mock()
        client.get.return_value = {"data": rows}
        return client

    def test_returns_the_pinned_pcm_notes_app(self) -> None:
        rows = [
            {"id": "999", "attributes": {"bundleId": "com.apoorvdarshan.iitjee.extra"}},
            {"id": APP, "attributes": {"bundleId": "com.apoorvdarshan.iitjee"}},
        ]
        self.assertEqual(asc_release.find_app(self.client(rows), "com.apoorvdarshan.iitjee"), APP)

    def test_wrong_ambiguous_or_missing_app_stops(self) -> None:
        cases = {
            "other id": [{"id": "123", "attributes": {"bundleId": "com.apoorvdarshan.iitjee"}}],
            "ambiguous": [
                {"id": APP, "attributes": {"bundleId": "com.apoorvdarshan.iitjee"}},
                {"id": "124", "attributes": {"bundleId": "com.apoorvdarshan.iitjee"}},
            ],
            "missing": [],
            "prefix only": [{"id": APP, "attributes": {"bundleId": "com.apoorvdarshan.iitjeex"}}],
        }
        for label, rows in cases.items():
            with self.subTest(label), self.assertRaises(SystemExit):
                quiet(asc_release.find_app, self.client(rows), "com.apoorvdarshan.iitjee")


class PreflightTests(unittest.TestCase):
    def problems(self, state: str | None, *, edits: bool = True, submit: bool = False) -> list[str]:
        version = None if state is None else {"id": "V1", "attributes": {"appStoreState": state}}
        return ios_release.preflight_problems(
            version,
            version_string=VERSION,
            edits_metadata=edits,
            submit=submit,
            editable_states=asc_release.EDITABLE_VERSION_STATES,
            submittable_states=asc_release.SUBMITTABLE_VERSION_STATES,
        )

    def test_missing_version_fails_before_anything_is_built(self) -> None:
        self.assertRegex(" ".join(self.problems(None)), "create it in App Store Connect")

    def test_live_or_in_review_version_cannot_take_listing_edits(self) -> None:
        for state in ("READY_FOR_SALE", "WAITING_FOR_REVIEW", "IN_REVIEW", "PENDING_DEVELOPER_RELEASE"):
            with self.subTest(state=state):
                self.assertTrue(self.problems(state))

    def test_prepared_version_passes(self) -> None:
        self.assertEqual(self.problems("PREPARE_FOR_SUBMISSION", submit=True), [])
        self.assertEqual(self.problems("DEVELOPER_REJECTED", submit=True), [])

    def test_submit_only_accepts_a_rerun_while_waiting_for_review(self) -> None:
        self.assertEqual(self.problems("WAITING_FOR_REVIEW", edits=False, submit=True), [])
        self.assertTrue(self.problems("IN_REVIEW", edits=False, submit=True))

    def test_cli_is_read_only_and_reports_problems(self) -> None:
        client = mock.Mock()
        client.get.side_effect = lambda path: (
            {"data": [{"id": APP, "attributes": {"bundleId": ios_release.BUNDLE_ID}}]}
            if path.startswith("/apps?")
            else {"data": [{"id": "V1", "attributes": {"versionString": "1.0", "appStoreState": "READY_FOR_SALE"}}]}
        )
        with mock.patch.object(ios_release, "asc_client", return_value=(asc_release, client)), \
                self.assertRaises(SystemExit):
            quiet(ios_release.main, ["preflight", "--version", VERSION, "--edits-metadata"])
        client.patch.assert_not_called()
        client.post.assert_not_called()
        client.request.assert_not_called()


def write_listing(root: Path, locale: str = "en-US", **overrides: str) -> Path:
    loc = root / "ios" / locale
    loc.mkdir(parents=True, exist_ok=True)
    files = {
        "name.txt": "PCM Notes: JEE & NEET",
        "subtitle.txt": "Handwritten Exam Revision",
        "privacy_url.txt": "https://iitjee.apoorvdarshan.com/privacy",
        "description.txt": "Handwritten notes.",
        "keywords.txt": "jee,neet",
        "promotional_text.txt": "Promo",
        "marketing_url.txt": "https://iitjee.apoorvdarshan.com/",
        "support_url.txt": "https://iitjee.apoorvdarshan.com/#support",
    }
    files.update(overrides)
    for name, text in files.items():
        (loc / name).write_text(text + "\n")
    return loc


class AscCliTests(unittest.TestCase):
    def run_cli(self, env: dict[str, str], *args: str) -> tuple[int, str]:
        out = io.StringIO()
        full_env = {k: v for k, v in os.environ.items() if k not in FLAG_NAMES}
        full_env.update(env)
        with mock.patch.dict(os.environ, full_env, clear=True), mock.patch.object(
            sys, "argv", ["asc_release.py", "--dry-run", *args]
        ), redirect_stdout(out), redirect_stderr(out):
            try:
                asc_release.main()
            except SystemExit as exc:
                return (exc.code if isinstance(exc.code, int) else 1), out.getvalue()
        return 0, out.getvalue()

    def test_everything_off_is_a_no_op(self) -> None:
        code, output = self.run_cli({})
        self.assertEqual(code, 0)
        self.assertIn("skipped", output)

    def test_submit_without_this_runs_build_fails(self) -> None:
        code, output = self.run_cli({"SUBMIT_IOS_REVIEW": "true"})
        self.assertEqual(code, 1)
        self.assertIn("--build-id", output)

    def test_public_release_without_submit_fails(self) -> None:
        code, _ = self.run_cli({"UPLOAD_LISTING": "true", "PUBLIC_RELEASE": "true"})
        self.assertEqual(code, 1)

    def test_the_repository_listing_and_screenshots_are_upload_ready(self) -> None:
        env = {"UPLOAD_LISTING": "true", "UPLOAD_SCREENSHOTS": "true", "SUBMIT_IOS_REVIEW": "true"}
        code, output = self.run_cli(env, "--build-id", "B9", "--build-number", "8")
        self.assertEqual(code, 0, output)
        self.assertIn("locales=en-US", output)

    def test_whats_new_requires_text_for_every_locale(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            write_listing(Path(tmp))
            fr = write_listing(Path(tmp), "fr-FR")
            code, output = self.run_cli({"UPLOAD_WHATS_NEW": "true"}, "--metadata-dir", tmp)
            self.assertEqual(code, 1)
            self.assertIn("whats_new.txt", output)
            (Path(tmp) / "ios" / "en-US" / "whats_new.txt").write_text("Fixes\n")
            code, output = self.run_cli({"UPLOAD_WHATS_NEW": "true"}, "--metadata-dir", tmp)
            self.assertEqual(code, 1)
            self.assertIn("fr-FR", output)
            (fr / "whats_new.txt").write_text("Corrections\n")
            code, output = self.run_cli({"UPLOAD_WHATS_NEW": "true"}, "--metadata-dir", tmp)
            self.assertEqual(code, 0, output)

    def test_listing_limits_and_required_fields_are_enforced(self) -> None:
        cases = {
            "name": {"name.txt": "N" * 31},
            "subtitle": {"subtitle.txt": "S" * 31},
            "keywords": {"keywords.txt": "k" * 101},
            "promotional text": {"promotional_text.txt": "p" * 171},
            "description": {"description.txt": "d" * 4001},
            "http url": {"support_url.txt": "http://iitjee.apoorvdarshan.com"},
            "missing description": {"description.txt": ""},
        }
        for label, override in cases.items():
            with self.subTest(label), tempfile.TemporaryDirectory() as tmp:
                write_listing(Path(tmp), **override)
                code, _ = self.run_cli({"UPLOAD_LISTING": "true"}, "--metadata-dir", tmp)
                self.assertEqual(code, 1, label)

    def test_primary_locale_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            write_listing(Path(tmp), "fr-FR")
            code, output = self.run_cli({"UPLOAD_LISTING": "true"}, "--metadata-dir", tmp)
        self.assertEqual(code, 1)
        self.assertIn("en-US", output)

    def test_listing_excludes_whats_new_unless_enabled(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            loc = Path(tmp) / "ios" / "en-US"
            loc.mkdir(parents=True)
            (loc / "description.txt").write_text("Desc")
            (loc / "whats_new.txt").write_text("New")
            for whats_new, expected in ((False, {"description"}), (True, {"description", "whatsNew"})):
                client = mock.Mock()
                client.get.return_value = {"data": [{"id": "LOC", "attributes": {"locale": "en-US"}}]}
                with mock.patch.object(asc_release, "upload_app_info"), \
                        mock.patch.object(asc_release, "check_whats_new_is_new"):
                    quiet(
                        asc_release.upload_listing,
                        client,
                        app_id=APP,
                        version_id="V1",
                        locale="en-US",
                        metadata_dir=Path(tmp),
                        include_listing=True,
                        include_whats_new=whats_new,
                    )
                attrs = client.patch.call_args[0][1]["data"]["attributes"]
                self.assertEqual(set(attrs), expected)

    def test_exported_listing_matches_the_app(self) -> None:
        loc = ROOT / "store" / "metadata" / "ios" / "en-US"
        self.assertEqual((loc / "name.txt").read_text().strip(), "PCM Notes: JEE & NEET")
        self.assertIn("91 chapters", (loc / "promotional_text.txt").read_text())
        self.assertEqual(asc_release.listing_locales(ROOT / "store" / "metadata"), ["en-US"])


class AppInfoClient:
    """Fake ASC client for app information (name, subtitle, privacy URL)."""

    def __init__(self, *, editable: bool, current: dict[str, str]) -> None:
        self.infos = [{"id": "INFO-LIVE", "attributes": {"state": "READY_FOR_DISTRIBUTION"}}]
        if editable:
            self.infos.append({"id": "INFO-NEXT", "attributes": {"state": "PREPARE_FOR_SUBMISSION"}})
        self.current = current
        self.patches: list[tuple[str, dict]] = []

    def get(self, path: str) -> dict:
        if path == f"/apps/{APP}/appInfos":
            return {"data": self.infos}
        if path.startswith("/appInfos/"):
            info_id = path.split("/")[2]
            return {"data": [{"id": f"LOC-{info_id}", "attributes": {"locale": "en-US", **self.current}}]}
        raise AssertionError(f"unexpected GET {path}")

    def patch(self, path: str, body: dict) -> dict:
        self.patches.append((path, body))
        return body


LIVE_INFO = {
    "name": "PCM Notes: JEE & NEET",
    "subtitle": "Handwritten Exam Revision",
    "privacyPolicyUrl": "https://iitjee.apoorvdarshan.com/privacy",
}


class AppInfoTests(unittest.TestCase):
    def upload(self, client: AppInfoClient, **overrides: str) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            write_listing(Path(tmp), **overrides)
            quiet(asc_release.upload_app_info, client, app_id=APP, locale="en-US", metadata_dir=Path(tmp))

    def test_unchanged_app_information_is_not_patched(self) -> None:
        client = AppInfoClient(editable=True, current=LIVE_INFO)
        self.upload(client)
        self.assertEqual(client.patches, [])

    def test_only_changed_fields_go_to_the_editable_copy(self) -> None:
        client = AppInfoClient(editable=True, current=LIVE_INFO)
        self.upload(client, **{"subtitle.txt": "Offline JEE & NEET Notes"})
        self.assertEqual(len(client.patches), 1)
        path, body = client.patches[0]
        self.assertEqual(path, "/appInfoLocalizations/LOC-INFO-NEXT")
        self.assertEqual(body["data"]["attributes"], {"subtitle": "Offline JEE & NEET Notes"})

    def test_changes_without_an_editable_copy_stop(self) -> None:
        client = AppInfoClient(editable=False, current=LIVE_INFO)
        with self.assertRaises(SystemExit):
            self.upload(client, **{"name.txt": "PCM Notes"})
        self.assertEqual(client.patches, [])
        self.upload(AppInfoClient(editable=False, current=LIVE_INFO))  # unchanged is fine


class WhatsNewClient:
    def __init__(self, live_whats_new: str | None) -> None:
        self.live_whats_new = live_whats_new

    def get(self, path: str) -> dict:
        if path.startswith(f"/apps/{APP}/appStoreVersions"):
            return {"data": [
                {"id": "V-LIVE", "attributes": {"versionString": "1.0", "appStoreState": "READY_FOR_SALE"}},
                {"id": "V-NEXT", "attributes": {"versionString": VERSION, "appStoreState": "PREPARE_FOR_SUBMISSION"}},
            ]}
        if path.startswith("/appStoreVersions/V-LIVE/appStoreVersionLocalizations"):
            return {"data": [{"id": "L", "attributes": {"locale": "en-US", "whatsNew": self.live_whats_new}}]}
        raise AssertionError(f"unexpected GET {path}")


class WhatsNewGuardTests(unittest.TestCase):
    def check(self, live: str | None, text: str) -> None:
        quiet(asc_release.check_whats_new_is_new, WhatsNewClient(live),
              app_id=APP, version_id="V-NEXT", locale="en-US", text=text)

    def test_the_live_versions_text_is_refused(self) -> None:
        with self.assertRaises(SystemExit):
            self.check("Bug fixes.\n", "Bug fixes.")

    def test_new_text_or_a_first_release_passes(self) -> None:
        self.check("Bug fixes.", "Faster chapter search.")
        self.check(None, "Bug fixes.")


def png_bytes(width: int, height: int) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IEND", b"")


class ScreenshotClient:
    """Fake ASC client for one screenshot set."""

    def __init__(self, existing: list[bytes], *, final_state: str = "COMPLETE") -> None:
        self.shots = [
            {"id": f"OLD{i}", "attributes": {"sourceFileChecksum": hashlib.md5(raw).hexdigest(),  # noqa: S324
                                             "assetDeliveryState": {"state": "COMPLETE"}}}
            for i, raw in enumerate(existing)
        ]
        self.final_state = final_state
        self.calls: list[tuple[str, str]] = []
        self.uploaded: list[str] = []

    def get(self, path: str) -> dict:
        self.calls.append(("GET", path))
        if path.endswith("/appScreenshotSets"):
            return {"data": [{"id": "SET", "attributes": {"screenshotDisplayType": "APP_IPHONE_67"}}]}
        if path == "/appScreenshotSets/SET/appScreenshots":
            return {"data": self.shots}
        raise AssertionError(f"unexpected GET {path}")

    def post(self, path: str, body: dict) -> dict:
        self.calls.append(("POST", path))
        name = body["data"]["attributes"]["fileName"]
        shot = {"id": f"NEW-{name}", "attributes": {
            "uploadOperations": [{"url": "https://upload.example/x", "length": body["data"]["attributes"]["fileSize"],
                                  "offset": 0, "method": "PUT", "requestHeaders": []}],
            "assetDeliveryState": {"state": "AWAITING_UPLOAD"}}}
        self.shots.append(shot)
        return {"data": shot}

    def upload_bytes(self, url: str, data: bytes, headers: dict, *, method: str = "PUT") -> None:
        self.calls.append(("UPLOAD", url))

    def patch(self, path: str, body: dict) -> dict:
        self.calls.append(("PATCH", path))
        for shot in self.shots:
            if path == f"/appScreenshots/{shot['id']}":
                shot["attributes"]["sourceFileChecksum"] = body["data"]["attributes"]["sourceFileChecksum"]
                shot["attributes"]["assetDeliveryState"] = {"state": self.final_state}
                self.uploaded.append(shot["id"])
        return body

    def request(self, method: str, path: str, body: dict | None = None):
        self.calls.append((method, path))
        if method == "DELETE":
            self.shots = [s for s in self.shots if path != f"/appScreenshots/{s['id']}"]
        return None


class ScreenshotTests(unittest.TestCase):
    SPEC = asc_release.ScreenshotSet("APP_IPHONE_67", "shots", frozenset({(1290, 2796)}))

    def make_dir(self, tmp: str, images: list[bytes]) -> Path:
        root = Path(tmp)
        (root / "shots").mkdir()
        for i, raw in enumerate(images):
            (root / "shots" / f"0{i + 1}.png").write_bytes(raw)
        return root

    def test_matching_screenshots_are_left_alone(self) -> None:
        images = [png_bytes(1290, 2796) + bytes([i]) for i in range(3)]
        with tempfile.TemporaryDirectory() as tmp:
            root = self.make_dir(tmp, images)
            client = ScreenshotClient(images)
            changed = quiet(asc_release.upload_screenshot_set, client, "LOC", self.SPEC, root)
        self.assertFalse(changed)
        self.assertFalse([c for c in client.calls if c[0] != "GET"])

    def test_changed_screenshots_are_replaced_in_order_and_processed(self) -> None:
        old = [png_bytes(1290, 2796) + b"old"]
        new = [png_bytes(1290, 2796) + bytes([i]) for i in range(2)]
        with tempfile.TemporaryDirectory() as tmp:
            root = self.make_dir(tmp, new)
            client = ScreenshotClient(old)
            changed = quiet(asc_release.upload_screenshot_set, client, "LOC", self.SPEC, root)
        self.assertTrue(changed)
        self.assertEqual(client.uploaded, ["NEW-01.png", "NEW-02.png"])
        self.assertIn(("DELETE", "/appScreenshots/OLD0"), client.calls)
        self.assertEqual([s["attributes"]["sourceFileChecksum"] for s in client.shots],
                         [hashlib.md5(raw).hexdigest() for raw in new])  # noqa: S324

    def test_processing_failure_stops(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = self.make_dir(tmp, [png_bytes(1290, 2796)])
            client = ScreenshotClient([], final_state="FAILED")
            with self.assertRaises(SystemExit):
                quiet(asc_release.upload_screenshot_set, client, "LOC", self.SPEC, root)

    def test_processing_timeout_stops(self) -> None:
        client = mock.Mock()
        client.get.return_value = {"data": [{"id": "S", "attributes": {"assetDeliveryState": {"state": "UPLOAD_COMPLETE"}}}]}
        clock = FakeClock(0)
        with self.assertRaises(SystemExit):
            quiet(asc_release.wait_for_screenshot_processing, client, "SET",
                  timeout_seconds=60, poll_seconds=10, now=clock.now, sleep=clock.sleep)
        self.assertLessEqual(clock.time, 70)

    def test_png_size_and_validation(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "a.png"
            path.write_bytes(png_bytes(2048, 2732))
            self.assertEqual(asc_release.png_size(path), (2048, 2732))
            path.write_bytes(b"not a png at all, just text....")
            with self.assertRaises(SystemExit):
                quiet(asc_release.png_size, path)

    def test_repository_screenshots_have_app_store_sizes(self) -> None:
        quiet(asc_release.validate_screenshots)
        counts = {spec.display_type: len(asc_release.screenshot_files(spec)) for spec in asc_release.SCREENSHOT_SETS}
        self.assertEqual(counts, {"APP_IPHONE_67": 5, "APP_IPAD_PRO_3GEN_129": 5})

    def test_wrong_sized_or_missing_screenshots_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for spec in asc_release.SCREENSHOT_SETS:
                (root / spec.directory).mkdir(parents=True)
                width, height = sorted(spec.sizes)[0]
                (root / spec.directory / "01.png").write_bytes(png_bytes(width, height))
            quiet(asc_release.validate_screenshots, root)
            (root / "marketing/mockups/iphone/02.png").write_bytes(png_bytes(1179, 2556))
            with self.assertRaises(SystemExit):
                quiet(asc_release.validate_screenshots, root)
            for path in (root / "marketing/mockups/iphone").glob("*.png"):
                path.unlink()
            with self.assertRaises(SystemExit):
                quiet(asc_release.validate_screenshots, root)


class RecordingClient:
    """Offline AscClient stand-in that serves fixed collections."""

    def __init__(self, collections: dict[str, list[dict]], *, failing_posts: set[str] = frozenset()) -> None:
        self.collections = collections
        self.failing_posts = failing_posts
        self.posts: list[tuple[str, dict]] = []
        self.requests: list[tuple[str, str, dict | None]] = []

    def get(self, path: str) -> dict:
        return {"data": self.collections.get(path, [])}

    def post(self, path: str, body: dict) -> dict:
        if path in self.failing_posts:
            raise asc_release.AscHttpError(409, "conflict")
        self.posts.append((path, body))
        return {"data": {"id": "NEW"}}

    def request(self, method: str, path: str, body: dict | None = None):
        self.requests.append((method, path, body))
        return {"data": {"id": "fake"}}


TIP = "com.apoorvdarshan.iitjee.tip."
ITEMS_PATH = "/reviewSubmissions/SUB1/items?limit=50&include=subscriptionVersion,appStoreVersion"


def product_collections(**states: str) -> dict[str, list[dict]]:
    return {
        f"/apps/{APP}/reviewSubmissions?filter%5Bstate%5D=READY_FOR_REVIEW&limit=5": [{"id": "SUB1"}],
        f"/apps/{APP}/inAppPurchasesV2?limit=200": [
            {"id": f"IAP-{tier}", "attributes": {"name": tier, "productId": TIP + tier, "state": state}}
            for tier, state in states.items()
        ],
    }


class ProductSubmissionTests(unittest.TestCase):
    def submit(self, client: RecordingClient, intended: set[str] | None = None):
        ids = intended if intended is not None else {TIP + t for t in ("small", "medium", "large", "generous")}
        return quiet(asc_release.submit_in_app_purchases, client, APP, intended_ids=ids)

    def test_only_ready_catalog_tips_are_submitted(self) -> None:
        collections = product_collections(small="APPROVED", medium="READY_TO_SUBMIT", large="APPROVED",
                                          generous="APPROVED", extra="READY_TO_SUBMIT")
        client = RecordingClient(collections)
        result = self.submit(client)
        submissions = [body for path, body in client.posts if path == "/inAppPurchaseSubmissions"]
        self.assertEqual([b["data"]["relationships"]["inAppPurchaseV2"]["data"]["id"] for b in submissions],
                         ["IAP-medium"])
        self.assertEqual(result.submitted, 1)

    def test_approved_tips_mean_nothing_to_submit(self) -> None:
        client = RecordingClient(product_collections(small="APPROVED", medium="APPROVED"))
        self.assertEqual(self.submit(client).submitted, 0)
        self.assertEqual(client.posts, [])

    def test_a_tip_that_cannot_be_submitted_blocks_the_release(self) -> None:
        client = RecordingClient(product_collections(small="READY_TO_SUBMIT"),
                                 failing_posts={"/inAppPurchaseSubmissions"})
        with self.assertRaises(asc_release.ProductSubmitError):
            self.submit(client)

    def test_subscriptions_attach_their_current_version_once(self) -> None:
        collections = product_collections()
        collections[f"/apps/{APP}/subscriptionGroups?limit=200"] = [{"id": "G1"}]
        collections["/subscriptionGroups/G1/subscriptions?limit=200"] = [
            {"id": "S0", "attributes": {"name": "Plus", "productId": "plus", "state": "DEVELOPER_REJECTED"}},
            {"id": "S1", "attributes": {"name": "Pro", "productId": "pro", "state": "READY_TO_SUBMIT"}},
        ]
        for sub in ("S0", "S1"):
            collections[f"/subscriptions/{sub}/versions"] = [
                {"id": f"{sub}-v2", "attributes": {"version": 2}},
                {"id": f"{sub}-v1", "attributes": {"version": 1}},
            ]
        collections[ITEMS_PATH] = [{"id": "I", "relationships": {
            "subscriptionVersion": {"data": {"type": "subscriptionVersions", "id": "S0-v2"}}}}]
        client = RecordingClient(collections)
        result = self.submit(client, {"plus", "pro"})
        items = [b["data"]["relationships"]["subscriptionVersion"]["data"]["id"]
                 for path, b in client.posts if path == "/reviewSubmissionItems"]
        self.assertEqual(items, ["S1-v2"])  # S0's current version was already attached
        self.assertEqual(result.submitted, 2)
        self.assertTrue(result.has_products)

    def test_empty_catalog_submits_nothing(self) -> None:
        client = RecordingClient(product_collections(small="READY_TO_SUBMIT"))
        self.assertEqual(self.submit(client, set()).submitted, 0)
        self.assertEqual(client.posts, [])

    def test_catalog_lists_the_four_tips(self) -> None:
        self.assertEqual(asc_release.intended_product_ids(),
                         {TIP + t for t in ("small", "medium", "large", "generous")})

    def test_submit_for_review_does_not_readd_a_held_version(self) -> None:
        client = RecordingClient({ITEMS_PATH: [{"id": "I", "relationships": {
            "appStoreVersion": {"data": {"type": "appStoreVersions", "id": "AV1"}}}}]})
        quiet(asc_release.submit_for_review, client, APP, "AV1", "PREPARE_FOR_SUBMISSION", submission_id="SUB1")
        self.assertEqual(client.posts, [])
        self.assertIn(("PATCH", "/reviewSubmissions/SUB1"), [(m, p) for m, p, _ in client.requests])
        self.assertTrue(asc_release.draft_holds_app_version(client, "SUB1"))


class TransientErrorTests(unittest.TestCase):
    def test_real_retry_rule(self) -> None:
        import http.client
        import urllib.error

        transient = [
            http.client.RemoteDisconnected("closed"),
            ConnectionResetError("reset"),
            http.client.IncompleteRead(b""),
            urllib.error.URLError("dns"),
            TimeoutError("slow"),
            asc_release.AscHttpError(503, "busy"),
            asc_release.AscHttpError(429, "rate limited"),
            urllib.error.HTTPError("https://x", 502, "bad gateway", {}, None),
        ]
        fatal = [
            asc_release.AscHttpError(401, "unauthorized"),
            asc_release.AscHttpError(409, "conflict"),
            urllib.error.HTTPError("https://x", 404, "missing", {}, None),
            ValueError("bad"),
            ReleaseError("mismatch"),
            SystemExit(1),
        ]
        for exc in transient:
            with self.subTest(exc=repr(exc)):
                self.assertTrue(ios_release.is_transient_error(exc))
        for exc in fatal:
            with self.subTest(exc=repr(exc)):
                self.assertFalse(ios_release.is_transient_error(exc))


class CmdWaitBuildTests(unittest.TestCase):
    def test_deadline_counts_from_upload_start_and_app_lookup_is_retried(self) -> None:
        import argparse
        import http.client

        lookups = []

        def find_app(_client, bundle_id):
            lookups.append(bundle_id)
            if len(lookups) == 1:
                raise http.client.RemoteDisconnected("closed")
            return APP

        fake_module = mock.Mock(find_app=find_app)
        captured = {}

        def fake_wait(client, **kwargs):
            captured.update(kwargs)
            return {"id": "B9"}

        args = argparse.Namespace(
            version=VERSION, build=8, started_at=STARTED, wait_minutes=120, poll_seconds=30
        )
        with tempfile.NamedTemporaryFile("r", suffix=".out") as out, mock.patch.object(
            ios_release, "asc_client", return_value=(fake_module, object())
        ), mock.patch.object(ios_release, "wait_for_build", side_effect=fake_wait), mock.patch.object(
            ios_release.time, "sleep"
        ), mock.patch.object(
            ios_release.time, "time", return_value=STARTED + 30
        ), mock.patch.dict(os.environ, {"GITHUB_OUTPUT": out.name}), redirect_stdout(io.StringIO()):
            ios_release.cmd_wait_build(args)
            written = Path(out.name).read_text()
        self.assertEqual(lookups, [ios_release.BUNDLE_ID] * 2)
        self.assertEqual(captured["deadline"], STARTED + 120 * 60)
        self.assertEqual(captured["uploaded_after"], STARTED)
        self.assertEqual(captured["build_number"], "8")
        self.assertIs(captured["is_transient"], ios_release.is_transient_error)
        self.assertIn("build_id=B9", written)

    def test_app_lookup_gives_up_at_the_deadline(self) -> None:
        import http.client

        def boom():
            raise http.client.RemoteDisconnected("closed")

        clock = FakeClock(STARTED)
        with redirect_stdout(io.StringIO()), self.assertRaises(http.client.RemoteDisconnected):
            ios_release.call_with_retries(
                boom, deadline=STARTED + 90, poll_seconds=30, now=clock.now, sleep=clock.sleep
            )
        self.assertEqual(clock.sleeps, [30, 30, 30])


class FakeAsc:
    """App Store Connect stand-in for asc_release.main() (live path, no network)."""

    def __init__(self, *, state: str = "PREPARE_FOR_SUBMISSION", attached: str | None = "OLD",
                 revert_after_select: bool = False) -> None:
        self.state = state
        self.attached = attached
        self.revert_after_select = revert_after_select
        self.build_reads = 0
        self.calls: list[tuple[str, str]] = []

    def get(self, path: str) -> dict:
        self.calls.append(("GET", path))
        if path.startswith("/apps?"):
            return {"data": [{"id": APP, "attributes": {"bundleId": asc_release.DEFAULT_BUNDLE_ID}}]}
        if path.startswith(f"/apps/{APP}/appStoreVersions"):
            return {"data": [{"id": "V1", "attributes": {"versionString": VERSION, "appStoreState": self.state}}]}
        if path.startswith("/builds/B9"):
            return {"data": build_row("B9"), "included": [pre_row()]}
        if path == "/appStoreVersions/V1/build":
            self.build_reads += 1
            if self.revert_after_select and self.build_reads >= 2:
                return {"data": {"type": "builds", "id": "OLD"}}
            return {"data": {"type": "builds", "id": self.attached} if self.attached else None}
        if path.startswith(f"/apps/{APP}/reviewSubmissions"):
            return {"data": [{"id": "SUB1"}]}
        if path.startswith("/reviewSubmissions/SUB1/items"):
            return {"data": []}
        raise AssertionError(f"unexpected GET {path}")

    def post(self, path: str, body: dict) -> dict:
        self.calls.append(("POST", path))
        return {"data": {"id": "ITEM"}}

    def patch(self, path: str, body: dict) -> dict:
        self.calls.append(("PATCH", path))
        return {"data": body["data"]}

    def request(self, method: str, path: str, body: dict | None = None):
        self.calls.append((method, path))
        if method == "PATCH" and path == "/appStoreVersions/V1/relationships/build":
            self.attached = body["data"]["id"]
        return None


class LiveSubmitFlowTests(unittest.TestCase):
    def run_main(self, fake: FakeAsc, env_flags: dict[str, str] | None = None) -> tuple[int, mock.Mock]:
        products = mock.Mock(return_value=asc_release.ProductSubmitResult("SUB1", 0, False))
        argv = ["asc_release.py", "--version", VERSION, "--build-id", "B9", "--build-number", "8"]
        env = {k: v for k, v in os.environ.items() if k not in FLAG_NAMES}
        env.update(env_flags or {"SUBMIT_IOS_REVIEW": "true"})
        code = 0
        with mock.patch.dict(os.environ, env, clear=True), mock.patch.object(sys, "argv", argv), \
                mock.patch.object(asc_release, "client_from_environment", return_value=fake), \
                mock.patch.object(asc_release, "submit_in_app_purchases", products), \
                redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            try:
                asc_release.main()
            except SystemExit as exc:
                code = exc.code if isinstance(exc.code, int) else 1
        return code, products

    def test_selects_rechecks_then_submits(self) -> None:
        fake = FakeAsc()
        code, products = self.run_main(fake)
        self.assertEqual(code, 0)
        calls = fake.calls
        select = calls.index(("PATCH", "/appStoreVersions/V1/relationships/build"))
        submit = calls.index(("PATCH", "/reviewSubmissions/SUB1"))
        reads = [i for i, c in enumerate(calls) if c == ("GET", "/appStoreVersions/V1/build")]
        build_checks = [i for i, c in enumerate(calls) if c[0] == "GET" and c[1].startswith("/builds/B9")]
        self.assertEqual(len(reads), 2, "selection must be read back and rechecked")
        self.assertTrue(select < reads[0] < reads[1] < submit)
        self.assertEqual(len(build_checks), 2)
        self.assertTrue(build_checks[1] < reads[1] < submit, "build must be re-verified just before submit")
        self.assertIn(("PATCH", "/appStoreVersions/V1"), calls)  # release type
        products.assert_called_once()

    def test_selection_changed_before_submit_aborts(self) -> None:
        fake = FakeAsc(revert_after_select=True)
        code, _ = self.run_main(fake)
        self.assertEqual(code, 1)
        self.assertNotIn(("PATCH", "/reviewSubmissions/SUB1"), fake.calls)

    def test_waiting_for_review_with_another_build_aborts(self) -> None:
        fake = FakeAsc(state="WAITING_FOR_REVIEW", attached="OTHER")
        code, products = self.run_main(fake)
        self.assertEqual(code, 1)
        products.assert_not_called()
        self.assertNotIn(("PATCH", "/reviewSubmissions/SUB1"), fake.calls)

    def test_waiting_for_review_with_this_build_is_idempotent(self) -> None:
        fake = FakeAsc(state="WAITING_FOR_REVIEW", attached="B9")
        code, products = self.run_main(fake)
        self.assertEqual(code, 0)
        products.assert_called_once()
        self.assertNotIn(("PATCH", "/appStoreVersions/V1/relationships/build"), fake.calls)

    def test_metadata_on_a_live_version_is_refused_without_writes(self) -> None:
        fake = FakeAsc(state="READY_FOR_SALE")
        code, _ = self.run_main(fake, {"UPLOAD_LISTING": "true"})
        self.assertEqual(code, 1)
        self.assertFalse([c for c in fake.calls if c[0] != "GET"])


class ReleaseNotesTests(unittest.TestCase):
    TEXT = "# Release notes\n\n## v1.0.2\n\n- Faster search\n\n## v1.0.1\n\n## v1.0.0\n\nFirst edition.\n"

    def test_matching_section_is_used(self) -> None:
        self.assertEqual(release_notes.section_for(self.TEXT, "v1.0.2"), "- Faster search")
        self.assertEqual(release_notes.section_for(self.TEXT, "v1.0.0"), "First edition.")

    def test_missing_section_falls_back_to_generated_notes(self) -> None:
        self.assertIsNone(release_notes.section_for(self.TEXT, "v1.0.3"))

    def test_empty_section_is_an_error(self) -> None:
        with self.assertRaises(ValueError):
            release_notes.section_for(self.TEXT, "v1.0.1")

    def test_repository_notes_parse(self) -> None:
        text = (ROOT / "RELEASE_NOTES.md").read_text(encoding="utf-8")
        self.assertIsNone(release_notes.section_for(text, "v0.0.0-not-a-release"))


class CatalogTests(unittest.TestCase):
    def test_catalog_matches_the_app_and_storekit_configuration(self) -> None:
        quiet(validate_catalog.main)

    def test_catalog_drift_is_caught(self) -> None:
        catalog = json.loads((ROOT / "store/catalog/products.json").read_text())
        catalog["tips"] = catalog["tips"][:3]
        with self.assertRaises(SystemExit):
            quiet(validate_catalog.check, catalog)


if __name__ == "__main__":
    unittest.main()
