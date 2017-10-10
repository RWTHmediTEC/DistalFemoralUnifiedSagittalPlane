function GD = LoadSubject(hObject, GD)
if ishandle(hObject)
    GD = guidata(hObject);
    %% Load Subject Bone
    % Subject STL path
    GD.Subject.PathMAT = [GD.ToolPath GD.Subject.DataPath, GD.Subject.Name '.mat'];
    
    load(GD.Subject.PathMAT)
    
    % Read subject surface data and store
    GD.Subject.STL.Vertices = Vertices;
    GD.Subject.STL.Faces = Faces;
    GD.Subject.Side = Side;
    GD.Subject.STL.InitialRot = InitialRot;
    
    
    %% Set Centroid of the bone as Point of Origin
    if exist('USPTFM','var')
        % Construct a questdlg with three options
        choice = questdlg({'Data from a previous calculation was found.', 'Load data?'}, ...
            'Data from a previous calculation was found.Load data?', 'Yes', 'No', 'Yes');
        % Handle response
        switch choice
            case 'Yes'
                % If exists, use transformation from a previous calculation
                GD.Subject.STL.TFM = USPTFM;
                disp(['Subject ' GD.Subject.Name ' loaded. ' ...
                    'Data from a previous calculation is used for the initial alignment!']);
            case 'No'
                GD = initialTFM(GD);
        end
    else
        GD = initialTFM(GD);
    end
else
    GD = initialTFM(GD);
end

GD.Subject.STL.V_C_tfm = transformPointsInverse(affine3d(GD.Subject.STL.TFM'), GD.Subject.STL.Vertices);

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

if ishandle(hObject); guidata(hObject,GD); end

end

function GD = initialTFM(GD)
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
end

