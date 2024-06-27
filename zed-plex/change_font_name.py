import fontforge
import re

def change_font_name(input_file, output_file):
    font = fontforge.open(input_file)

    type = ""
    match = re.search(r'-(\w+)\.ttf$', input_file)
    if match:
        type = match.group(1)

    # Set the new font names while preserving the original weight and other properties
    font.fontname = "ZedPlexSans-" + type
    font.fullname = "Zed Plex Sans " + type
    font.familyname = "Zed Plex Sans"
    font.copyright = "Copyright © 2024 IBM Corp. All rights reserved. Ligatures adapted from Fira Code (Copyright © 2015-2023 The Fira Code Project Authors). Ligatures further refined by Zed Industries, Inc. for enhanced readability and coding experience."
    font.sfntRevision = 0x00030000

    font.appendSFNTName(0x409, 16, "Zed Plex Sans")
    font.appendSFNTName(0x409, 3, "Zed Plex Sans " + type + ";20240627")

    # Generate the new font file
    font.generate(output_file)

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python change_font_name.py input.ttf output.ttf")
    else:
        change_font_name(sys.argv[1], sys.argv[2])
