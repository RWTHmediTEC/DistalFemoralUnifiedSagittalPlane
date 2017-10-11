function GD = SetStartSetup(GD)

tempVertices = transformPoint3d(GD.Subject.Mesh.vertices, GD.Subject.STL.TFM);

%% Find most posterior points of the condyles (mpCPts)
[XminIdxNZ, XminIdxPZ] = FindMostPosteriorPts(tempVertices);

%% Create cutting boxes
% Origin of the cutting boxes [0, 0, mpCPts(3)]
OriginNZ = [0, 0, tempVertices(XminIdxNZ,3)];
OriginPZ = [0, 0, tempVertices(XminIdxPZ,3)];

% Calculate the size of the cutting boxes by the size of the bounding box 
% of the bone vertices.
Scale = 1.2;
BBox = boundingBox3d(tempVertices);
Xlength = (abs(BBox(1))+BBox(2))*Scale;
Ylength = (abs(BBox(3))+BBox(4))*Scale;
Zlength = GD.Cond.NoPpC-1;

%% Plotting
if GD.Visualization == 1
    lSP = GD.Figure.LeftSpHandle;
    hold(lSP,'on')
    
    % Plot the boxes
    BoxProps.FaceAlpha = 0.2;
    BoxProps.EdgeColor = 'none';
    [CNZ.vertices, CNZ.faces, ~] = CreateCuboid(OriginNZ, [Xlength, Ylength, Zlength]);
    patch(lSP, CNZ, 'FaceColor', 'g', BoxProps);
    [CPZ.vertices, CPZ.faces, ~] = CreateCuboid(OriginPZ, [Xlength, Ylength, Zlength]);
    patch(lSP, CPZ, 'FaceColor', 'g', BoxProps);
    
    % Plot most posterior points of the condyles (mpCPts)
    % Indices of the Medial & Lateral point
    mpCPIdx = [XminIdxNZ, XminIdxPZ];
    scatter3(lSP,...
        tempVertices(mpCPIdx,1),...
        tempVertices(mpCPIdx,2),...
        tempVertices(mpCPIdx,3),'g','filled');
end

end
