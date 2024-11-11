#!/usr/bin/env bash
set -euo pipefail


version=$(grep '"version"' package.json | cut -d'"' -f4)
npm install

#ttfautohint --version > /dev/null || (echo "ttfautohint is not installed" && exit 1)
# npm run build -- ttf::zed-mono
# npm run build -- ttf::zed-mono-nl
# npm run build -- ttf::zed-sans

npm run build -- ttf-unhinted::zed-mono
npm run build -- ttf-unhinted::zed-mono-nl
npm run build -- ttf-unhinted::zed-sans

mkdir -p releases
pushd releases
for font in zed-mono zed-mono-nl zed-sans; do
  font_dir="${font}-${version}"
  rm -rf "$font_dir"
  mkdir -p "$font_dir"
  cp -R ../dist/${font}/ttf-unhinted/*.ttf "$font_dir"
  zip -r "${font_dir}.zip" "$font_dir"
done

# This is the recommended bundle for use in Zed
font_dir="zed-app-fonts-${version}"
rm -rf "$font_dir"
mkdir -p "$font_dir"
cp ../dist/zed-mono/ttf-unhinted/zed-mono-extended{,bold,bolditalic,italic}.ttf "$font_dir"
cp ../dist/zed-sans/ttf-unhinted/zed-sans-extended{,bold,bolditalic,italic}.ttf "$font_dir"
zip -r "zed-app-fonts-${version}.zip" "${font_dir}/"

popd
