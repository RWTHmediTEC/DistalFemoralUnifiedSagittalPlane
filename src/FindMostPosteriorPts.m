function [I_Xmin_NegZ, I_Xmin_PosZ] = FindMostPosteriorPts(Vertices)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

% Find vertex with min x-value in all vertices with negative z-values
VertNegZ = Vertices;
% Set all vertices with positive z-values to nan
VertNegZ((Vertices(:,3) > 0),:) = nan;
% Index of Vertex with min x-value
[~, I_Xmin_NegZ] = min(VertNegZ(:,1));

% % Alternative: Find vertex with min x-value in all vertices with negative z-values
% I_Xmin_NegZ = find(ismember(Vertices(:,1),min(Vertices((Vertices(:,3) < 0),1))));

% Find vertex with min x-value in all vertices with positive z-values
VertPosZ = Vertices;
% Set all vertices with negative z-values to nan
VertPosZ((Vertices(:,3) < 0),:) = nan;
% Index of Vertex with min x-value
[~, I_Xmin_PosZ] = min(VertPosZ(:,1));

% % Alternative: Find vertex with min x-value in all vertices with positive z-values
% I_Xmin_PosZ = find(ismember(Vertices(:,1),min(Vertices((Vertices(:,3) > 0),1))));

end