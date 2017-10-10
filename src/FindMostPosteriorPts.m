function [I_Xmin_NegZ, I_Xmin_PosZ] = FindMostPosteriorPts(Vertices)

% Find vertex with min x-value in all vertices with negative z-values
VertNegZ = Vertices;
% Set all vertices with positive z-values to 0
VertNegZ((Vertices(:,3) > 0),:) = 0;
% Index of Vertex with min x-value
[~, I_Xmin_NegZ] = min(VertNegZ(:,1));

% % Alternative: Find vertex with min x-value in all vertices with negative z-values
% I_Xmin_NegZ = find(ismember(Vertices(:,1),min(Vertices((Vertices(:,3) < 0),1))));

% Find vertex with min x-value in all vertices with positive z-values
VertPosZ = Vertices;
% Set all vertices with negative z-values to 0
VertPosZ((Vertices(:,3) < 0),:) = 0;
% Index of Vertex with min x-value
[~, I_Xmin_PosZ] = min(VertPosZ(:,1));

% % Alternative: Find vertex with min x-value in all vertices with positive z-values
% I_Xmin_PosZ = find(ismember(Vertices(:,1),min(Vertices((Vertices(:,3) > 0),1))));


