function VisualizeEll2D(H, P, Color)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

z = P.Ell.z;
a = P.Ell.a;
b = P.Ell.b;
alpha = P.Ell.g;
f = P.Ell.pf;
AB = P.Ell.AB;

% Plot ellipses & foci in 2D
scatter(H, z(1),z(2),'MarkerEdgeColor', [0,0,0], 'MarkerFaceColor',Color);
ellProps.Color = Color;
plotellipse(H, z, a, b, alpha, ellProps);
quiver(H, repmat(z(1),2,1),repmat(z(2),2,1),AB(:,1),AB(:,2),...
    ':k','Autoscale','off','ShowArrowHead','off');
scatter(H, f(:,1),f(:,2),'MarkerEdgeColor', [0,0,0], 'MarkerFaceColor',Color);
end