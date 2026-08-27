#!/bin/bash
# Prepare the Typst universe package for submission.
# Creates packages/preview/scoryst/0.1.0/ with only the required files.
#
# To submit: fork https://github.com/typst/packages, copy the output
# directory into packages/preview/, and open a PR.

set -e
cd "$(dirname "$0")/.."

VERSION=$(grep '^version' pkg/typst.toml | sed 's/.*"\(.*\)"/\1/')
OUT="dist/packages/preview/scoryst/$VERSION"

echo "Packaging scoryst v$VERSION"

rm -rf dist/
mkdir -p "$OUT"

cp pkg/typst.toml "$OUT/"
cp pkg/scoryst.typ "$OUT/"
cp pkg/scoryst.wasm "$OUT/"
cp README.md "$OUT/"
cp LICENSE "$OUT/"

echo "Package ready at $OUT/"
echo "Files:"
ls -lh "$OUT/"
echo ""
echo "Total size: $(du -sh "$OUT" | cut -f1)"
