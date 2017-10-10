function GD = Algorithm3(GD)
%ALGORITHM3
%    - An optimization algorithm for establishing a Unified Sagittal Plane (USP)
%   
%   REFERENCE:
%       Li et al. - Automating Analyses of the Distal Femur Articular 
%       Geometry Basedon Three-Dimensional Surface Data
%       Annals of Biomedical Engineering, Vol. 38, No. 9, September 2010 
%       pp. 2928–2936                                    
%
%   INPUT:
%       ToDo
%
%   OUTPUT:
%       ToDo
% 
%   AUTHOR: MCMF
%

visu = GD.Visualization;

if visu == 1
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
Bone = transformPoint3d(GD.Subject.Mesh, GD.Subject.STL.TFM);
Side = GD.Subject.Side;

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

% Plane variation loop counter
PV_Counter = 0;

RangeLength_a = length(Range_a);
RangeLength_b = length(Range_b);

% Variable to save the results
R.Dispersion = nan(RangeLength_a,RangeLength_b);

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
        PRM =    eulerAnglesToRotation3d(    0    , Range_b(I_b), Range_a(I_a));
        PlaneNormal = [0 0 1];
        % The inverse PRM
        invPRM = PRM';
        
        % Find most posterior points of the condyles (mpCPts) for the current plane variation 
        RotTFM = affine3d(eye(4));
        SC(1).RotTFM = RotTFM;
        SC(2).RotTFM = RotTFM;
        % Rotate the bone  corresponding to the plane variation
        tempBone = transformPoint3d(Bone, PRM);
        
        % Find the most posterior Points (mpCPts) of the rotated bone
        [mpCPts.IXmax(1), mpCPts.IXmax(2)] = FindMostPosteriorPts(tempBone.vertices);
        mpCPts.Origin_tfm_GUI = tempBone.vertices(mpCPts.IXmax,:);
        
        % Create cutting plane origins
        for s=1:2
            SC(s).Origin = mpCPts.Origin_tfm_GUI(s,:);
            for p=1:NoPpC
                % Distance between the plane origins has to be 1 mm in the direction of the plane normal
                % e.g. for NoPpC = 8 ->  mpCPt     -3.5, -2,5, -1,5, -0.5, +0.5, +1.5, +2.5, +3.5
                SC(s).PlaneOrigins(p,:) = SC(s).Origin+(-(0.5+NoPpC/2)+p)*PlaneNormal;
            end; clear p;
        end; clear s;
        
        tempContour=cell(1,2);
        for s=1:2
            % Create SC(s).NoC Saggital Contour Profiles (SC(s).P)
            tempContour{s} = IntersectMeshPlaneParfor(tempBone, SC(s).PlaneOrigins, PlaneNormal);
            for c=1:NoPpC
                % If there is more than one closed contour after the cut, use the longest one
                [~, IobC] = max(cellfun(@length, tempContour{s}{c}));
                SC(s).P(c).xyz = tempContour{s}{c}{IobC}';
                % Close contour: Copy start value to the end, if needed
                if ~isequal(SC(s).P(c).xyz(1,:),SC(s).P(c).xyz(end,:))
                    SC(s).P(c).xyz(end+1,:) = SC(s).P(c).xyz(1,:);
                end
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
                            if ishandle(ExPts.lB(2)); delete(ExPts.lB(2)); end
                            if ishandle(ExPts.lB(3)); delete(ExPts.lB(3)); end
                        end
                    case 'PZ'
                        SC(s).P(c).ExPts.B = ExPts.lB;
                        if length(ExPts.mB) > 1
                            figure(SC(s).P(c).ExPts.H)
                            if ishandle(ExPts.mB(2)); delete(ExPts.mB(2)); end
                            if ishandle(ExPts.mB(3)); delete(ExPts.mB(3)); end
                        end
                end
            end; clear c
        end; clear s
        
        
        %% Algorithm 2
        % A least-squares fitting algorithm for extracting geometric measures
        tempEll2D=cell(1,2);
        for s=1:2
            PartCont=cell(NoPpC,1);
            for c=1:NoPpC
                % Part of the contour, that is used for fitting
                PartCont{c} = SC(s).P(c).xyz(SC(s).P(c).ExPts.A:SC(s).P(c).ExPts.B,1:2)';
            end
            % Parametric least-squares fitting and analysis of cross-sectional profiles
            tempEll2D{s} = FitEllipseParfor(PartCont);
            for c=1:NoPpC
                Ell2D.z = tempEll2D{s}(1:2,c);
                Ell2D.a = tempEll2D{s}(3,c);
                Ell2D.b = tempEll2D{s}(4,c);
                Ell2D.g = tempEll2D{s}(5,c);
                
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
        PostFoci2D = inf(2*NoPpC,2);
        for s=1:2
            for c=1:NoPpC
                T_P = SC(s).P(c);
                [Foci2D, SC(s).P(c).Ell.AB] = ...
                    CalculateEllipseFoci2D(T_P.Ell.z', T_P.Ell.a, T_P.Ell.b, T_P.Ell.g);
                % Posterior Focus (pf): Foci2D(1,1:2), Anterior Focus (af): Foci2D(2,1:2)
                SC(s).P(c).Ell.pf = Foci2D(1,1:2);
                PostFoci2D(c+(s-1)*NoPpC,:) = Foci2D(1,1:2);
            end; clear c
        end; clear s
        
        % Calculate the Dispersion as Eccentricity Measure
        Dispersion = CalculateDispersion(PostFoci2D);
        % Save the dispersion together with the plane variation info
        R.Dispersion(I_a,I_b) = Dispersion;
        
        if visu == 1
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
            
            if PlotPlaneVariation == 1
                % Draw bone transformed by PRM
                patch(tempBone, GD.BoneProps)
                % Plot the mpCPts
                scatter3(mpCPts.Origin_tfm_GUI(:,1),...
                    mpCPts.Origin_tfm_GUI(:,2),mpCPts.Origin_tfm_GUI(:,3),'g','filled');
                % Plot the plane variation
                title(['\alpha = ' num2str(Range_a(I_a)) '° & ' ...
                    '\beta = '  num2str(Range_b(I_b)) '°.'])
            end
            
            if EllipsePlot == 1
                for s=1:2
                    for c=1:NoPpC
                        switch SC(s).Zone
                            case 'NZ'
                                VisualizeContEll3D(SC(s).P(c), SC(s).Color);
                            case 'PZ'
                                VisualizeContEll3D(SC(s).P(c), SC(s).Color);
                        end
                    end; clear c
                end; clear s
            end
            drawnow
        end

        % Save the calculations in one big cell array
        CutVariations{I_a,I_b} = SC;
        % Save the PRMs in one big cell array
        PRMs{I_a,I_b}=PRM;
        
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
if sum(sum(~isnan(R.Dispersion)))>=4
    if visu == 1
        %% Dispersion plot
        % A representative plot of the dispersion of focus locations
        % as a function of alpha (a) and beta (b).
        % The angles are varied in StepSize° increments within the definedrange.
        if ishandle(GD.Results.FigHandle)
            figure(GD.Results.FigHandle)
        else
            GD.Results.FigHandle = figure('Name', GD.Subject.Name, 'Color', 'w');
            GD.Results.AxHandle = axes;
            xlabel(GD.Results.AxHandle, '\alpha');
            ylabel(GD.Results.AxHandle, '\beta');
            zlabel(GD.Results.AxHandle, 'Dispersion [mm]')
            title(GD.Results.AxHandle, ...
                'Dispersion of focus locations as a function of \alpha & \beta')
            hold(GD.Results.AxHandle,'on')
            view(GD.Results.AxHandle, 3)
        end
        [Surf.X, Surf.Y] = meshgrid(Range_a, Range_b);
        Surf.X = Surf.X + GD.Results.OldDMin(1);
        Surf.Y = Surf.Y + GD.Results.OldDMin(2);
        surf(GD.Results.AxHandle, Surf.X', Surf.Y', R.Dispersion)
    end
    
    
    % Searching the cutting plane with minimum Dispersion
    [DMin.Value, minDIdx] = min(R.Dispersion(:));
    [DMin.I_a, DMin.I_b] = ind2sub(size(R.Dispersion),minDIdx);
    DMin.a = Range_a(DMin.I_a); DMin.b = Range_b(DMin.I_b);
    if GD.Verbose == 1
        display([newline ' Minimum Dispersion: ' num2str(DMin.Value) ' for ' ...
            char(945) ' = ' num2str(DMin.a) '° & ' ...
            char(946) ' = ' num2str(DMin.b) '°.' newline])
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
    
    MinSC = CutVariations{DMin.I_a,DMin.I_b};
    
    % The rotation matrix for the plane variation with minimum Dispersion
    GD.Results.PlaneRotMat = PRMs{DMin.I_a,DMin.I_b};
    
    % Calculate foci & centers in 3D for minimum Dispersion
    EllpFoc3D = inf(2*NoPpC,3);
    EllpCen3D = inf(2*NoPpC,3);
    for s=1:2
        for c=1:NoPpC
            % Save the 3D posterior Foci for the Line fit
            EllpFoc3D(c+(s-1)*NoPpC,:) = ...
                [MinSC(s).P(c).Ell.pf, MinSC(s).P(c).xyz(1,3)];
            % Save the ellipse center for the Line fit
            EllpCen3D(c+(s-1)*NoPpC,:) = ...
                [MinSC(s).P(c).Ell.z, MinSC(s).P(c).xyz(1,3)];
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
    if visu == 1
         % Results in the main figure
        % Plot the cutting plane with minimum Dispersion (Left subplot)
        figure(H.Fig);
        subplot(H.lSP); ClearPlot(H.Fig, H.lSP, {'Patch','Scatter','Line'})
        patch(transformPoint3d(Bone, GD.Results.PlaneRotMat), GD.BoneProps)
        
        % Plot the ellipses in 2D (Right subplot) for minimum Dispersion
        figure(H.Fig);
        subplot(H.rSP); cla(H.rSP);
        title(['Minimum Dispersion of the posterior Foci: ' num2str(DMin.Value) ' mm'])
        hold(H.rSP,'on')
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
        hold(H.rSP,'off')
        
        % Delete old 3D ellipses & contours, if exist
        figure(H.Fig);
        subplot(H.lSP);
        title('Line fit through the posterior Foci for minimum Dispersion')
        hold(H.lSP,'on')
        % Plot contour-parts, ellipses & foci in 3D for minimum Dispersion
        for s=1:2
            for c=1:NoPpC
                switch MinSC(s).Zone
                    case 'NZ'
                        VisualizeContEll3D(MinSC(s).P(c), MinSC(s).Color);
                    case 'PZ'
                        VisualizeContEll3D(MinSC(s).P(c), MinSC(s).Color);
                end
            end; clear c
        end; clear s
        
        % Plot foci & centers in 3D for minimum Dispersion
        scatter3(EllpFoc3D(:,1),EllpFoc3D(:,2),EllpFoc3D(:,3),'g','filled', 'tag', 'PFEA')
        scatter3(EllpCen3D(:,1),EllpCen3D(:,2),EllpCen3D(:,3),'b','filled', 'tag', 'CEA')
        
        % Plot axis through the posterior foci for minimum Dispersion
        drawLine3d(GD.Results.pFociLine, 'color','g', 'tag','PFEA');
        % Plot axis through the centers for minimum Dispersion
        drawLine3d(GD.Results.CenterLine, 'color','b', 'tag','CEA');
        
        % Enable the Save button
        if isfield(GD.Results, 'B_H_SaveResults')
            set(GD.Results.B_H_SaveResults,'Enable','on')
        end
    end
    lineToVertexIndices(GD.Results.pFociLine,Bone)
    lineToVertexIndices(GD.Results.CenterLine,Bone)
end

end