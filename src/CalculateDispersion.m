function Dispersion = CalculateDispersion(Points)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

n = length(Points);
meanXMat = repmat(mean(Points(:,1)),n,1);
meanYMat = repmat(mean(Points(:,2)),n,1);
% 2D dispersion or root mean squared distance (RMSD)
Dispersion = sqrt(mean( (Points(:,1)-meanXMat).^2 + (Points(:,2)-meanYMat).^2 ));

end