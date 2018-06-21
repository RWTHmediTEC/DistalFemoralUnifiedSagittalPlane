clearvars; close all; opengl hardware;
% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts('USP_GUI.m');
% List.f = List.f'; List.p = List.p';

%% Select subject
[fn,pn,~]=uigetfile('data\*.mat','Select mat file');
load([pn, fn]); 
 
%% Select different options by commenting 

% Default mode
[USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'Subject', Subject);
% Silent mode
% [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'Subject', Subject, 'Visu', false, 'Verbose', false);
% The other options
% [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'PlaneVariationRange', 12, 'StepSize', 3);
% Special case: 'PlaneVariationRange', 0 -> 48 additional figures!
% [USPTFM, PFEA, CEA] = USP(Vertices, Faces, Side, InitialRot, 'PlaneVariationRange', 0, 'StepSize', 2);

%% Visualization
figure('Units','pixels','Color','w','ToolBar','figure',...
'WindowScrollWheelFcn',@M_CB_Zoom,'WindowButtonDownFcn',@M_CB_RotateWithMouse,...
    'renderer','opengl');
axes('Color','w'); axis on; xlabel('X [mm]'); ylabel('Y [mm]'); zlabel('Z [mm]');
daspect([1 1 1])
cameratoolbar('SetCoordSys','none')
light1 = light; light('Position', -1*(get(light1,'Position')));

% Bone
Bone.vertices=Vertices;
Bone.faces=Faces;
BoneProps.EdgeColor = 'none';
BoneProps.FaceColor = [0.882, 0.831, 0.753];
BoneProps.FaceAlpha = 0.7;
BoneProps.EdgeLighting = 'none';
BoneProps.FaceLighting = 'gouraud';
patch(Bone, BoneProps);

% PFEA
PFEA_TFM = transformLine3d(PFEA, inv(USPTFM));
drawLine3d(PFEA_TFM,'LineWidth', 3, 'LineStyle', '-', 'Color', 'g');
% lineToVertexIndices(PFEA_TFM,Bone)

% CEA
patch(transformPoint3d(Bone, USPTFM), BoneProps);
drawLine3d(CEA,'LineWidth', 3, 'LineStyle', '-', 'Color', 'b');
% lineToVertexIndices(CEA,transformPoint3d(Bone, USPTFM))

