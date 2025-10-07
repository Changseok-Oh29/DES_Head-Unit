# Yocto Layer for Head Unit Project

This directory contains the Yocto build system metadata for the Head Unit project.

## Structure

- `meta-headunit/` - Custom layer for Head Unit application and configurations
  - `conf/` - Layer configuration
  - `recipes-headunit/` - Head Unit application recipes
  - `recipes-images/` - Custom image recipes

## Usage

1. Source the Yocto environment
2. Add this layer to your build configuration:
   ```
   bitbake-layers add-layer path/to/meta-headunit
   ```
3. Build the Head Unit image:
   ```
   bitbake headunit-image
   ```

## Dependencies

- poky (Yocto reference distribution)
- meta-raspberrypi (Raspberry Pi BSP layer)
- meta-qt5 (Qt5 framework support)

## Features

The Head Unit image includes:
- Qt5 runtime environment
- Head Unit application
- USB media support
- Ambient lighting controls
- Gear selection interface
