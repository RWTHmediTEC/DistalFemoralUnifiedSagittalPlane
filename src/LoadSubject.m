function GD = LoadSubject(GD)

% Move the bone to the centroid and rotate

% Check if the surface is closed
if isempty(surfedge(GD.Subject.STL.Faces))
    [~, GD.Subject.STL.Centroid, ~] = VolumeIntegrate(GD.Subject.STL.Vertices, GD.Subject.STL.Faces);
else
    GD.Subject.STL.Centroid = mean(GD.Subject.STL.Vertices)';
end
    
% Negative sign because the following inital transformation is inverse
IR = -GD.Subject.STL.InitialRot;
% Rotate around the Z Y X axis (global basis)
TFM = eulerAnglesToRotation3d(IR(1), IR(2), IR(3));
% Set Centroid of the bone as Point of Origin
TFM(1:3,4) = GD.Subject.STL.Centroid;
if GD.Verbose == 1
    disp(['Subject ' GD.Subject.Name ' loaded.']);
end

GD.Subject.STL.TFM = TFM;

GD.Subject.STL.V_C_tfm = transformPointsInverse(affine3d(TFM'), GD.Subject.STL.Vertices);

if GD.Visualization == 1
    %% Configure subplots
    figure(GD.Figure.Handle);
    set(GD.Figure.Handle, 'Name', [GD.Subject.Side ' femur of subject: ' GD.Subject.Name]);
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
    daspect([1 1 1])
    cameratoolbar('SetCoordSys','none')
    
    %% Visualize Subject Bone with the Default Sagittal Plane (DSP)
    GD = VisualizeSubjectBone(GD);
    hold on
    % Plot a dot into the Point of Origin
    scatter3(0,0,0,'k','filled')

end

%% Find most posterior points of the condyles (mpCPts) & plot the cutting boxes
GD = SetStartSetup(GD);

drawnow

end

