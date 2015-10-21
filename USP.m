function [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, varargin)

% USP An optimization algorithm for establishing a Unified Sagittal Plane.
%     USPTFM = USP(Vertices, Faces, Side, InitialRot) returns a 3D 
%     transform to move the distal femur from the coordinate system of the 
%     medical imaging system into the USP-system.
%     
%     [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot)
%     additionally returns the Posterior Focal Elliptic Axis (PFEA) and the
%     Center Elliptic Axis (CEA) defined in the USP-system.
% 
% INPUT:
%   - REQUIRED:
%     Vertices - Double [Nx3]: A list of points of the mesh of the distal femur
%     Faces - Integer [Mx3]: A list of triangle faces, indexing into the Vertices
%     Side - Char: 'Left' or 'Right' distal femur
%     InitalRot - Double [1x3]: Three Cardan angles aka Tait-Bryan angles,
%                 given in degrees using the 'ZYX' convention (fixed basis
%                 aka extrinsic rotations). Values between -180° and 180°
%                 are valid.
%                 The distal femur has to be rotated from the coordinate
%                 system of the medical imaging system into the default
%                 sagittal plane system, defined as:
%                 _________________________________________________________
%                 Axes       |      X      |      Y      | Z dep. on Side |
%                   Positive |   Anterior  |   Proximal  | Medial/Lateral |
%                   Negative |  Posterior  |    Distal   | medial/lateral |
% 
%   - ADDITIONAL
%     'Subject' - Char: Identification of the subject. Default is 'unnamed'.
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
% 
% EXAMPLE:
%     Run the file 'USP_Example.m'
% 
% REFERENCE:
%     Li et al. - Automating Analyses of the Distal Femur Articular
%     Geometry Basedon Three-Dimensional Surface Data
%     Annals of Biomedical Engineering, Vol. 38, No. 9, September 2010
%     pp. 2928–2936
% 
% AUTHOR:
%     MCMF


narginchk(5, 13);

% Validate inputs
[Subject, PlaneVariationRange, StepSize, GD.Visualization, GD.Verbose] = ...
    validateAndParseOptInputs(Vertices, Faces, Side, InitialRot, varargin{:});

if sum(strcmp(Side, {'Left','Right'})) == 0
    error('Invalid side indicator. Only ''Left'' or ''Right'' are valid.')
end

% Add path for external functions
addpath(genpath('extern'));
% Add path fur subfunctions
addpath('functions');

% Compile mex file if not exist
CTP = pwd; cd('extern/intersectPlaneSurf')
if ~exist('IntersectPlaneTriangle.mexw64','file')
    mex('IntersectPlaneTriangle.cpp','-v');
end; cd(CTP);

GD.ToolPath = [fileparts([mfilename('fullpath'), '.m']) '\'];
if GD.Visualization == 1
    %% Figure
    GD.Figure.Color = [1 1 1];
    MonitorsPos = get(0,'MonitorPositions');
    GUIFigure = figure('Units','pixels',...
        'Color',GD.Figure.Color,'ToolBar','figure',...
        'WindowScrollWheelFcn',@M_CB_Zoom,'WindowButtonDownFcn',@M_CB_RotateWithLeftMouse,...
        'renderer','opengl');
    if     size(MonitorsPos,1) == 1
        set(GUIFigure,'OuterPosition',MonitorsPos(1,:));
    elseif size(MonitorsPos,1) == 2
        set(GUIFigure,'OuterPosition',MonitorsPos(2,:));
    end
    GD.Figure.Handle = GUIFigure;
    view(3)
    
    %% Subject subplot
    GD.Figure.LeftSpHandle = subplot('Position', [0.05, 0.1, 0.4, 0.8],...
        'Visible', 'off','Color',GD.Figure.Color);
    
    %% Calculation subplot
    GD.Figure.RightSpHandle = subplot('Position', [0.55, 0.1, 0.4, 0.8],'Color',GD.Figure.Color);
    axis on; axis equal; grid on; xlabel('X [mm]'); ylabel('Y [mm]');
end

%% Load Subject
GD.Subject.STL.Vertices = Vertices;
GD.Subject.STL.Faces = Faces;
GD.Subject.STL.InitialRot = InitialRot;
GD.Subject.Side = Side; % Left or Right knee
GD.Subject.Name = Subject; % Subject name
% Number of cutting planes per cuting box
GD.Cond.NoPpC = 8;

GD = LoadSubject(GD);

%% Settings for the framework
% Iteration settings
GD.Algorithm3.PlaneVariationRange = PlaneVariationRange;
GD.Algorithm3.StepSize = StepSize;

% Visualization settings
if GD.Visualization == 1
    GD.Algorithm3.PlaneVariaton = 1;
    GD.Algorithm3.EllipsePlot = 1;
    if GD.Algorithm3.PlaneVariationRange == 0
        GD.Algorithm1.PlotContours = 1;
    else
        GD.Algorithm1.PlotContours = 0;
    end
elseif GD.Visualization == 0
    GD.Algorithm3.PlaneVariaton = 0;
    GD.Algorithm3.EllipsePlot = 0;
    GD.Algorithm1.PlotContours = 0;
end

% Start rough/fine iteration process
GD = RoughFineIteration('no handle', GD);

%% Check results, if they exist
if GD.Algorithm3.PlaneVariationRange ~= 0
    % Calculate the transformation (USPTFM) from the initial bone position into the USP
    PRM = GD.Results.PlaneRotMat;
    USPTFM  = GD.Subject.STL.TFM * PRM;
    if nargout >= 2
        % Calculate the posterior focal elliptic axis (PFEA) in the USP system
        PFEA = [GD.Results.pFociLine(1:3)*PRM(1:3,1:3), GD.Results.pFociLine(4:6)*PRM(1:3,1:3)];
        CEA = [GD.Results.CenterLine(1:3)*PRM(1:3,1:3), GD.Results.CenterLine(4:6)*PRM(1:3,1:3)];
    end
    
    % Check if the PFEA has 4 intersections with the bone:
    % 2 intersections with the medial condyle
    % 2 intersections with the lateral condyle
    [~, ~, I_IntPFEABone] = intersectLineMesh3d(PFEA, GD.Subject.STL.V_C_tfm, GD.Subject.STL.Faces);
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
end

end


%==========================================================================
% Parameter validation
%==========================================================================
function [Subject, PlaneVariationRange, StepSize, Visualization, Verbose] = ...
    validateAndParseOptInputs(Vertices, Faces, Side, InitialRot, varargin)

validateattributes(Vertices, {'numeric'},{'ncols', 3});
validateattributes(Faces, {'numeric'},{'integer','nonnegative','nonempty','ncols', 3});
validateattributes(Side, {'char'},{'nonempty'});
validateattributes(InitialRot, {'numeric'},{'>=', -180, '<=', 180,'size', [1 3]});

% Parse the input P-V pairs
defaults = struct(...
    'Subject', 'unnamed', ...
    'PlaneVariationRange', 4, ...
    'StepSize', 2, ...
    'Visualization', true, ...
    'Verbose', true);

parser = inputParser;
parser.CaseSensitive = false;

parser.addParameter('Subject', defaults.Subject, ...
    @(x)validateattributes(x,{'char'}, {}));
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
PlaneVariationRange = parser.Results.PlaneVariationRange;
StepSize            = parser.Results.StepSize;
Visualization       = parser.Results.Visualization;
Verbose             = parser.Results.Verbose;

end

