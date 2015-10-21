function GD = B_CB_Load(hObject, GD)
if ishandle(hObject); GD = guidata(hObject); end
cd(GD.ToolPath)

%% Load Subject Bone

% Subject STL path
GD.Subject.PathMAT = [GD.Subject.DataPath, GD.Subject.Name '.mat'];

load(GD.Subject.PathMAT)

% Find femur index
FI = find(strcmp('Femur', [S(1:2).Name]'));
% Read subject surface data and store
GD.Subject.STL.Vertices = S(FI).Surf.Vertices;
GD.Subject.STL.Faces = S(FI).Surf.Faces;
GD.Subject.Side = S(FI).Side;

%% Set Centroid of the bone as Point of Origin
if isfield(S(FI), 'USP')
    % If exists, use transformation from a previous calculation
    TFM = S(FI).USP.TFM;
    display(['Subject ' GD.Subject.Name ': Data from a previous calculation is used for the initial alignment!']);
else
    % Otherwise, only move the bone to the centroid and turn upside-down
    GD.Subject.STL = GetInertiaInfo(GD.Subject.STL);
    % Rotate around the Z   Y  X axis (global basis)
    InertialRot     = [180, 0, 0];
    TFM = eulerAnglesToRotation3d(InertialRot);
    % Set Centroid of the bone as Point of Origin
    TFM(1:3,4) = GD.Subject.STL.Props.b0;
end
GD.Subject.STL.TFM = TFM;

GD.Subject.STL.V_C_tfm = transformPointsInverse(affine3d(TFM'), GD.Subject.STL.Vertices);


%% Configure subplots
figure(GD.Figure.Handle);
set(GD.Figure.Handle, 'Name', GD.Subject.Name);
% Clear right subplot
subplot(GD.Figure.RightSpHandle); cla reset;
axis on; axis equal; grid on; xlabel('X [mm]'); ylabel('Y [mm]');
set(GD.Figure.RightSpHandle, 'Color', GD.Figure.Color);

% Left subject subplot and properties
subplot(GD.Figure.LeftSpHandle);
cla reset;
axis on; xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
set(GD.Figure.LeftSpHandle,'Color',GD.Figure.Color);
light1 = light; light('Position', -1*(get(light1,'Position')));
lighting phong
daspect([1 1 1])
cameratoolbar('SetCoordSys','none')

%% Visualize Subject Bone with the Default Sagittal Plane (DSP)
GD = VisualizeSubjectBone(GD);

%% Find most posterior points of the condyles (mpCPts) & plot the cutting boxes
GD = SetStartSetup(GD);

% Plot a dot into the Point of Origin
scatter3(0,0,0,'k','filled')

if ishandle(hObject); guidata(hObject,GD); end;
end