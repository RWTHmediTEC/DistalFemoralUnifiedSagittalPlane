function CB_CB_PlotContours(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.Algorithm1.PlotContours = get(hObject,'Value');
    guidata(hObject,GUIData);
end