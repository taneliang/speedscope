#!/bin/bash

set -euxo pipefail

OUTDIR=`pwd`/dist/release
OUTDIR_LIBRARY=`pwd`/dist/library

# Typecheck
node_modules/.bin/tsc --noEmit

# Run unit tests
npm run jest

# Clean out the release directory
rm -rf "$OUTDIR"
mkdir -p "$OUTDIR"

# Place info about the current commit into the build dir to easily identify releases
npm ls -depth -1 | head -n 1 | cut -d' ' -f 1 > "$OUTDIR"/release.txt
date >> "$OUTDIR"/release.txt
git rev-parse HEAD >> "$OUTDIR"/release.txt

# Place a json schema for the file format into the build directory too
node scripts/generate-file-format-schema-json.js > "$OUTDIR"/file-format-schema.json

# Build the compiled assets
node_modules/.bin/parcel build assets/index.html --no-cache --out-dir "$OUTDIR" --public-url "./" --detailed-report

# Clean out the library release directory
rm -rf "$OUTDIR_LIBRARY"
mkdir -p "$OUTDIR_LIBRARY"

# Build library
node_modules/.bin/tsc --project tsconfig.dist-lib.json --outDir "$OUTDIR_LIBRARY"

# Generate Flow definition files
for i in $(find ${OUTDIR_LIBRARY} -type f -name "*.d.ts");
  do flowgen $i -o ${i%.*.*}.js.flow --add-flow-header --no-inexact;
done;
