import fontforge
import re

def change_font_name(input_file, output_file):
    font = fontforge.open(input_file)

    style = ""
    type = ""
    match = re.search(r'(Mono|Sans).*-(\w+)\.ttf$', input_file)
    if match:
        style = match.group(1)
        type = match.group(2)
    else:
        print("Error: Could not parse font name")
        exit(1)

    # Set the new font names while preserving the original weight and other properties
    font.fontname = "ZedPlex" + style + "-" + type
    font.fullname = "Zed Plex " +style+ " " + type
    font.familyname = "Zed Plex " + style
    font.copyright = "Copyright © 2024 IBM Corp. All rights reserved. Ligatures adapted from Fira Code (Copyright © 2015-2023 The Fira Code Project Authors). Ligatures further refined by Zed Industries, Inc. for enhanced readability and coding experience."
    font.sfntRevision = 0x00030000

    font.appendSFNTName(0x409, 16, "Zed Plex " + style)
    font.appendSFNTName(0x409, 3, "Zed Plex " + style + " " + type + ";20240628")

    # Generate the new font file
    font.generate(output_file)

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 3:
        print("Usage: python change_font_name.py input.ttf output.ttf")
    else:
        change_font_name(sys.argv[1], sys.argv[2])
