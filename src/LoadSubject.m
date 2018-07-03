function GD = LoadSubject(hObject, GD)
if ishandle(hObject)
    GD = guidata(hObject);
    %% Load Subject Bone
    % Subject STL path
    GD.Subject.PathMAT = [GD.ToolPath GD.Subject.DataPath, GD.Subject.Name '.mat'];
    
    load(GD.Subject.PathMAT)
    
    % Read subject surface data and store
    GD.Subject.Mesh.vertices = Vertices;
    GD.Subject.Mesh.faces = Faces;
    GD.Subject.Side = Side;
    GD.Subject.InitialRot = InitialRot;
    
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
                disp('Data from a previous calculation is used for the initial alignment!');
            case 'No'
                GD = initialTFM(GD);
        end
    else
        GD = initialTFM(GD);
    end
else
    GD = initialTFM(GD);
end

if GD.Visualization == 1
    %% Configure subplots
    set(GD.Figure.Handle, 'Name', [GD.Subject.Side ' femur of subject: ' GD.Subject.Name]);
    % Clear right subplot
    rSP=GD.Figure.RightSpHandle;
    cla(rSP, 'reset');
    axis(rSP,'on','equal');
    grid(rSP,'on');
    xlabel(rSP,'X [mm]'); ylabel(rSP,'Y [mm]');
    set(rSP, 'Color', GD.Figure.Color);
    
    % Left subject subplot and properties
    lSP=GD.Figure.LeftSpHandle;
    cla(lSP,'reset');
    axis(lSP,'on','equal');
    xlabel(lSP,'X [mm]'); ylabel(lSP,'Y [mm]'); zlabel(lSP,'Z [mm]');
    set(lSP,'Color',GD.Figure.Color);
    light1 = light(lSP); light(lSP, 'Position', -1*(get(light1,'Position')));
    daspect(lSP, [1 1 1])
    cameratoolbar('SetCoordSys','none')
    
    %% Visualize Subject Bone with the Default Sagittal Plane (DSP)
    GD = VisualizeSubjectBone(GD);
    hold(lSP,'on')
    % Plot a dot into the Point of Origin
    scatter3(lSP, 0,0,0,'k','filled')
end

%% Find most posterior points of the condyles (mpCPts) & plot the cutting boxes
GD = SetStartSetup(GD);

if GD.Verbose == 1
    disp(['Subject ' GD.Subject.Name ' loaded.']);
end

if ishandle(hObject); guidata(hObject,GD); end

end

function GD = initialTFM(GD)
% Move the bone to the specified center or to its centroid and rotate
TRANS = createTranslation3d(-GD.Subject.Center);
% Negative sign because the following inital transformation is inverse
IR = GD.Subject.InitialRot;
% Rotate around the Z Y X axis (global basis)
ROT = eulerAnglesToRotation3d(IR(1), IR(2), IR(3));
GD.Subject.STL.TFM = ROT*TRANS;
end

