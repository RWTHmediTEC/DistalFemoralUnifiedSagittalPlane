function GD = SetStartSetup(GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

vertices = transformPoint3d(GD.Subject.Mesh.vertices, GD.Subject.TFM);

%% Find most posterior points of the condyles (mpCPts)
[XminIdxNZ, XminIdxPZ] = FindMostPosteriorPts(vertices);
XminNZ = vertices(XminIdxNZ,:);
XminPZ = vertices(XminIdxPZ,:);

%% Create cutting boxes
% Origin of the cutting boxes [0, 0, mpCPts(3)]
OriginNZ = [0, 0, XminNZ(3)];
OriginPZ = [0, 0, XminPZ(3)];

% Calculate the size of the cutting boxes by the size of the bounding box 
% of the bone vertices.
Scale = 1.2;
BBox = boundingBox3d(vertices);
Xlength = (abs(BBox(1))+BBox(2))*Scale;
Ylength = (abs(BBox(3))+BBox(4))*Scale;
Zlength = GD.Cond.NoPpC-1;

%% Plotting
if GD.Visualization
    H3D = GD.Figure.D3Handle;
    hold(H3D,'on')
    
    switch GD.Subject.Side
        case 'R'
            Color = {'m','c'}; % Medial = magenta, Lateral = cyan
        case 'L'
            Color = {'c','m'}; % Lateral = cyan, Medial = magenta
        otherwise
            error('Wrong side variable!')
    end
    
    % Plot the boxes
    BoxProps.FaceAlpha = 0.2;
    BoxProps.EdgeColor = 'none';
    [CNZ.vertices, CNZ.faces, ~] = CreateCuboid(OriginNZ, [Xlength, Ylength, Zlength]);
    patch(H3D, CNZ, 'FaceColor', Color{1}, BoxProps);
    [CPZ.vertices, CPZ.faces, ~] = CreateCuboid(OriginPZ, [Xlength, Ylength, Zlength]);
    patch(H3D, CPZ, 'FaceColor', Color{2}, BoxProps);
    
    % Plot most posterior points of the condyles (mpCPts)
    % Indices of the Medial & Lateral point
    scatter3(H3D,XminNZ(1),XminNZ(2),XminNZ(3),Color{1},'filled');
    scatter3(H3D,XminPZ(1),XminPZ(2),XminPZ(3),Color{2},'filled');
end

end
