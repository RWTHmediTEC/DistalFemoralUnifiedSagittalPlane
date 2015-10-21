function CB_CB_ParallelComputing(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.Algorithm3.ParallelComputing = get(hObject,'Value');
    guidata(hObject,GUIData);
end