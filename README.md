# Devils River

This repository contains data and code used in the paper "UAV-based monitoring of groundwater inputs to surface waters using an economical thermal infrared camera," submitted by Abolt *et al.* to *Optical Engineering*. The paper describes a post-processing method to stabilize thermal imagery captured using a FLIR Vue Pro microbolometer attached to a small UAV. The imagery was collected at a site of groundwater-surface water mixing in the Devils River in west Texas.

The folder 'RawData' includes raw output from the FLIR Vue Pro, provided for completeness. The main script operates on images stored in the folder 'TIFFs - pixel bias removed,' which were produced by subtracting estimated pixel bias from the raw output, using the methods described in the paper.

The files 'devils_tiepts.txt' and 'devils_cameras.txt' contain the coordinates of tie points and the estimated geographic positions of the images, respectively. These files were exported from the software Agisoft Photoscan after creating an initial mosaic from the unprocessed data.

The files 'sceua.m' and 'cceua.m' are functions used to implement the Shuffled Complex Evolution global optimization routine (SCE-UA). The routine is described in the paper "Effective and efficient global optimization for conceptual rainfall-runoff models" by Duan, Gupta, and Sorooshian, in Water Resources Research, vol 28, pp. 1015-1031, 1992.

The main script, 'stabilizeImagery.m,' was written in MATLAB R2017b, and requires the Image Processing Toolbox. To use the algorithm, simply run the script, keeping the directory structure as it appears in the repository. At the end, a stabilized set of images is produced and stored in the folder 'TIFFs - corrected.'
