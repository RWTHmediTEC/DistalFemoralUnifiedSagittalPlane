function GD = VisualizeSubjectBone(GD)

figure(GD.Figure.Handle); subplot(GD.Figure.LeftSpHandle);

%% Plot the bone as patch object
GD.BoneProps.EdgeColor = 'none';
GD.BoneProps.FaceColor = [0.882, 0.831, 0.753];
GD.BoneProps.FaceAlpha = 0.7;
GD.BoneProps.EdgeLighting = 'none';
GD.BoneProps.FaceLighting = 'gouraud';
GD.Subject.PatchHandle = patch(...
    transformPoint3d(GD.Subject.Mesh, GD.Subject.STL.TFM), GD.BoneProps);

%% Plot the Default Sagittal Plane (DSP)
PlaneProps.FaceAlpha = 0.2;
PlaneProps.EdgeColor = 'none';
PlaneProps.HandleVisibility = 'Off';
PlaneProps.FaceColor = 'k';
GD.DSPlane.Handle = drawPlane3d(createPlane([0,0,0], [0,0,1]), PlaneProps);

%% Set view to a unified camera position
set(GD.Figure.LeftSpHandle,'CameraTarget',[0, 0, 0]);
CamPos = [-0.65, 0.43, 0.62] * norm(get(GD.Figure.LeftSpHandle,'CameraPosition'));
set(GD.Figure.LeftSpHandle,'CameraPosition',CamPos);
set(GD.Figure.LeftSpHandle,'CameraUpVector',[0, 1, 0]);

end