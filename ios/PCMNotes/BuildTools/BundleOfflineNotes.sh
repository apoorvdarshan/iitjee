#!/bin/sh

set -eu

: "${PROJECT_DIR:?Xcode PROJECT_DIR is required}"
: "${BUILD_DIR:?Xcode BUILD_DIR is required}"
: "${TARGET_BUILD_DIR:?Xcode TARGET_BUILD_DIR is required}"
: "${UNLOCALIZED_RESOURCES_FOLDER_PATH:?Xcode resources path is required}"

archive_root="${PROJECT_DIR}/../.."
generator_source="${PROJECT_DIR}/BuildTools/GenerateOfflineNotes.swift"
generator_binary="${BUILD_DIR}/OfflineNotesGenerator"
cache_root="${BUILD_DIR}/OfflineNotesCache"
bundle_root="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/OfflineNotes"

mkdir -p "${BUILD_DIR}" "${cache_root}" "${bundle_root}"

if [ ! -x "${generator_binary}" ] || [ "${generator_source}" -nt "${generator_binary}" ]; then
    xcrun --sdk macosx swiftc \
        -parse-as-library \
        "${generator_source}" \
        -framework AppKit \
        -framework PDFKit \
        -o "${generator_binary}"
fi

"${generator_binary}" "${archive_root}" "${cache_root}"
/usr/bin/ditto "${cache_root}" "${bundle_root}"
