function GD = Algorithm3(GD)

if GD.Visualization == 1
    % Figure & subplot handles
    H.Fig = GD.Figure.Handle;
    H.lSP = GD.Figure.LeftSpHandle;
    H.rSP = GD.Figure.RightSpHandle;
    
    % Clear subplots
    % Right
    figure(H.Fig); subplot(H.rSP); title(''); cla
    % Left
    figure(H.Fig); subplot(H.lSP); title(''); ClearPlot(H.Fig, H.lSP, {'Patch','Scatter','Line'})
end

%% Settings
% Algorithm 3 - Part 1
% The angles are varied in StepSize°increments within following range:
PVR = GD.Algorithm3.PlaneVariationRange;
StepSize = GD.Algorithm3.StepSize;

Range_a = -PVR:StepSize:PVR;
Range_b = -PVR:StepSize:PVR;

% Plot Plane Variation
PlotPlaneVariation = GD.Algorithm3.PlaneVariaton;

% Algorithm 1
% Plot the contours with extremity point detection: 
% 1: 16 Contour Figures per plane variation
% (CSS Image, Curvature can be plotted, too. See end of Algorithm1.m)
PlotContours = GD.Algorithm1.PlotContours;
% Sigma: For explanation see the functions: Algorithm1.m & BOMultiScaleCurvature2D_adapted.m
sigma = 4; sigmastart = 1; sigmadelta = 1;

% Algorithm 2
% -

% Algorithm 3 - Part 2
% Plot Ellipses & Foci for each plane variation into the GUI figure
EllipsePlot = GD.Algorithm3.EllipsePlot;

%% START OF THE FRAMEWORK BY LI -------------------------------------------
% Algorithm 3 - Part 1
% An optimization algorithm for establishing a Unified Sagittal Plane (USP)

% Bone Surface
Bone.vertices = GD.Subject.STL.V_C_tfm;
Bone.faces    = GD.Subject.STL.Faces;
Side          = GD.Subject.Side;

% Number of Planes per Cutting Box
NoPpC = GD.Cond.NoPpC;

% Sagittal Cuts (SC)
% RIGHT knee: medial - neg. Z values (NZ), lateral - pos. Z values (PZ)
%  LEFT knee: medial - pos. Z values (PZ), lateral - neg. Z values (NZ)
switch Side
    case 'Right'
        SC(1).Zone = 'NZ';
        SC(2).Zone = 'PZ';
        SC(1).Color = [255,   0, 255]/255; % Medial = Magenta
        SC(2).Color = [255, 255, 102]/255; %Lateral = Lemon
    case 'Left'
        SC(1).Zone='PZ';
        SC(2).Zone='NZ';
        SC(1).Color = [255, 255, 102]/255; %Lateral = Lemon
        SC(2).Color = [255,   0, 255]/255; % Medial = Magenta
end

% Variable to save the results
Results = [];

% Plane variation loop counter
PV_Counter = 0;

RangeLength_a = length(Range_a);
RangeLength_b = length(Range_b);

% Cell array to save the results of each plane variation
CutVariations = cell(RangeLength_a,RangeLength_b);

if GD.Verbose == 1
    % Start updated command window information
    dispstat('','init');
    dispstat('Initializing the iteration process...','keepthis','timestamp');
end

for I_a = 1:RangeLength_a
    for I_b = 1:RangeLength_b
        
        % Systematic Variation of Cutting Plane Orientation
        
        % (Abdu.) (Addu.)                       | 
        % Lateral  Medial Rotation   Angle      | Intern  Extern Rotation    Angle
        %     +       -    X-Axis  Range_a(I_a) |  -        +     Y-Axis  Range_b(I_b)
        
        % Calculate the Rotation Matrix for the plane variation
        % (All rotations around the fixed axes / around the global basis) 
        %                                       (  Z-Axis      Y-Axis        X-Axis   )
        PlaneRotMat =    eulerAnglesToRotation3d(    0    , Range_b(I_b), Range_a(I_a));
        PlaneNormal = [0, 0, 1]*PlaneRotMat(1:3,1:3)';
        
        % Find most posterior points of the condyles (mpCPts) for the current plane variation 
        RotTFM = affine3d(PlaneRotMat);
        SC(1).RotTFM = RotTFM;
        SC(2).RotTFM = RotTFM;
        % Rotate the bone vertices corresponding to the plane variation
        TempVertices = transformPointsForward(RotTFM, Bone.vertices);
        % Find the most posterior Points (mpCPts) of the rotated bone
        [mpCPts.IXmax(1), mpCPts.IXmax(2)] = FindMostPosteriorPts(TempVertices);
        % Rotate the mpCPts back into the reference system of the bone.
        mpCPts.Origin_tfm_GUI = transformPointsInverse(RotTFM, TempVertices(mpCPts.IXmax,:));
        
        % Create cutting plane origins
        for s=1:2
            SC(s).Origin = mpCPts.Origin_tfm_GUI(s,:);
            for p=1:NoPpC
                % Distance between the plane origins has to be 1 mm in the direction of the plane normal
                % e.g. for NoPpC = 8 ->  mpCPt     -3.5, -2,5, -1,5, -0.5, +0.5, +1.5, +2.5, +3.5
                SC(s).PlaneOrigins(p,:) = SC(s).Origin+(-(0.5+NoPpC/2)+p)*PlaneNormal;
            end; clear p;
        end; clear s;
        

        for s=1:2
            % Create SC(s).NoC Saggital Contour Profiles (SC(s).P)
            T_Contour{s} = IntersectMeshPlaneParfor(Bone, SC(s).PlaneOrigins, PlaneNormal);
            for c=1:NoPpC
                % If there is more than one closed contour after the cut, use the longest one
                [~, IobC] = max(cellfun(@length, T_Contour{s}{c}));
                SC(s).P(c).xyz = T_Contour{s}{c}{IobC}';
                % Close contour: Copy start value to the end, if needed
                if ~isequal(SC(s).P(c).xyz(1,:),SC(s).P(c).xyz(end,:))
                    SC(s).P(c).xyz(end+1,:) = SC(s).P(c).xyz(1,:);
                end
                % Rotation back, parallel to X-Y-Plane (Default Sagittal Plane)
                SC(s).P(c).xyz = transformPointsForward(SC(s).RotTFM, SC(s).P(c).xyz);
                % If the contour is sorted clockwise
                if varea(SC(s).P(c).xyz(:,1:2)') < 0 % The contour has to be closed
                    % Sort the contour counter-clockwise
                    SC(s).P(c).xyz = flipud(SC(s).P(c).xyz);
                    SC(s).P(c).xyz(end,:) = [];
                    SC(s).P(c).xyz = circshift(SC(s).P(c).xyz, [-1,0]);
                else
                    SC(s).P(c).xyz(end,:) = [];
                end
                [~, IYMax] = max(SC(s).P(c).xyz(:,2));
                % Set the start of the contour to the maximum Y value
                if IYMax ~= 1
                    SC(s).P(c).xyz = SC(s).P(c).xyz([IYMax:size(SC(s).P(c).xyz,1),1:IYMax-1],:);
                end
                % Close contour: Copy start value to the end, if needed
                if ~isequal(SC(s).P(c).xyz(1,:),SC(s).P(c).xyz(end,:))
                    SC(s).P(c).xyz(end+1,:) = SC(s).P(c).xyz(1,:);
                end
            end; clear c;
        end; clear s;
        
        
        %% Algorithm 1
        % A pattern-recognition algorithm for identifying the articulating surface
        
        % Identifying the articulating portion from condyle cross-sectional profiles
        for s=1:2
            for c=1:NoPpC
                % Only the X & Y values are needed
                Contour = SC(s).P(c).xyz(:,1:2);
                % Get the anterior and posterior extremity points of the articulating surface
                [ExPts.A, ExPts.mB, ExPts.lB, A1FigHandle] = ...
                    Algorithm1(Contour, sigmastart, sigmadelta, sigma, PlotContours);
                SC(s).P(c).ExPts.H = A1FigHandle;
                SC(s).P(c).ExPts.A = ExPts.A;
                switch SC(s).Zone
                    case 'NZ'
                        SC(s).P(c).ExPts.B = ExPts.mB;
                        if length(ExPts.lB) > 1
                            figure(SC(s).P(c).ExPts.H)
                            delete(ExPts.lB(2),ExPts.lB(3))
                        end
                    case 'PZ'
                        SC(s).P(c).ExPts.B = ExPts.lB;
                        if length(ExPts.mB) > 1
                            figure(SC(s).P(c).ExPts.H)
                            delete(ExPts.mB(2),ExPts.mB(3))
                        end
                end
            end; clear c
        end; clear s
        
        
        %% Algorithm 2
        % A least-squares fitting algorithm for extracting geometric measures
        % TEST
        for s=1:2
            for c=1:NoPpC
                % Part of the contour, that is used for fitting
                PartCont{c} = SC(s).P(c).xyz(SC(s).P(c).ExPts.A:SC(s).P(c).ExPts.B,1:2)';
            end
            % Parametric least-squares fitting and analysis of cross-sectional profiles
            T_Ell2D{s} = FitEllipseParfor(PartCont);
            for c=1:NoPpC
                Ell2D.z = T_Ell2D{s}(1:2,c);
                Ell2D.a = T_Ell2D{s}(3,c);
                Ell2D.b = T_Ell2D{s}(4,c);
                Ell2D.g = T_Ell2D{s}(5,c);
                
                SC(s).P(c).Ell.z = Ell2D.z';
                % Unify the orientation of the ellipses
                if Ell2D.a >= Ell2D.b
                    SC(s).P(c).Ell.a = Ell2D.a;
                    SC(s).P(c).Ell.b = Ell2D.b;
                    SC(s).P(c).Ell.g = Ell2D.g;
                elseif Ell2D.a < Ell2D.b
                    SC(s).P(c).Ell.a = Ell2D.b;
                    SC(s).P(c).Ell.b = Ell2D.a;
                    SC(s).P(c).Ell.g = Ell2D.g+pi/2;
                end
                % If a contour figure exists, plot the ellipse
                if ~isempty(SC(s).P(c).ExPts.H)
                    figure(SC(s).P(c).ExPts.H)
                    plotellipse(Ell2D.z, Ell2D.a, Ell2D.b, Ell2D.g)
                end
            end; clear c
        end; clear s 
        
        
        %% Algorithm 3 - Part 2
        % An optimization algorithm for establishing the unified sagittal plane
        
        % Calculate the ellipse foci (Foci2D) and the major (A) & minor (B) axis points (AB)
        PostFoci2D = [];
        for s=1:2
            for c=1:NoPpC
                T_P = SC(s).P(c);
                [Foci2D, SC(s).P(c).Ell.AB] = ...
                    CalculateEllipseFoci2D(T_P.Ell.z', T_P.Ell.a, T_P.Ell.b, T_P.Ell.g);
                % Posterior Focus (pf): Foci2D(1,1:2), Anterior Focus (af): Foci2D(2,1:2)
                SC(s).P(c).Ell.pf = Foci2D(1,1:2);
                PostFoci2D(end+1,:) = Foci2D(1,1:2);
            end; clear c
        end; clear s
        
        % Calculate the Dispersion as Eccentricity Measure
        Dispersion = CalculateDispersion(PostFoci2D);
        % Save the dispersion together with the plane variation info
        Results(end+1,1) = Range_a(I_a);
        Results(end,2)   = Range_b(I_b);
        Results(end,3)   = Dispersion;
        Results(end,4)   = I_a;
        Results(end,5)   = I_b;
        
        if GD.Visualization == 1
            %% Visualization during Iteration
            % RIGHT subplot: Plot the ellipses in 2D in the XY-plane
            if EllipsePlot == 1
                % Clear right subplot
                figure(H.Fig); subplot(H.rSP); cla;
                hold on;
                % Plot the ellipses in 2D
                for s=1:2
                    for c=1:NoPpC
                        switch SC(s).Zone
                            case 'NZ'
                                VisualizeEll2D(SC(s).P(c), SC(s).Color);
                            case 'PZ'
                                VisualizeEll2D(SC(s).P(c), SC(s).Color);
                        end
                    end; clear c
                end; clear s
                hold off
            end
            
            % LEFT Subplot: Plot most posterior Points (mpCPts), plane
            % variation, contour-parts, ellipses in 3D
            
            figure(H.Fig); subplot(H.lSP);
            ClearPlot(H.Fig, H.lSP, {'Patch','Scatter','Line'})
            
            % Plot the mpCPts
            if PlotPlaneVariation == 1
                scatter3(mpCPts.Origin_tfm_GUI(:,1),...
                    mpCPts.Origin_tfm_GUI(:,2),mpCPts.Origin_tfm_GUI(:,3),'g','filled');
            end
            
            % Plot the plane variation
            if PlotPlaneVariation == 1
                title(['\alpha = ' num2str(Range_a(I_a)) '° & ' ...
                    '\beta = '  num2str(Range_b(I_b)) '°.'])
                drawPlane3d(createPlane([0, 0, 0], PlaneNormal),'g','FaceAlpha', 0.5);
            end
            
            if EllipsePlot == 1
                for s=1:2
                    for c=1:NoPpC
                        switch SC(s).Zone
                            case 'NZ'
                                VisualizeContEll3D(SC(s).P(c), SC(s).RotTFM, SC(s).Color);
                            case 'PZ'
                                VisualizeContEll3D(SC(s).P(c), SC(s).RotTFM, SC(s).Color);
                        end
                    end; clear c
                end; clear s
            end
            drawnow
        end

        % Save the calculations in one big cell array
        CutVariations{I_a,I_b} = SC;
        
        PV_Counter=PV_Counter+1;
        
        if GD.Verbose == 1
            dispstat(['Plane variation ' num2str(PV_Counter) ' of ' ...
                num2str(RangeLength_a*RangeLength_b) '. '...
                char(945) ' = ' num2str(Range_a(I_a)) '° & '...
                char(946) ' = ' num2str(Range_b(I_b)) '°.'],'timestamp');
        end
    end; clear I_b
end; clear I_a
clear SC

if GD.Verbose == 1
    % Stop updated command window information
    dispstat('','keepprev');
end


%% Results
if size(Results,1) > 3
    if GD.Visualization == 1
        %% Dispersion plot
        % A representative plot of the dispersion of focus locations
        % as a function of alpha (a) and beta (b).
        % The angles are varied in StepSize° increments within the definedrange.
        if ishandle(GD.Results.FigHandle)
            figure(GD.Results.FigHandle)
            hold on
        else
            GD.Results.FigHandle = figure('Name', GD.Subject.Name, 'Color', 'w');
        end
        
        Surf.x = Results(:,1) + GD.Results.OldDMin(1);
        Surf.y = Results(:,2) + GD.Results.OldDMin(2);
        Surf.z = Results(:,3);
        trisurf(delaunay(Surf.x,Surf.y), Surf.x, Surf.y, Surf.z);
        xlabel('\alpha');ylabel('\beta');zlabel('Dispersion [mm]')
        title('Dispersion of focus locations as a function of \alpha & \beta')
    end
    
    
    % Searching the cutting plane with minimum Dispersion
    [DMin.Value, DMin.I] = min(Results(:,3));
    DMin.a = Results(DMin.I, 1); DMin.b = Results(DMin.I, 2);
    if GD.Verbose == 1
        display([char(10) ' Minimum Dispersion: ' num2str(DMin.Value) ' for ' ...
            char(945) ' = ' num2str(DMin.a) '° & ' ...
            char(946) ' = ' num2str(DMin.b) '°.' char(10)])
    end
    
    GD.Results.OldDMin(1) = GD.Results.OldDMin(1)+DMin.a;
    GD.Results.OldDMin(2) = GD.Results.OldDMin(2)+DMin.b;
    
    % Stop the Rough Iteration if the minimum dispersion lies inside the
    % search space and not on the borders.
    if DMin.a == -PVR || DMin.a == PVR || DMin.b == -PVR || DMin.b == PVR
        GD.Iteration.Rough = 1;
    else
        GD.Iteration.Rough = 0;
    end
    
    DMin.I_a = Results(DMin.I, 4);DMin.I_b = Results(DMin.I, 5);
    MinSC = CutVariations{DMin.I_a,DMin.I_b};
    
    % The rotation matrix for the plane variation with minimum Dispersion
    GD.Results.PlaneRotMat = MinSC(1).RotTFM.T;
    
    % Calculate foci & centers in 3D for minimum Dispersion
    EllpFoc3D = [];
    EllpCen3D = [];
    for s=1:2
        for c=1:NoPpC
            % Save the 3D posterior Foci for the Line fit
            EllpFoc3D(end+1,:) = CalculatePointInEllipseIn3D(...
                MinSC(s).P(c).Ell.pf, MinSC(s).P(c).xyz(1,3), MinSC(s).RotTFM);
            % Save the ellipse center for the Line fit
            EllpCen3D(end+1,:) = CalculatePointInEllipseIn3D(...
                MinSC(s).P(c).Ell.z, MinSC(s).P(c).xyz(1,3), MinSC(s).RotTFM);
        end; clear c
    end; clear s
    
    % Calculate axis through the posterior foci
    GD.Results.pFociLine  = fitLine3d(EllpFoc3D);
    GD.Results.CenterLine = fitLine3d(EllpCen3D);
    
    % Display info about the ellipses in the command window
    EllResults = CalcAndPrintEllipseResults(MinSC, NoPpC, GD.Verbose);
    GD.Results.Ell.Med.a = EllResults(1,:);
    GD.Results.Ell.Med.b = EllResults(3,:);
    GD.Results.Ell.Lat.a = EllResults(2,:);
    GD.Results.Ell.Lat.b = EllResults(4,:);
    
    %% Visualization of Results
    if GD.Visualization == 1
         % Results in the main figure
        % Plot the cutting plane with minimum Dispersion (Left subplot)
        figure(H.Fig); subplot(H.lSP); ClearPlot(H.Fig, H.lSP, {'Patch','Scatter','Line'})
        PlaneNormal = [0, 0, 1]*GD.Results.PlaneRotMat(1:3,1:3)';
        drawPlane3d(createPlane([0, 0, 0], PlaneNormal),'w','FaceAlpha', 0.5);
        
        % Plot the ellipses in 2D (Right subplot) for minimum Dispersion
        figure(H.Fig); subplot(H.rSP); cla;
        title(['Minimum Dispersion of the posterior Foci: ' num2str(DMin.Value) ' mm'])
        hold on;
        % Plot the ellipses in 2D
        for s=1:2
            for c=1:NoPpC
                switch MinSC(s).Zone
                    case 'NZ'
                        VisualizeEll2D(MinSC(s).P(c), MinSC(s).Color);
                    case 'PZ'
                        VisualizeEll2D(MinSC(s).P(c), MinSC(s).Color);
                end
            end; clear c
        end; clear s
        hold off
        
        % Delete old 3D ellipses & contours, if exist
        figure(H.Fig); subplot(H.lSP);
        title('Line fit through the posterior Foci for minimum Dispersion')
        hold on
        % Plot contour-parts, ellipses & foci in 3D for minimum Dispersion
        for s=1:2
            for c=1:NoPpC
                switch MinSC(s).Zone
                    case 'NZ'
                        VisualizeContEll3D(MinSC(s).P(c), MinSC(s).RotTFM, MinSC(s).Color);
                    case 'PZ'
                        VisualizeContEll3D(MinSC(s).P(c), MinSC(s).RotTFM, MinSC(s).Color);
                end
            end; clear c
        end; clear s
        
        % Plot foci & centers in 3D for minimum Dispersion
        scatter3(EllpFoc3D(:,1),EllpFoc3D(:,2),EllpFoc3D(:,3),'g','filled')
        scatter3(EllpCen3D(:,1),EllpCen3D(:,2),EllpCen3D(:,3),'b','filled')
        
        % Plot axis through the posterior foci for minimum Dispersion
        drawLine3d(GD.Results.pFociLine,'g');
        % Plot axis through the centers for minimum Dispersion
        drawLine3d(GD.Results.CenterLine,'b');
        
        % Enable the Save button
        if isfield(GD.Results, 'B_H_SaveResults')
            set(GD.Results.B_H_SaveResults,'Enable','on')
        end
    end
end

end