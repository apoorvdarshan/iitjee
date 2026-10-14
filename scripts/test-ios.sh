#!/bin/bash
# Unsigned Debug simulator tests for PCM Notes. Never archives, signs or uploads.
#
#   1. builds the app and both test bundles once,
#   2. runs the unit tests and every UI test except the iPad-only ones on an iPhone,
#   3. runs the iPad-only UI tests (iPadReaderUITests) on an iPad,
#   4. fails if either run failed, ran no tests, or skipped a test.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

derived_data="${IOS_TEST_DERIVED_DATA:-$HOME/Library/Developer/Xcode/DerivedData/iitjee-simulator-tests}"
packages="${IOS_TEST_PACKAGES:-$derived_data/SourcePackages}"
results="${IOS_TEST_RESULTS:-$derived_data/TestResults/$(date -u +%Y%m%dT%H%M%SZ)-$$}"
ipad_only="iitjeeUITests/iPadReaderUITests"
mkdir -p "$results"
for bundle in Build iPhone iPad; do
  if [[ -e "$results/$bundle.xcresult" ]]; then
    echo 'Choose an unused IOS_TEST_RESULTS directory; existing results are preserved.' >&2
    exit 1
  fi
done

xcodebuild -version

# The app bundles PDFs generated from these note images (BuildTools/GenerateOfflineNotes.swift).
for subject in physics chemistry mathematics; do
  if ! compgen -G "$subject/*/*.jpg" > /dev/null; then
    echo "Missing $subject/ note images: the app bundles every chapter as a PDF built from them." >&2
    exit 1
  fi
done

# Create task-owned simulators: never erase or reset a developer's existing ones.
iphone_id=""
ipad_id=""
cleanup() {
  # Only the simulators created by this invocation are removed.
  for id in $iphone_id $ipad_id; do
    xcrun simctl shutdown "$id" >/dev/null 2>&1 || true
    xcrun simctl delete "$id" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

read -r runtime iphone_type ipad_type < <(python3 - <<'PY'
import json, subprocess
data = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', '--json']))
def version(runtime):
    return tuple(int(part) for part in runtime['version'].split('.'))
runtimes = [r for r in data['runtimes'] if r.get('isAvailable') and
            '.iOS-' in r['identifier'] and version(r) >= (17, 6)]
if not runtimes:
    raise SystemExit('Install an iOS 17.6 or newer Simulator runtime in Xcode.')
runtime = max(runtimes, key=version)
types = runtime.get('supportedDeviceTypes', [])
def pick(family, preferred):
    devices = [d for d in types if d.get('productFamily') == family]
    if not devices:
        raise SystemExit(f'The iOS {runtime["version"]} runtime has no {family} simulator.')
    by_name = {d['name']: d for d in devices}
    return next((by_name[name] for name in preferred if name in by_name), devices[0])
iphone = pick('iPhone', ['iPhone 17 Pro', 'iPhone 16 Pro', 'iPhone 17'])
ipad = pick('iPad', ['iPad Pro 13-inch (M5)', 'iPad Pro 13-inch (M4)', 'iPad Air 13-inch (M3)'])
print(runtime['identifier'], iphone['identifier'], ipad['identifier'])
PY
) || true
if [[ -z "${ipad_type:-}" ]]; then
  echo 'Could not choose iPhone and iPad simulators.' >&2
  exit 1
fi
iphone_id="$(xcrun simctl create 'PCM Notes CI iPhone' "$iphone_type" "$runtime")"
ipad_id="$(xcrun simctl create 'PCM Notes CI iPad' "$ipad_type" "$runtime")"
echo "Simulators: iPhone $iphone_type ($iphone_id), iPad $ipad_type ($ipad_id) on $runtime"

common=(
  -project ios/iitjee/iitjee.xcodeproj
  -scheme iitjee
  -configuration Debug
  -derivedDataPath "$derived_data"
  -clonedSourcePackagesDirPath "$packages"
  -onlyUsePackageVersionsFromResolvedFile
  -enableCodeCoverage YES
)
run_tests=(
  -destination-timeout 120
  -parallel-testing-enabled NO
  -maximum-concurrent-test-simulator-destinations 1
)

# Both simulators share the iOS Simulator SDK and architecture, so one build serves both.
xcodebuild build-for-testing "${common[@]}" \
  -destination "platform=iOS Simulator,id=$iphone_id" \
  -resultBundlePath "$results/Build.xcresult" \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$results/build.log"

# Boot the iPad while the iPhone tests run, so its run does not start with a cold
# boot. (Booting during the build instead starves the build of CPU.)
xcrun simctl boot "$ipad_id" &
ipad_boot=$!

status=0
xcodebuild test-without-building "${common[@]}" "${run_tests[@]}" \
  -destination "platform=iOS Simulator,id=$iphone_id" \
  -skip-testing:"$ipad_only" \
  -resultBundlePath "$results/iPhone.xcresult" \
  2>&1 | tee "$results/iphone.log" || status=1

# If the early boot failed, xcodebuild boots the iPad itself.
wait "$ipad_boot" || echo "warning: early iPad boot failed; xcodebuild will boot it" >&2

xcodebuild test-without-building "${common[@]}" "${run_tests[@]}" \
  -destination "platform=iOS Simulator,id=$ipad_id" \
  -only-testing:"$ipad_only" \
  -resultBundlePath "$results/iPad.xcresult" \
  2>&1 | tee "$results/ipad.log" || status=1

python3 scripts/ios_test_summary.py "$results/iPhone.xcresult" --require-unit --require-ui || status=1
python3 scripts/ios_test_summary.py "$results/iPad.xcresult" --require-ui || status=1
echo "Results: $results"
exit "$status"
