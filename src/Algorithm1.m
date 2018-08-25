function [pExA, amExB, alExB, axH_C] = Algorithm1(Contour, sigmastart, sigmadelta, sigma, vis)
%ALGORITHM1
%    - A Pattern-Recognition Algorithm for Identifying the Articulating Surface
%
%   REFERENCE:
%       Li et al. - Automating Analyses of the Distal Femur Articular
%       Geometry Basedon Three-Dimensional Surface Data
%       Annals of Biomedical Engineering, Vol. 38, No. 9, September 2010
%       pp. 2928–2936
%
%   INPUT:
%       Contour    - nx2 double: X- & Y-coordinates of the contour
%                      	Requirements: - Sorting: counter-clockwise,
%                                     - Start point: Max Y-value
%       sigmastart - Starting sigma value (see BOMultiScaleCurvature2D_adapted)
%       sigmadelta - Delta value of sigma (see BOMultiScaleCurvature2D_adapted)
%       sigma      - Sigma, that is used to detect the local maxima
%       vis        - visualization options:
%                               - 0: Plot nothing
%                               - 1: Plot contour
%
%   OUTPUT:
%       pExA       - integer: posterior extremity A
%       amExB(1)   - integer: anterior medial extremity B
%       amExB(2)   - scatter handle of amExB(1)
%       amExB(3)   - text handle of amExB(1)
%       alExB(1)   - integer: anterior lateral extremity B
%       alExB(2)   - scatter handle of alExB(1)
%       alExB(3)   - text handle of alExB(1)
%       axH_C      - axes handle: nan if vis == 0
%
%   AUTHOR: MCMF
%

% Boundaries of the contour
[XMin, IXMin] = min(Contour(:,1));
[XMax, IXMax] = max(Contour(:,1));
[YMin, IYMin] = min(Contour(:,2));
[YMax, IYMax] = max(Contour(:,2));

% IYMax should always be 1, because the contour should start there
if IYMax ~=1
    warning('Contour should start at the max. Y value (YMax): Algorithm1 won''t work!')
end

% Calculate the multi-scale curvature & the curvature scale-space image
try
    [K,S,~,~,Xsm,Ysm,zcp] = BOMultiScaleCurvature2D_adapted(Contour,sigmastart,sigmadelta);
catch
    % In the very rare case that the countour is almost a circle:
    [pExA, amExB, alExB, axH_C] = circleCornerCase(Contour, IYMax, vis);
    return
end

%% Find the posterior extremity A (pExA)
% To find the curvature zerocrossing point of pExA:
% Find the sigma that meets the following condition:
% Only 2 zero crossings lie between IYMax and IXMin of the contour
sigma_pExA = 1;
for z=1:length(zcp(1:end-1))
    if sum(zcp{z}>IYMax & zcp{z}<IXMin) > 2
        sigma_pExA = z+1;
    end
end
zero_pExA = max(zcp{sigma_pExA}(zcp{sigma_pExA}>IYMax & zcp{sigma_pExA}<IXMin));
% If no zero crossing is found set IYMax as crossing point
if isempty(zero_pExA)
    zero_pExA = IYMax;
end

% Which Gaussian of width (sigma) should be used to find the local maxima
if sigma == 0
    sigma = sigma_pExA;
elseif sigma > length(zcp)
    sigma = length(zcp);
end
[~, Local_Maxima_Indcs] = findpeaks(K{sigma});

% Find the posterior extremity A (pExA) defined as:
% - local maximum curvature point inferior to the curvature zerocrossing point (zero_pExA)
pExA_Candidates = Local_Maxima_Indcs(Local_Maxima_Indcs>zero_pExA & Local_Maxima_Indcs<IXMin);
% If no candiates are found set IYMax as pExA
if isempty(pExA_Candidates)
    pExA = IYMax;
else
    pExA  = pExA_Candidates(1);
end

%% Anterior extremities B (medial & lateral)
% Find the anterior medial extremity B (amExB) defined as:
% - the local maximum curvature point with the largest curvature value in
%   the region between the most anterior point and the most inferior point of the contour;
[~, amExB] = max(K{sigma}(IYMin:IXMax));
amExB = IYMin-1+amExB;

% Find the anterior lateral extremity B (alExB) defined as:
% - local maximum curvature point closest to the most anterior point of the contour.
alExB = Local_Maxima_Indcs(knnsearch(Local_Maxima_Indcs, IXMax));


%% Visualization
axH_C = nan;
if vis == 1 || vis == 2
    %% Plot: Contour
    figH_C = figure('name','Contour', 'color','w');
    axH_C = axes(figH_C);
    title(axH_C, 'Contour');
    plot(axH_C, Contour(:,1),Contour(:,2),'k-','LineWidth',2);
    hold(axH_C,'on');
    for i=1:length(zcp)
        Xs = Xsm{i};
        Ys = Ysm{i};
        zc = zcp{i};
        sch(1) = plot(axH_C, Xs,Ys,'r-');
        hold(axH_C,'on');
        sch(2) = plot(axH_C, Xs(zc),Ys(zc),'go');
        % pause(0)
        delete(sch);
    end
    
    % Visualization of the Running direction: Arrow -> at YMax
    % Should be counter-clockwise
    quiver(axH_C, ...
        Contour(1,1),Contour(1,2),...
        Contour(6,1)-Contour(1,1),Contour(6,2)-Contour(1,2),...
        'g','LineWidth',3,'AutoScale','off','MaxHeadSize',30);
    scatter(axH_C, Contour(zero_pExA,1),Contour(zero_pExA,2), 'filled');
    text(axH_C, Contour(zero_pExA,1),Contour(zero_pExA,2), 'Zerocrossing point',...
        'VerticalAlignment','bottom');
    
    %% Normals of the contour
    % Get the normals (already normed)
    [~, Normals, ~, ~, ~] = frenet(Contour(:,1),Contour(:,2));
    Normals = Normals(:,1:2);
    % Unify normals: All normals have to point outside the contour
    % If normal points inside resp. the tip of the normal is inside the
    % contour, change the direction
    Indcs_Inside_Normals = isPointInPolygon( (Contour+Normals) , Contour);
    % Change the direction of all normals pointing inside the contour
    Normals(Indcs_Inside_Normals,1:2)=Normals(Indcs_Inside_Normals,1:2) * -1;
    % A scaling factor for the length of the normals
    ScalingFactor = max(abs([XMin,XMax,YMin,YMax]));
    % Multiply the normals with kappa (K), to visualize K on the contour
    Normals = repmat(K{sigma},1,2).*Normals*ScalingFactor;
    quiver(axH_C, Contour(:,1),Contour(:,2),Normals(:,1),Normals(:,2),...
        'color','k','ShowArrowHead','off','AutoScale','off','LineStyle','--')
    % Connect the tips of the normals
    NormalEnds = Normals + Contour;
    plot(axH_C, NormalEnds(:,1),NormalEnds(:,2),'k-.','LineWidth',1.5)
    
    %% Plot extremity points of the articulating surface
    % Plot the posterior extremity A (pExA)
    scatter(axH_C, Contour(pExA,1),Contour(pExA,2), 'filled');
    text(axH_C, Contour(pExA,1),Contour(pExA,2), ['A for \sigma = ' num2str(sigma)],...
        'VerticalAlignment','top');
    
    % Plot the anterior medial extremity B (amExB)
    amExB(2) = scatter(axH_C, Contour(amExB,1),Contour(amExB,2), 'filled');
    amExB(3) = text(axH_C, Contour(amExB(1),1),Contour(amExB(1),2), ['medial B for \sigma = ' num2str(sigma)],...
        'HorizontalAlignment','right');
    
    % Plot the anterior lateral extremity B (alExB)
    alExB(2) = scatter(axH_C, Contour(alExB,1),Contour(alExB,2), 'filled');
    alExB(3) = text(axH_C, Contour(alExB(1),1),Contour(alExB(1),2), ['lateral B for \sigma = ' num2str(sigma)],...
        'VerticalAlignment','top','HorizontalAlignment','right');
    
    axis(axH_C, 'equal');
    
    if vis == 1 % <- Set this to 1 if Plots are needed
        %% Plot: Curvature Scale Space (CSS) Image
        figH_CSS = figure('name', 'Curvature Scale Space (CSS) Image', 'color','w');
        axH_CSS = axes(figH_CSS);
        for i=1:length(zcp)
            plot(zcp{i},S{i},'k.');%,'MarkerFaceColor',C(i,:),'MarkerEdgeColor',C(i,:));
            hold(axH_CSS,'on')
        end
        hold(axH_CSS,'off')
        xlim(axH_CSS, [1 length(K{1})]);
        title(axH_CSS, 'Curvature Scale Space (CSS) Image');
        
        if length(K) > 1
            %% Plot: Curvature kappa
            figH_kappa = figure('name', 'Curvature kappa', 'color','w');
            axH_kappa = axes(figH_kappa);
            surf(axH_kappa, cell2mat(K))
            xlabel(axH_kappa, '\sigma');
            ylabel(axH_kappa, 'u');
            zlabel(axH_kappa, '\kappa(u,\sigma)');
            title(axH_kappa, 'Curvature of \Gamma_\sigma: \kappa(u,\sigma)');
        end
    end
end

end

function [pExA, amExB, alExB, axH_C]=circleCornerCase(Contour, IYMax, vis)

pExA=IYMax;
amExB=IYMax;
alExB=IYMax;

if vis == 1 || vis == 2
    %% Plot: Contour
    figH_C = figure('name','Contour', 'color','w');
    axH_C = axes(figH_C);
    title(axH_C, 'Contour');
    plot(axH_C, Contour(:,1),Contour(:,2),'k-','LineWidth',2);
    hold(axH_C,'on');
    
    %% Plot extremity points of the articulating surface
    % Plot the posterior extremity A (pExA)
    scatter(axH_C, Contour(pExA,1),Contour(pExA,2), 'filled');
    text(axH_C, Contour(pExA,1),Contour(pExA,2), 'A for circle corner case', ...
        'VerticalAlignment','top');
    
    % Plot the anterior medial extremity B (amExB)
    amExB(2) = scatter(axH_C, Contour(amExB,1),Contour(amExB,2), 'filled');
    amExB(3) = text(axH_C, Contour(amExB(1),1),Contour(amExB(1),2), 'medial B for circle corner case',...
        'HorizontalAlignment','right');
    
    % Plot the anterior lateral extremity B (alExB)
    alExB(2) = scatter(axH_C, Contour(alExB,1),Contour(alExB,2), 'filled');
    alExB(3) = text(axH_C, Contour(alExB(1),1),Contour(alExB(1),2), 'lateral B for circle corner case',...
        'VerticalAlignment','top','HorizontalAlignment','right');
    
    axis(axH_C, 'equal');
end
end