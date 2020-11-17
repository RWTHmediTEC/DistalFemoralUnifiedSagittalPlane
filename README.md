# DistalFemoralUnifiedSagittalPlane
An optimization algorithm for establishing a unified sagittal plane (USP) of the distal femur using 3D surface models.

## Reference
Please cite the following papers:<br/>
- [Li 2010] Li et al. - Automating Analyses of the Distal Femur Articular Geometry Based on Three-Dimensional Surface Data. Annals of Biomedical Engineering (2010)
- [Fischer 2020] Fischer et al. - A robust method for automatic identification of femoral landmarks, axes, planes and bone coordinate systems using surface models. Scientific Reports (2020)

## Releases
none

## License
EUPL v1.2

## Usage 
Clone and run *USP_example.m* in MATLAB to test the main function *USP.m*. Comment the different calls of the USP function to test several options. Type *help USP* to get a detailed description of the options.<br/>
The distal femur is moved from the coordinate system of the medical imaging system to its centroid. The distal femur has to be aligned according to Table 1 to guarantee a working calculation.
This initial transformation depends on the medical imaging system and is stored in the MAT-file as a vector of three Euler angles*. In addition, the side has to be defined: 'L'eft or 'R'ight knee.<br/>

**<sub>Table 1: Required initial orientation of the distal femur</sub>**
|   Axes   | X         | Y        | Z                                      |
|:--------:|-----------|----------|----------------------------------------|
| Negative | Posterior | Distal   | Right knee: Medial, Left knee: Lateral |
| Positive | Anterior  | Proximal | Right knee: Lateral, Left knee: Medial |

<sub>*Three Cardan angles aka Tait-Bryan angles given in degrees using the 'ZYX' convention (global basis aka extrinsic rotations). 
This means a rotation around the Z-axis is followed by a rotation around the Y-axis is followed by a rotation around the X-axis.
But all rotations occur about the axes of the fixed coordinate system. Values between -180° and 180° are valid.</sub>

### USP GUI
As an alternative *USP_GUI.m* can be used and a distal femur can be loaded. The bone with the grey default sagittal plane (DSP) can be adjusted with the six rotate buttons bellow the bone (Figure 1). 
If a MAT-file of the subject exists in the folder "results", the USP was already calculated and the USPTFM from the previous calculation can be used for the initial transformation of the bone.
![USP_InitialOrientation](https://user-images.githubusercontent.com/43516130/99388704-47581780-28d6-11eb-8f5c-da91db4396ca.png)<br/>
**<sub>Figure 1: Required initial orientation of the distal femur</sub>**

#### The rough/fine iteration method
- For a fast calculation, the default settings should be used and all plotting options should be disabled.
- For the initial rough search the *-/+ Plane Variation* may be set to 4° and the step size to 2° resulting in a quadratic search field of ((4° x 2 / 2°) + 1)² = 25 plane variations (default).
- After the start of the calculation, the rough search is repeated as long as the minimum dispersion lies on the boundaries of the search field (4°) (Figure 2). 
Once the minimum dispersion lies inside the search field a finer search with a step size of 0.5° is performed (Figure 2). 
The *-/+ Plane Variation* is set to the step size of the rough search minus the step size of the fine search (2° - 0.5° = 1.5°) resulting in a quadratic search field of ((1.5° x 2 / 0.5°) + 1)² = 49 plane variations.
- The results can be saved after the calculation is finished.
After each calculation a table with results for the minimum dispersion is printed in the MATLAB command window.
![USP_DispersionPlot](https://user-images.githubusercontent.com/43516130/99388735-52ab4300-28d6-11eb-8829-a7868a9383e9.png)<br/>
**<sub>Figure 2: Rough iterations and the final fine iteration</sub>**

## USP method
The framework is based on the paper: 2010 - Li et al. - Automating Analyses of the Distal Femur Articular Geometry Based on Three-Dimensional Surface Data.<br/>

The input consists of a triangulated surface model of the distal femur, the side of the femur and an initial transformation from the coordinate system of the medical imaging system into the DSP (see Table 1). 
The XY-plane is the DSP due to the initial transformation of the bone surface into its centroid.<br/>

The initially transformed bone surface is passed to the main function that adheres closely to the framework proposed by Li et al. to calculate the USP. 
Two cutting boxes each filled with eight parallel cutting planes are positioned on the most posterior point of each femur condyle. 
The orientation of the boxes is varied in an iterative manner (Algorithm 3). For each variation the articulating parts of the contour profiles defined by the cutting planes are determined (Algorithm 1). 
Ellipses are fitted to the contour parts (Algorithm 2) and the 2D dispersion of the posterior foci of these ellipses is calculated (Algorithm 3). 
The variation with the smallest dispersion is defined as the USP. Algorithm 3 encloses Algorithm 1 and Algorithm 2 successively.<br/>

Improvements have been made to the iteration process of Algorithm 3. First the position of the dispersion minimum is localized by a rough search with a larger step size of the plane variation. 
Subsequently, a fine search with a plane variation of 0.5° is performed around the dispersion minimum of the rough search to improve the position of the USP. 
For a "-/+ Plane Variation" of 8° the method of Li requires 33² = 1089 plane variations. The rough/fine iteration method requires two initial rough searches and one subsequent fine search, 25 + 25 + 49 = 99 plane variations. 
The number of iterations is reduced about one-tenth compared with the method of Li et al. In addition parallel computing was implemented for the computationally-intensive parts of the framework to reduce computing time.