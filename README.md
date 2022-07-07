# Zed Fonts
**Zed Mono** & **Zed Sans** are custom builds of [Iosevka](https://github.com/be5invis/Iosevka) liscensed under the SIL Open Font License, Version 1.1.

They are built for use in [Zed](zed.dev). **Zed Sans** uses a quasi-proportional spacing to allow the font to still feel monospace while not having such wide gaps in a UI setting.

You can read the [license here](README.md).

## Building Zed Mono

Custom configurations are set up in `private-build-plans.toml`.

1. Install node modules with `npm install`
2. Run `npm run build -- contents::zed-mono` to build the font.
3. Output will be in `/dist`

Don't check the `/dist` folder into the repo!
