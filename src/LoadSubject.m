function GD = LoadSubject(hObject, GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

if ishandle(hObject)
    GD = guidata(hObject);
    %% Load Subject Bone
    % Subject STL path
    GD.Subject.PathMAT = [GD.ToolPath GD.Subject.DataPath, GD.Subject.Name '.mat'];
    
    load(GD.Subject.PathMAT)
    
    % Read subject surface data and store
    GD.Subject.Mesh.vertices = Vertices;
    GD.Subject.Mesh.faces = Faces;
    GD.Subject.Center = mean(Vertices);
    GD.Subject.Side = upper(Side(1)); %#ok<NODEF>
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
    switch GD.Subject.Side; case 'R'; Side = 'Right'; case 'L'; Side = 'Left'; end
    set(GD.Figure.Handle, 'Name', [Side ' femur of subject: ' GD.Subject.Name]);
    % Clear right subplot
    H2D = GD.Figure.D2Handle;
    cla(H2D, 'reset');
    axis(H2D,'on','equal');
    grid(H2D,'on');
    xlabel(H2D,'X [mm]'); ylabel(H2D,'Y [mm]');
    set(H2D, 'Color', GD.Figure.Color);
    
    % 3D subject plot and properties
    H3D = GD.Figure.D3Handle;
    cla(H3D,'reset');
    axis(H3D,'on','equal');
    xlabel(H3D,'X [mm]'); ylabel(H3D,'Y [mm]'); zlabel(H3D,'Z [mm]');
    set(H3D,'Color',GD.Figure.Color);
    light1 = light(H3D); light(H3D, 'Position', -1*(get(light1,'Position')));
    daspect(H3D, [1 1 1])
    cameratoolbar('SetCoordSys','none')
    
    %% Visualize Subject Bone with the Default Sagittal Plane (DSP)
    GD = VisualizeSubjectBone(GD);
    hold(H3D,'on')
    % Plot a dot into the Point of Origin
    scatter3(H3D, 0,0,0,'k','filled')
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

