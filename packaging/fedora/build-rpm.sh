#!/bin/bash
# SPDX-FileCopyrightText: None
# SPDX-License-Identifier: CC0-1.0
#
# Rebuild Fedora's kwin package with kwin-no-relocate.patch applied.
# Runs inside a fedora:<ver> container. Usage: build-rpm.sh <nvr> <outdir>
#   e.g. build-rpm.sh kwin-6.7.5-1.fc44 /out
set -euo pipefail

NVR=$1
OUT=$2
HERE=$(cd "$(dirname "$0")" && pwd)

dnf -y install koji rpm-build rpmdevtools 'dnf-command(builddep)'

TOP=$(mktemp -d)
cd "$TOP"
koji download-build --arch=src "$NVR"
rpm -i --define "_topdir $TOP" ./*.src.rpm

SPEC=$TOP/SPECS/kwin.spec
cp "$HERE/kwin-no-relocate.patch" "$TOP/SOURCES/"
sed -i -E 's/^(Release:\s*)([0-9]+)/\1\2.norelocate/' "$SPEC"
sed -i -E '/^Source1:/a Patch0: kwin-no-relocate.patch' "$SPEC"
grep -nE '^(Release|Patch0):' "$SPEC"

dnf -y builddep "$SPEC"
rpmbuild --define "_topdir $TOP" -ba "$SPEC"

mkdir -p "$OUT"
find "$TOP/RPMS" "$TOP/SRPMS" -name '*.rpm' ! -name '*-debuginfo-*' ! -name '*-debugsource-*' -exec cp {} "$OUT" \;
ls -l "$OUT"
