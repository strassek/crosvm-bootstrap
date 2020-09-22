#! /usr/bin/env python3

# create-image.py
# Generates a disk image using dd, formats it to desired filesystem and then
# mounts it. Use the image.json example to configure this utility for deployment
# Also includes helper function to unmount specified disk.

from enum import Enum
import argparse
import json
import os
import os.path

class FilesystemType(Enum):
    # Enum of supported filesystems
    # To add new FS type, simply add to this list and add CLI args in the map
    EXT2 = "ext2"
    EXT3 = "ext3"
    EXT4 = "ext4"
    FAT32 = "fat32"

    def toCommand(self):
        commandMap = {FilesystemType.EXT2: "mkfs.ext2",
                      FilesystemType.EXT3: "mkfs.ext3",
                      FilesystemType.EXT4: "mkfs.ext4",
                      FilesystemType.FAT32: "mkfs.fat -F32"}
        return commandMap[self]
    
    # Static helper function to return the correct Enum value if it exists or
    # emit a warning and use a default if it doesn't. (Avoids ValueError exception)
    @staticmethod
    def fromString(fstype):
        try:
            return FilesystemType(fstype)
        except ValueError:
            print(fstype + " is not a supported filesystem type, defaulting to ext4")
            return FilesystemType.EXT4

class ImageDefinition:
    def __init__(self, jsonFile=None):
        # Default disk image parameters
        self.path = "output/"
        self.name = "rootfs.img"
        self.fstype = FilesystemType.EXT4
        self.isSparse = True
        self.sizeInMB = 2048
        if jsonFile is None:
            return

        # Override defaults with values from json file
        if os.path.exists(jsonFile):
            try:
                with open(jsonFile) as f:
                    image_config = json.load(f)
                    if image_config is not None:
                        if image_config.get("path") is not None:
                            self.path = image_config["path"]
                        if image_config.get("name") is not None:
                            self.name = image_config["name"]
                        if image_config.get("fstype") is not None:
                            self.fstype = FilesystemType.fromString(
                                image_config["fstype"])
                        if image_config.get("isSparse") is not None:
                            self.isSparse = image_config["isSparse"]
                        if image_config.get("sizeInMB") is not None:
                            self.sizeInMB = image_config["sizeInMB"]
            except ValueError:
                print("Failed to decode image spec file. Ensure it's valid json.")
                raise
            except OSError:
                print("Something went wrong")
                raise
        else:
            print("Failed to find image spec json file (" + jsonFile + ")")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", help="Specify image spec json file.", 
                        metavar="FILE", nargs=1, default=["config/image.json"])
    parser.add_argument("--create", action="store_true",
                        help="Create the specified image")
    args = vars(parser.parse_args())

    #print (args)
    targetImage = ImageDefinition(args["spec"][0])
    targetImagePath = targetImage.path + "/" + targetImage.name

    if args["create"]:
        dd_count = targetImage.sizeInMB if not targetImage.isSparse else 0
        dd_seek = targetImage.sizeInMB if targetImage.isSparse else 0
        dd_cmd = ("dd if=/dev/zero of={0} bs=1M count={1} seek={2}").format(
            targetImagePath, dd_count, dd_seek)
        #print (dd_cmd)
        os.system(dd_cmd)
        mkfs_cmd = targetImage.fstype.toCommand() + " " + targetImagePath
        #print (mkfs_cmd)
        os.system(mkfs_cmd)
