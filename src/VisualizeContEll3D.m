function VisualizeContEll3D(P, EllColor)

%% Contour
% Plot contour-part in 3D
CP3D = P.xyz(P.ExPts.A:P.ExPts.B, :);
plot3(CP3D(:,1),CP3D(:,2),CP3D(:,3),'k','Linewidth',2);

%% Ellipse
% Calculate ellipse points
E3D(:,1:2) = CalculateEllipsePoints(P.Ell.z', P.Ell.a, P.Ell.b, P.Ell.g, 100);
E3D(:,3) = P.xyz(1,3);
% Plot ellipses in 3D
plot3(E3D(:,1), E3D(:,2), E3D(:,3),'Color', EllColor,'Linewidth',1);
end