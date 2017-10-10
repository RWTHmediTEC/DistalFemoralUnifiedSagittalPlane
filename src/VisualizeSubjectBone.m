function GD = VisualizeSubjectBone(GD)

figure(GD.Figure.Handle); subplot(GD.Figure.LeftSpHandle);

%% Plot the bone as patch object
BoneProps.EdgeColor = 'none';
BoneProps.FaceColor = [0.882, 0.831, 0.753];
BoneProps.FaceAlpha = 0.7;
BoneProps.EdgeLighting = 'none';
BoneProps.FaceLighting = 'gouraud';
BoneProps.HandleVisibility = 'Off';
GD.Subject.PatchHandle = patch(...
    transformPoint3d(GD.Subject.Mesh, GD.Subject.STL.TFM), BoneProps);

%% Plot the Default Sagittal Plane (DSP)
PlaneProps.FaceAlpha = 0.2;
PlaneProps.EdgeColor = 'none';
PlaneProps.HandleVisibility = 'Off';
PlaneProps.FaceColor = 'k';
GD.DSPlane.Handle = drawPlane3d(createPlane([0,0,0], [0,0,1]), PlaneProps);

%% Set view to a unified camera position
set(GD.Figure.LeftSpHandle,'CameraTarget',[0, 0, 0]);
CamPos = [-0.6499, 0.4339, 0.6240] * norm(get(GD.Figure.LeftSpHandle,'CameraPosition'));
set(GD.Figure.LeftSpHandle,'CameraPosition',CamPos);
set(GD.Figure.LeftSpHandle,'CameraUpVector',[0, 1, 0]);

end