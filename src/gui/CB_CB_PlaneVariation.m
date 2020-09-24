function CB_CB_PlaneVariation(hObject, ~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
GD.Algorithm3.PlotPlaneVariation = get(hObject,'Value');
guidata(hObject,GD);
end