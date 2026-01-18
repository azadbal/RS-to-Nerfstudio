# RS-to-Nerfstudio

This repo automates the training of gaussian splats using RealityScan for image alignment and NerfStudio Splatfacto for 3DGS training.

The entire workflow can be run by a single batch script `_RunAllSteps.bat` or each stepncan be run individually with its corresponding batch script. 

## What it does
- Aligns images in RealityScan/RealityCapture.
- Exports registration (poses) and sparse point cloud.
- Converts to COLMAP format using `ns-process`.
- Trains with splatfacto.
- Exports the latest splat.

## Requirements
- Windows 10 or 11.
- RealityScan/RealityCapture installed, logged in, and licensed (free or enterprise).
- Conda or Anaconda installed.
- Nerfstudio installed inside a conda environment named `nerfstudio`.


## User_Settings.txt
`User_Settings.txt` is the only file you need to edit. Use it to set:
- RealityScan/RealityCapture installation path
- Project name override
- Image directory 
- Nerfstudio output directories
- Nerfstudio Training parameters (image downscale, max steps, viewer host/port)


## How to run
- Make sure the requirements listed above are met
- Make sure your RealityScan directory is correct in the `User_Settings.txt`
- download the contents of this repo and place the `RS-to-Nerfstudio-main` folder in the root folder of your project, alongside an `images` folder (this can be configured in the `User_Settings.txt` file)
- run everything at once:
  - `_RunAllSteps.bat`
- Or run each step individually:
  - `1-RS-alignment-localCoordinate.bat`
  - `2-RS-to-NS-converter.bat`
  - `3-Nerfstudio-train.bat`
  - `4-Export-latest-splat.bat`


## Folder layout
Place the scripts folder inside your project folder:

```
SanFrancisco-drone-scan/
  images
  RS-to-Nerfstudio-main/
    User_Settings.txt
    1-RS-alignment-localCoordinate.bat
    2-RS-to-NS-converter.bat
    3-Nerfstudio-train.bat
    4-Export-latest-splat.bat
    _RunAllSteps.bat
```

The project root is the parent folder (e.g. `SanFrancisco-drone-scan/`). Output folders like `RC`, `nerfstudio`, `splats`, and `logs` are created in the project root. 

The naming of all outputs (the RS file, splat PLYs) will all be named after the roof folder name (e.g. `SanFrancisco-drone-scan`)
