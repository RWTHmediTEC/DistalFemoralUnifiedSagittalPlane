function GD = VisualizeSubjectBone(GD)

lSP = GD.Figure.LeftSpHandle;

%% Plot the bone as patch object
GD.BoneProps.EdgeColor = 'none';
GD.BoneProps.FaceColor = [0.882, 0.831, 0.753];
GD.BoneProps.FaceAlpha = 0.7;
GD.BoneProps.EdgeLighting = 'none';
GD.BoneProps.FaceLighting = 'gouraud';
GD.Subject.PatchHandle = patch(lSP, ...
    transformPoint3d(GD.Subject.Mesh, GD.Subject.STL.TFM), GD.BoneProps);

%% Plot the Default Sagittal Plane (DSP)
planeProps.FaceAlpha = 0.2;
planeProps.EdgeColor = 'none';
planeProps.HandleVisibility = 'Off';
planeProps.FaceColor = 'k';
GD.DSPlane.Handle = drawPlane3d(lSP, createPlane([0,0,0], [0,0,1]), planeProps);

%% Set view to a unified camera position
set(lSP,'CameraTarget',[0, 0, 0]);
CamPos=[-0.65, 0.43, 0.62]*norm(get(lSP,'CameraPosition'));
set(lSP,'CameraPosition',CamPos);
set(lSP,'CameraUpVector',[0, 1, 0]);

end