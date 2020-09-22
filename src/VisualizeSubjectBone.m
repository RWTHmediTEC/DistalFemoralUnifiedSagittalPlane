function GD = VisualizeSubjectBone(GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

H3D = GD.Figure.D3Handle;

% Delete old XY-plane if exists
if isfield(GD, 'PlaneHandle') && ishandle(GD.PlaneHandle)
        delete(GD.PlaneHandle)
end

%% Plot the bone as patch object
GD.BoneProps.EdgeColor = 'none';
GD.BoneProps.FaceColor = [0.882, 0.831, 0.753];
GD.BoneProps.FaceAlpha = 0.7;
GD.BoneProps.EdgeLighting = 'none';
GD.BoneProps.FaceLighting = 'gouraud';
GD.Subject.PatchHandle = patch(H3D, ...
    transformPoint3d(GD.Subject.Mesh, GD.Subject.STL.TFM), GD.BoneProps);

%% Plot the Default Sagittal Plane (DSP)
planeProps.FaceAlpha = 0.2;
planeProps.EdgeColor = 'none';
planeProps.HandleVisibility = 'Off';
planeProps.FaceColor = 'k';
GD.PlaneHandle = drawPlane3d(H3D, createPlane([0,0,0], [0,0,1]), planeProps);

%% Set view to a unified camera position
view(H3D,3)
set(H3D,'CameraUpVector',[0, 1, 0]);
% set(lSP,'CameraTarget',[0, 0, 0]);
CamPos=[-450 350 450];
set(H3D,'CameraPosition',CamPos);

end