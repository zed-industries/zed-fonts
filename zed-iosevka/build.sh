#!/usr/bin/env bash
set -euo pipefail

ttfautohint --version > /dev/null || (echo "ttfautohint is not installed" && exit 1)

npm install
npm run clean
npm run build -- ttf-unhinted::zed-mono
npm run build -- ttf-unhinted::zed-mono-nl
npm run build -- ttf-unhinted::zed-sans
