function GD = RoughFineIteration(hObject, GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

if ishandle(hObject)
    GD = guidata(hObject);
    % Clear convergence plot
    ClearPlot(GD.Figure.DispersionHandle, {'Surf'})
    GD.Figure.DispersionHandle.Visible = 'off';
end

% Variable to save the rotation values during the rough iterations
GD.Iteration.OldDMin(1) = 0; GD.Iteration.OldDMin(2) = 0;

% If the PlaneVariationRange is below 0, do not start the iteration process
% and only execute Algorithm 3 once.
if GD.Algorithm3.PlaneVariationRange >= 1
    %% Rough Iteration
    if GD.Verbose
        disp('----- Starting Rough Iteration -----------------------------------');
    end
    GD.Iteration.Rough = 1;
    % Execute the Rough Iteration until the minimum dispersion lies inside 
    % the search space and not on the borders.
    while GD.Iteration.Rough == 1
        GD = Algorithm3(GD);
        GD.Subject.TFM = GD.Results.PlaneRotMat*GD.Subject.TFM;
        if GD.Visualization
            title(GD.Figure.D3Handle, '');
            delete(GD.Figure.MeshHandle);
            % Plot bone with newest transformation
            GD = VisualizeSubjectBone(GD);
            drawnow;
        end
    end
    if GD.Verbose
        disp('----- Finished Rough Iteration -----------------------------------');
        disp(' ');
    end
    
    %% Fine Iteration
    if GD.Verbose
        disp('----- Starting Fine Iteration ------------------------------------');
    end
    % Save the GUI values of Plane Variation Range & Step Size
    OldPVRange  = GD.Algorithm3.PlaneVariationRange;
    OldStepSize = GD.Algorithm3.StepSize;
    
    % The new Step Size for the Fine Iteration
    FineStepSize = 0.5;
    if GD.Algorithm3.StepSize >= 1
        % The new Plane Variation Range is the Step Size of the Rough 
        % Iteration minus the fine Step Size
        GD.Algorithm3.PlaneVariationRange = GD.Algorithm3.StepSize - FineStepSize;
    else
        % Minimal Plane Variation Range is the fine Step Size.
        GD.Algorithm3.PlaneVariationRange = FineStepSize;
    end
    GD.Algorithm3.StepSize = FineStepSize;
    GD = Algorithm3(GD);
    % Calculate the transformation (USPTFM) from the initial bone position into the USP
    PRM = GD.Results.PlaneRotMat;
    GD.Results.USPTFM  = PRM*GD.Subject.TFM;
    % Calculate the axes (PFEA & CEA) in the USP system
    GD.Results.PFEA = transformLine3d(GD.Results.pFociLine, PRM);
    GD.Results.CEA = transformLine3d(GD.Results.CenterLine, PRM);
    % Sanity check
    PFEA_Idx = lineToVertexIndices(transformLine3d(...
        GD.Results.PFEA, inv(GD.Results.USPTFM)), GD.Subject.Mesh);
    assert(isequal(GD.Results.pFociLineIdx, PFEA_Idx))
    CEA_Idx = lineToVertexIndices(transformLine3d(...
        GD.Results.CEA, inv(GD.Results.USPTFM)), GD.Subject.Mesh);
    assert(isequal(GD.Results.CenterLineIdx, CEA_Idx))
    
    if GD.Verbose
        disp('----- Finished Fine Iteration ------------------------------------');
        disp(' ');
    end
    
    % Set Plane Variation Range & Step Size to the old GUI values
    GD.Algorithm3.PlaneVariationRange = OldPVRange;
    GD.Algorithm3.StepSize = OldStepSize;
    
else
    GD = Algorithm3(GD);
end

if ishandle(hObject); guidata(hObject,GD); end

end
