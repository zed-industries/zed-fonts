# Zed Fonts - Developer Guide

Welcome, contributor! This guide provides a technical overview of the Zed Fonts project, designed to help you understand its architecture, build process, and how to make meaningful contributions. Our primary goal is to produce custom builds of the Iosevka font, specifically tailored for the Zed code editor.

## Core Technologies

* **Base Font**: [Iosevka](https://github.com/be5invis/Iosevka)
* **Build System**: [Verda](https://github.com/be5invis/verda) (orchestrated by `verdafile.js`)
* **Primary Language**: Node.js (JavaScript)
* **Font Compilation**: `ot-builder` and various custom scripts.
* **Configuration**: TOML files for parameters and build plans.

## Project Structure

The main development happens within the `zed-iosevka` subdirectory. Key areas include:

* `zed-iosevka/`: Root of the custom Iosevka build.
    * `build.sh`: Main build script for end-to-end font generation and packaging.
    * `verdafile.js`: Defines build rules and tasks for the Verda build system.
    * `package.json`: Manages Node.js dependencies and scripts.
    * `build-plans.toml`: Defines public build configurations for different font variants.
    * `private-build-plans.toml` (optional, gitignored): For personal or private build configurations.
    * `params/`: Contains TOML files defining various font parameters (shape, weight, variants, ligations).
    * `font-src/`: The heart of the font generation logic.
        * `glyphs/`: (Implicitly, through `buildGlyphs` in `font-src/glyphs/index.js`) Defines individual glyph constructions.
        * `gen/`: Scripts for the main font building pipeline stages.
        * `support/`: Helper modules for geometry, parameters, variants, ligations, etc.
        * `otl/`: Logic for building OpenType Layout (OTL) features.
    * `utility/`: Scripts for various auxiliary tasks like documentation generation, data export, release management, and snapshotting.
    * `snapshot-src/`: Source files for generating font sample images using Electron.
    * `dist/`: Default output directory for built font files.
    * `releases/`: Default output directory for packaged font archives (created by `build.sh`).
* `.zed/settings.json`: Recommended editor settings for Zed.
* `.eslintrc.json`, `.prettierrc.yaml`: Linting and formatting configurations.

## Build Process Overview

1.  **Initiation**: The `build.sh` script is the primary entry point. It typically:
    * Installs Node.js dependencies (`npm install`).
    * Invokes the Verda build system via `verda -f verdafile.js` with specific targets (e.g., `ttf-unhinted::zed-mono`).

2.  **Verda Build System (`verdafile.js`)**:
    * Defines rules, tasks, oracles, and dependencies.
    * Reads `build-plans.toml` and `private-build-plans.toml` to understand what to build.
    * Manages compilation of source scripts (e.g., `.ptl` to `.js`).
    * Orchestrates the font generation pipeline:
        * Unhinted TTF generation.
        * Optional hinting (e.g., using `ttfautohint` if available and specified).
        * Conversion to WOFF2.
        * Creation of TTC/SuperTTC collections.
        * Generation of webfont CSS.
    * Handles creation of release archives (ZIP files).
    * Manages auxiliary tasks like generating sample images, updating READMEs, and creating changelogs.

3.  **Output**:
    * Intermediate files are often stored in `.build/`.
    * Final font files (TTF, WOFF2, CSS) are placed in `dist/<group-name>/`.
    * Packaged archives are placed in `releases/`.

## Font Generation Deep Dive (`font-src/`)

The generation of each font variant follows a sophisticated pipeline:

1.  **Parameter Loading (`font-src/index.js` -> `getParameters`)**:
    * Merges configurations from multiple TOML files in `params/` (e.g., `parameters.toml`, `shape-weight.toml`, `variants.toml`, `ligation-set.toml`).
    * Applies specific parameters based on the build plan (e.g., family name, version, weight, width, slope).
    * Handles metric overrides if specified in the build plan.

2.  **Glyph Construction (`font-src/gen/build-font.js` -> `buildGlyphs`)**:
    * Individual glyphs are defined programmatically (often using `.ptl` files compiled to JavaScript). These definitions specify contours, components, and anchors.
    * The `font-src/glyphs/index.js` orchestrates the inclusion and construction of all glyphs required for a given build.
    * Utilizes `font-src/support/glyph-store.js` to manage glyph objects and their names/encodings.

3.  **OpenType Layout (OTL) Features (`font-src/otl/index.js`)**:
    * Defines GSUB (Glyph Substitution) and GPOS (Glyph Positioning) rules.
    * This includes features like ligatures, character variants (`cvXX`), stylistic sets (`ssXX`), kerning, and mark positioning.
    * Logic is often data-driven, based on parameters and glyph relations defined in `font-src/support/gr.js`.

4.  **Font Finalization (`font-src/gen/finalize/index.js`)**:
    * **Garbage Collection (`gc.js`)**: Removes unused glyphs and OTL lookups to optimize font size. Accessibility is traced from encoded characters and active OTL features.
    * **Glyph Geometry Regulation (`glyphs.js`)**:
        * Unlinks component references for composite glyphs that are not simple transformations of other glyphs.
        * Flattens and simplifies contour-based glyphs. This involves:
            * Applying transformations (like skew for italics).
            * Using a geometry cache (`font-src/gen/caching/index.js`) to speed up processing of identical shapes. The cache uses MessagePack and zlib.
            * Performing boolean operations (e.g., removing overlaps) and fairizing curves using `typo-geom`.
    * **Rank Assignment**: Assigns various ranks (glyphRank, grRank, codeRank, subRank) to glyphs for sorting and processing order.
    * **Validation**: Ensures properties like monospace consistency for "Fixed" variants.

5.  **OTD Conversion (`font-src/gen/otd-conv/index.js`)**:
    * Converts the internal font representation (including glyphs, cmap, GSUB, GPOS, GDEF tables) into an `ot-builder` compatible structure.
    * Glyph naming (`glyph-name.js`): Assigns PostScript names to glyphs based on Unicode values (AGLFN-like), specific relations (e.g., `.NWID`), or a build order fallback.

6.  **Font Output (`font-src/index.js` -> `saveTTF`)**:
    * Uses `ot-builder` to serialize the font object into an SFNT (TTF/OTF) binary.

### Key Support Modules in `font-src/support/`

* **`parameters.js`**: Loads and blends parameters from TOML files.
* **`variant-data.js`**: Parses `variants.toml` to manage character variants (CVs) and stylistic sets (SSs).
* **`ligation-data.js`**: Parses `ligation-set.toml` to manage ligation rules.
* **`gr.js` (Glyph Relations)**: Defines relationships between glyphs (e.g., dotless forms, stylistic alternates, width variants) and maps them to OpenType feature tags. This is crucial for automated OTL feature generation.
* **`geometry/`**: A suite of modules for 2D geometry:
    * `point.js`, `transform.js`, `box.js`, `anchor.js`: Basic geometric primitives.
    * `index.js`: Defines geometry classes like `ContourGeometry`, `SpiroGeometry`, `ReferenceGeometry`, `TransformedGeometry`, `CombineGeometry`, `BooleanGeometry`.
    * `curve-util.js`: Utilities for converting between different curve representations (e.g., Bezier, Spiro) and interfacing with `typo-geom`.
    * `spiro-expand.js`: Implements logic for expanding Spiro curves into outlines, often used for creating strokes or complex shapes.
* **`glyph/index.js`**: Defines the `Glyph` class, representing a single character's design.
* **`glyph-store.js`**: Manages the collection of all glyphs in a font.
* **`kits/`**: Provides higher-level abstractions for defining glyph shapes (e.g., `spiro-kit.js` for Spiro-based drawing, `boole-kit.js` for boolean operations).

## Utilities (`utility/`)

This directory contains scripts for various supporting tasks:

* **`amend-readme/`**: Updates Markdown files (like `README.md`, `doc/*.md`) with dynamically generated content, such as showcases of stylistic sets, character variants, and supported language lists.
* **`export-data/`**: Exports font-related data (metadata, character coverage, variant info, ligation sets) into JSON files. This data is often consumed by the `amend-readme` scripts or for website documentation.
* **`generate-change-log/`**: Creates or updates `CHANGELOG.md` based on versioned fragment files in the `changes/` directory.
* **`generate-release-note/`**: Generates detailed release notes for GitHub releases, including package descriptions and download links. It also produces `doc/PACKAGE-LIST.md`.
* **`generate-snapshot-page/`**: Creates HTML pages used for generating font sample images.
* **`make-webfont-css.js`**: Generates CSS `@font-face` rules for the webfont packages.
* **`ttf-to-woff2.js`**: Converts TTF files to WOFF2 format.
* **`update-package-json-version/`**: Updates the `version` field in `package.json` based on the latest version found in the `changes/` directory.
* **`snapshot-src/` (used by `verdafile.js` and utilities)**: Contains an Electron application (`get-snap.js`, `index.html`, `index.js`) to render fonts in a browser-like environment and capture screenshots for visual testing and documentation.

## Configuration and Customization

* **Build Plans (`build-plans.toml`, `private-build-plans.toml`)**:
    * Define font families, target files, included character variants, ligation sets, spacing, stylistic features, and output formats.
    * `private-build-plans.toml` allows developers to create custom builds without modifying the main tracked configuration.
* **Font Parameters (`params/*.toml`)**:
    * `parameters.toml`: General design parameters.
    * `shape-weight.toml`, `shape-width.toml`, `shape-slope.toml`: Define how weight, width, and slope affect glyph shapes.
    * `variants.toml`: Defines character variants (e.g., `a.alt1`, `g.single_story`) and stylistic sets.
    * `ligation-set.toml`: Defines sets of ligatures.
    * `private-parameters.toml` (optional): For overriding default parameters.

## Key Dependencies

* **`ot-builder`**: Core library for reading, manipulating, and writing OpenType font files.
* **`verda`**: The build system used to manage tasks and dependencies.
* **`spiro` (npm `spiro`)**: Library for generating Spiro curves.
* **`typo-geom`**: Library for 2D geometry operations, including boolean operations on paths.
* **`@iarna/toml`**: For parsing TOML configuration files.
* **`fs-extra`**: Enhanced file system operations.
* **`patel`**: A preprocessor for `.ptl` files (likely a custom templating/macro language for defining glyphs).
* **`wawoff2`**: For WOFF2 compression.
* **Electron** (dev dependency, used by snapshotting): For rendering fonts and capturing images.

## Development Environment

* **Prerequisites**:
    * Node.js (version specified in `package.json`'s `engines` field, e.g., `>=12.16.0`).
    * npm (comes with Node.js).
    * Optionally, `ttfautohint` if you need to build hinted TTF files (the `build.sh` currently focuses on unhinted).
* **Setup**: Run `npm install` in the `zed-iosevka` directory.
* **Linting & Formatting**:
    * ESLint (`.eslintrc.json`): `npm run lint` (if defined in `package.json`, otherwise run `npx eslint .`).
    * Prettier (`.prettierrc.yaml`): `npm run format` (if defined, otherwise run `npx prettier --write .`).
* **Editor Settings**: For Zed editor users, settings are provided in `.zed/settings.json`.

## Contributing

1.  **Understand the Goal**: Familiarize yourself with the desired characteristics of Zed Mono and Zed Sans.
2.  **Modify Parameters**: For changes to character shapes, spacing, weights, variants, or ligatures, you'll primarily edit the TOML files in the `params/` directory or the build plan files.
3.  **Modify Glyph Definitions**: For more fundamental changes to how glyphs are drawn, you might need to edit the source files that define glyphs (often `.ptl` files or JavaScript modules in `font-src/glyphs/` or related areas).
4.  **Add New Glyphs/Features**: This involves defining the new glyph and integrating it into the build process, potentially updating OTL rules and parameter files.
5.  **Improve Utilities**: Contributions to the build scripts or utility scripts are also welcome.
6.  **Build and Test**:
    * Run `./build.sh` to perform a full build and packaging.
    * For more granular builds during development, you can use Verda directly:
        ```bash
        # Example: Build only the unhinted TTF for zed-mono
        node utility/ensure-verda-exists && verda -f verdafile.js ttf-unhinted::zed-mono
        ```
    * Thoroughly test the generated fonts in the Zed editor and other relevant environments.
7.  **Update Documentation**: If your changes affect users or how the font behaves, update relevant Markdown files (READMEs, `doc/` files). Some of this might be automated by the build process if you update the source data for utilities like `amend-readme`.
8.  **Update Changelog**: Add an entry to the appropriate version section in `changes/` (create a new file like `changes/x.y.z.md` if it's a new version). The `CHANGELOG.md` is generated from these fragments.
9.  **Submit a Pull Request**: Follow standard Git and GitHub practices.

## License

This project, including Zed Mono and Zed Sans, is licensed under the SIL Open Font License, Version 1.1. See `LICENSE.md` in the `zed-iosevka` directory for details.

---

This guide should provide a solid foundation for your contributions. Happy font crafting!
