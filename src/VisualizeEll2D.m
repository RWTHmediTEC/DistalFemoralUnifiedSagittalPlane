function VisualizeEll2D(axH, P, Color)
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
scatter(axH, z(1),z(2),'MarkerEdgeColor', [0,0,0], 'MarkerFaceColor',Color);
drawEllipse(axH, z(1), z(2), a, b, rad2deg(alpha), 'Color',Color,'LineStyle','-')
quiver(axH, repmat(z(1),2,1),repmat(z(2),2,1),AB(:,1),AB(:,2),...
    ':k','Autoscale','off','ShowArrowHead','off');
scatter(axH, f(:,1),f(:,2),'MarkerEdgeColor', [0,0,0], 'MarkerFaceColor',Color);
end