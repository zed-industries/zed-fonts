#!/usr/bin/env bash
set -euo pipefail

version="1.3.2-pre"

cd iosevka
npm install

#ttfautohint --version > /dev/null || (echo "ttfautohint is not installed" && exit 1)
# npm run build -- ttf::zed-mono ttf::zed-mono-nl ttf::zed-sans

npm run build -- ttf-unhinted::zed-mono ttf-unhinted::zed-mono-nl ttf-unhinted::zed-sans

cd ..
mkdir -p releases
pushd releases

# This is the recommended bundle for use in Zed
font_dir="zed-app-fonts-${version}"
rm -rf "$font_dir"
mkdir -p "$font_dir"
cp ../iosevka/dist/zed-mono/TTF-Unhinted/Zed-Mono-Extended{,Bold,BoldItalic,Italic}.ttf "$font_dir"
cp ../iosevka/dist/zed-sans/TTF-Unhinted/Zed-Sans-Extended{,Bold,BoldItalic,Italic}.ttf "$font_dir"
zip -r "zed-app-fonts-${version}.zip" "${font_dir}/"

popd
