function GD = SetStartSetup(GD)

tempVertices = transformPoint3d(GD.Subject.Mesh.vertices, GD.Subject.STL.TFM);
%% Find most posterior points of the condyles (mpCPts)
[GD.Cond.NZ.IXmax, GD.Cond.PZ.IXmax] = ...
    FindMostPosteriorPts(tempVertices);

%% Create cutting boxes
% Origin of the cutting boxes [0, 0, mpCPts(3)]
GD.Cond.NZ.Origin = [0, 0, tempVertices(GD.Cond.NZ.IXmax,3)];
GD.Cond.PZ.Origin = [0, 0, tempVertices(GD.Cond.PZ.IXmax,3)];

% Calculate the size of the cutting boxes by the size of the bounding box 
% of the bone vertices.
Scale = 1.2;
BBox = boundingBox3d(tempVertices);
Xlength = (abs(BBox(1))+BBox(2))*Scale;
Ylength = (abs(BBox(3))+BBox(4))*Scale;
Zlength = GD.Cond.NoPpC-1;

%% Plotting
if GD.Visualization == 1
    figure(GD.Figure.Handle); subplot(GD.Figure.LeftSpHandle);
    hold on
    
    % Plot the boxes
    BoxProps.FaceAlpha = 0.2;
    BoxProps.EdgeColor = 'none';
    [NZCBV, NZCBF, ~] = CreateCuboid(GD.Cond.NZ.Origin, [Xlength, Ylength, Zlength]);
    GD.mpCPtsStartH(2) = patch('Faces', NZCBF, 'Vertices', NZCBV, 'FaceColor', 'g', BoxProps);
    [PZCBV, PZCBF, ~] = CreateCuboid(GD.Cond.PZ.Origin, [Xlength, Ylength, Zlength]);
    GD.mpCPtsStartH(3) = patch('Faces', PZCBF, 'Vertices', PZCBV, 'FaceColor', 'g', BoxProps);
    
    % Plot most posterior points of the condyles (mpCPts)
    % Indices of the Medial & Lateral point
    mpCP = [GD.Cond.NZ.IXmax, GD.Cond.PZ.IXmax];
    GD.mpCPtsStartH(1) = scatter3(...
        tempVertices(mpCP,1),tempVertices(mpCP,2),tempVertices(mpCP,3),'g','filled');
end

end
