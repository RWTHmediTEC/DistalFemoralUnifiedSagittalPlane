function [USPTFM, PFEA, CEA, MED_A, MED_B, LAT_A, LAT_B] = ...
    USP(distalFemur, side, initialRot, varargin)
% USP An optimization algorithm for establishing a Unified Sagittal Plane.
%     USPTFM = USP(Vertices, Faces, Side, InitialRot) returns a 3D 
%     transform to move the distal femur from the coordinate system of the 
%     medical imaging system into the USP-system.
%     
%     [USPTFM, PFEA, CEA, MED_A, MED_B, LAT_A, LAT_B] = ...
%         USP(Vertices, Faces, Side, InitialRot) additionally returns the 
%     Posterior Focal Elliptic Axis (PFEA), the Center Elliptic Axis (CEA),
%     defined in the USP-system and the mean length of the semi-major and 
%     -minor axes of the medial & lateral side (MED_A, MED_B, LAT_A, LAT_B)
% 
% INPUT:
%   - REQUIRED:
%     distalFemur - struct: A clean mesh of the distal femur defined by the 
%       fields vertices (double [Nx3]) and faces (integer [Mx3]) 
%     side - Char: Left or right distal femur. Should start with L or R.
%     initalRot - Double [1x3]: Three Cardan angles aka Tait-Bryan angles,
%                 given in degrees using the 'ZYX' convention (fixed basis
%                 aka extrinsic rotations). Values between -180° and 180°
%                 are valid.
%                 The distal femur has to be rotated from the coordinate
%                 system of the medical imaging system into the default
%                 sagittal plane system, defined as:
%                 _________________________________________________________
%                 Axes       |      X      |      Y      | Z dep. on Side |
%                   Positive |   Anterior  |   Proximal  | Medial/Lateral |
%                   Negative |  Posterior  |    Distal   | Medial/Lateral |
% 
%   - OPTIONAL:
%     'Subject' - Char: Identification of the subject. Default is 'anonymous'.
%     'Center'  - Double [1x3]: Position of the origin of the coordinate 
%                 system. Default is 'mean(Vertices)'.
%     'PlaneVariationRange' - Integer [1x1]: Defines the size of the search
%                             field of the rough iterations. Default value 
%                             is 4° resulting in a quadratic search field 
%                             of -/+ 4°. Values between 0° and 16° are 
%                             valid. 4° seems to be a proper value for the 
%                             tested meshes. Higher values increase the 
%                             number of plane variations and the running 
%                             time. Lower values may miss the global 
%                             disperion minimum. 
%                             Set to 0° the Algorithm is executed only once
%                             and no results will be produced.
%     'StepSize' - Integer [1x1]: Defines the step size during the rough
%                  iterations. Default value is 2°. Values between 1° and 
%                  4° are valid. E.g. with a PlaneVariationRange of 4° it
%                  results in a search field of:
%                  ((4° x 2 / 2°) + 1)² = 25 plane variations
%     'Visualization' - Logical: Figure output. Default is true.
%     'Verbose' - Logical: Command window output. Default is true.
% 
% OUTPUT:
%     USPTFM - Double [4x4]: A transformation matrix to move the mesh of 
%              the distal femur from the coordinate system of the medical 
%              imaging system into the USP-system.
%     PFEA - Double [1x6]: A line fitted through the posterior foci of the
%            ellipses with minimum dispersion.
%     CEA - Double [1x6]: A line fitted through the centers of the ellipses
%           with minimum dispersion.
%     MED_A - Semi-major axis of the medial condyle
%     MED_B - Semi-minor axis of the medial condyle
%     LAT_A - Semi-major axis of the lateral condyle
%     LAT_B - Semi-minor axis of the lateral condyle
% 
% EXAMPLE:
%     Run the file 'USP_example.m'
% 
% REFERENCE:
%     Li et al. - Automating Analyses of the Distal Femur Articular
%     Geometry Basedon Three-Dimensional Surface Data
%     Annals of Biomedical Engineering, Vol. 38, No. 9, September 2010
%     pp. 2928–2936
% 
% TODO:
% 
% AUTHOR: Maximilian C. M. Fischer
% 	mediTEC - Chair of Medical Engineering, RWTH Aachen University
% VERSION: 2.0.0
% DATE: 2020-11-18
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

narginchk(5,15);

% Validate inputs
[GD.Subject.Side, GD.Subject.Name, GD.Subject.Center, ...
    GD.Algorithm3.PlaneVariationRange, GD.Algorithm3.StepSize, ...
    GD.Visualization, GD.Verbose] = ...
    validateAndParseOptInputs(distalFemur, side, initialRot, varargin{:});
GD.Subject.Mesh = distalFemur;
GD.Subject.InitialRot = initialRot;

% USP path
GD.ToolPath = [fileparts([mfilename('fullpath'), '.m']) '\'];

% Add src path
addpath(genpath([GD.ToolPath 'src']));

% Compile mex file if not exist
mexPath = [GD.ToolPath 'src\external\intersectPlaneSurf'];
if ~exist([mexPath '\IntersectPlaneTriangle.mexw64'],'file')
    mex([mexPath '\IntersectPlaneTriangle.cpp'],'-v','-outdir', mexPath);
end

if GD.Visualization == 1
    % Figure
    GD.Figure.Color = 'w';
    MonitorsPos = get(0,'MonitorPositions');
    FH = figure(...
        'Units','pixels',...
        'NumberTitle','off',...
        'Color',GD.Figure.Color,...
        'ToolBar','figure',...
        'WindowScrollWheelFcn',@M_CB_Zoom,...
        'WindowButtonDownFcn',@M_CB_RotateWithMouse,...
        'renderer','opengl');
    if     size(MonitorsPos,1) == 1
        set(FH,'OuterPosition',MonitorsPos(1,:));
    elseif size(MonitorsPos,1) == 2
        set(FH,'OuterPosition',MonitorsPos(2,:));
    end
    FH.MenuBar = 'none';
    FH.ToolBar = 'none';
    FH.WindowState = 'maximized';
    GD.Figure.Handle = FH;
    
    % 3D view
    LPT = uipanel('Title','3D view','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.01 0.01 0.49 0.99]);
    LH = axes('Parent', LPT, 'Visible','off', 'Color',GD.Figure.Color,'Position',[0.05 0.01 0.9 0.9]);
    GD.Figure.D3Handle = LH;
    
    % 2D view
    RPT = uipanel('Title','2D view','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.51 0.48 0.49]);
    RH = axes('Parent', RPT, 'Visible','off', 'Color',GD.Figure.Color);
    axis(RH, 'on'); axis(RH, 'equal'); grid(RH, 'on'); xlabel(RH, 'X [mm]'); ylabel(RH, 'Y [mm]');
    GD.Figure.D2Handle = RH;
    
    % A convergence plot as a function of alpha and beta.
    RPB = uipanel('Title','Convergence progress','FontSize',14,'BorderWidth',2,...
        'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.01 0.48 0.49]);
    IH = axes('Parent', RPB, 'Visible','off', 'Color',GD.Figure.Color);
    axis(IH, 'equal', 'tight'); view(IH,3);
    xlabel(IH,'\alpha [°]');
    ylabel(IH,'\beta [°]');
    zlabel(IH, 'Dispersion [mm]')
    title(IH, 'Dispersion of the posterior foci as function of \alpha & \beta','FontSize',14)
    GD.Figure.DispersionHandle = IH;
end

% Number of cutting planes per cutting box
GD.Algorithm3.NoCuttingPlanes = 8;

% Load Subject
GD = LoadSubject('no handle', GD);

% Visualization settings
if GD.Visualization == 1
    GD.Algorithm3.PlotPlaneVariation = 1;
    GD.Algorithm3.EllipsePlot = 1;
    if GD.Algorithm3.PlaneVariationRange == 0
        GD.Algorithm1.PlotContours = 1;
    else
        GD.Algorithm1.PlotContours = 0;
    end
elseif GD.Visualization == 0
    GD.Algorithm3.PlotPlaneVariation = 0;
    GD.Algorithm3.EllipsePlot = 0;
    GD.Algorithm1.PlotContours = 0;
end

% Start rough/fine iteration process
GD = RoughFineIteration('no handle', GD);

%% Check results, if they exist
if GD.Algorithm3.PlaneVariationRange ~= 0
    % Calculate the transformation (USPTFM) from the initial bone position into the USP
    USPTFM  = GD.Results.USPTFM;
    % Calculate the axes (PFEA & CEA) in the USP system
    PFEA = GD.Results.PFEA;
    CEA = GD.Results.CEA;
    % Calculate the semi-axes in the USP system
    MED_A = GD.Results.Ell.Med.a(1);
    MED_B = GD.Results.Ell.Med.b(1); 
    LAT_A = GD.Results.Ell.Lat.a(1);
    LAT_B = GD.Results.Ell.Lat.b(1);
    
    % Check if the PFEA has 4 intersections with the bone:
    % 2 intersections with the medial condyle
    % 2 intersections with the lateral condyle
    [~, ~, I_IntPFEABone] = intersectLineMesh3d(PFEA, ...
        transformPoint3d(GD.Subject.Mesh.vertices, GD.Subject.TFM),...
        GD.Subject.Mesh.faces);
    if numel(I_IntPFEABone)~=4
        warning(['Posterior focal elliptic axis (PFEA) should have 4 intersection points with the bone surface', ...
            'But number of intersection points is: ' num2str(numel(I_IntPFEABone)) '!']);
    end
    
    % Check if the lateral side is bigger than the medial side.
    if GD.Results.Ell.Med.a(1) > GD.Results.Ell.Lat.a(1)
        warning('The mean length of the semi-major axis of the fitted ellipses is bigger for the medial condyle.');
    end
elseif GD.Algorithm3.PlaneVariationRange == 0
    warning('PlaneVariationRange == 0 -> No Results!')
    USPTFM = eye(4);
    PFEA = [zeros(1,5), 1];
    CEA = [zeros(1,5), 1];    
    MED_A = NaN;
    MED_B = NaN;
    LAT_A = NaN;
    LAT_B = NaN;
end

end


%% Input parameter validation
function [Side, Subject, Center, PlaneVariationRange, StepSize, Visualization, Verbose] = ...
    validateAndParseOptInputs(Femur, Side, InitialRot, varargin)

Side = upper(Side(1));

validateattributes(Femur.vertices, {'numeric'},{'ncols', 3});
validateattributes(Femur.faces, {'numeric'},{'integer','nonnegative','nonempty','ncols', 3});
validatestring(Side, {'R','L'});
validateattributes(InitialRot, {'numeric'},{'>=', -180, '<=', 180,'size', [1 3]});

% Parse the input P-V pairs
defaults = struct(...
    'Subject', 'anonymous', ...
    'Center', mean(Femur.vertices), ...
    'PlaneVariationRange', 4, ...
    'StepSize', 2, ...
    'Visualization', true, ...
    'Verbose', true);

parser = inputParser;
parser.CaseSensitive = false;

parser.addParameter('Subject', defaults.Subject, ...
    @(x)validateattributes(x,{'char'}, {}));
parser.addParameter('Center', defaults.Center, ...
    @(x)validateattributes(x,{'numeric'}, {'nonempty','size', [1 3]}));
parser.addParameter('PlaneVariationRange', defaults.PlaneVariationRange, ...
    @(x)validateattributes(x,{'numeric'}, {'integer', 'nonempty', 'numel',1, '>=',0, '<=',16}));
parser.addParameter('StepSize', defaults.StepSize, ...
    @(x)validateattributes(x,{'numeric'}, {'integer', 'nonempty', 'numel',1, '>=',1, '<=',4}));
parser.addParameter('Visualization', defaults.Visualization, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));
parser.addParameter('Verbose', defaults.Verbose, ...
    @(x)validateattributes(x,{'logical'}, {'scalar','nonempty'}));

parser.parse(varargin{:});

Subject             = parser.Results.Subject;
Center              = parser.Results.Center;
PlaneVariationRange = parser.Results.PlaneVariationRange;
StepSize            = parser.Results.StepSize;
Visualization       = parser.Results.Visualization;
Verbose             = parser.Results.Verbose;

end

