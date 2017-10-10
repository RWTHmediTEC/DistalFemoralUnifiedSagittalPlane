clearvars; close all; opengl hardware;
% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts('USP_GUI.m');
% List.f = List.f'; List.p = List.p';

%% Select subject
[fn,pn,~]=uigetfile('data\*.mat','Select mat file');
load([pn, fn]); 
 
%% Select different options by commenting 

% Default mode
% [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'Subject', Subject);
% Silent mode
[USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'Subject', Subject, 'Visualization', false, 'Verbose', true);
% The other options
% [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'PlaneVariationRange', 12, 'StepSize', 3);
% Special case: 'PlaneVariationRange', 0 -> 48 additional figures!
% [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'PlaneVariationRange', 0, 'StepSize', 3);

%% Visualization
figure('Units','pixels','Color','w','ToolBar','figure',...
'WindowScrollWheelFcn',@M_CB_Zoom,'WindowButtonDownFcn',@M_CB_RotateWithLeftMouse,...
    'renderer','opengl');
axes('Color','w'); axis on; xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
daspect([1 1 1])
cameratoolbar('SetCoordSys','none')

% Bone
BoneProps.EdgeColor = 'none';
BoneProps.FaceColor = [0.882, 0.831, 0.753];
BoneProps.FaceAlpha = 0.7;
BoneProps.EdgeLighting = 'none';
BoneProps.FaceLighting = 'gouraud';
patch('Faces',Faces,'Vertices',Vertices, BoneProps);

% PFEA
PFEA_TFM = transformLine3d(PFEA, USPTFM);
drawLine3d(PFEA_TFM,'LineWidth', 3, 'LineStyle', '-', 'Color', 'g');

% CEA
mesh.vertices=Vertices;
mesh.faces=Faces;
mesh=transformPoint3d(mesh, inv(USPTFM));
patch(mesh, BoneProps);
drawLine3d(CEA,'LineWidth', 3, 'LineStyle', '-', 'Color', 'b');

% Light
light1 = light; light('Position', -1*(get(light1,'Position')));
