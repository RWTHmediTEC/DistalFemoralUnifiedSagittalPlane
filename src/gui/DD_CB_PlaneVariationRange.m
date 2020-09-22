function DD_CB_PlaneVariationRange(hObject, ~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
Index = get(hObject,'Value');
GD.Algorithm3.PlaneVariationRange = Index-1;

%Enable "Plot Contours" only for no/zero plane variation
if GD.Algorithm3.PlaneVariationRange == 0
    set(GD.Algorithm1.Handle,'Enable','on')
else
    set(GD.Algorithm1.Handle,'Enable','off')
    set(GD.Algorithm1.Handle,'Value',0)
    GD.Algorithm1.PlotContours = 0;
end
guidata(hObject,GD);
end