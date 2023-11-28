function VisualizeContEll3D(H, P, EllColor)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

%% Contour
% Plot contour-part in 3D
CP3D = P.xyz(P.ExPts.A:P.ExPts.B, :);
plot3(H, CP3D(:,1),CP3D(:,2),CP3D(:,3),'k','Linewidth',2);

%% Ellipse
% Calculate ellipse points
E3D(:,1:2) = CalculateEllipsePoints(P.Ell.z', P.Ell.a, P.Ell.b, P.Ell.g, 100);
E3D(:,3) = P.xyz(1,3);
% Plot ellipses in 3D
plot3(H, E3D(:,1), E3D(:,2), E3D(:,3),'Color', EllColor,'Linewidth',1);

end