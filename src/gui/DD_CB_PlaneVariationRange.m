function DD_CB_PlaneVariationRange(hObject, ~)
    GUIData = guidata(hObject);
    Index = get(hObject,'Value');
    GUIData.Algorithm3.PlaneVariationRange = Index-1;
    
    %Enable "Plot Contours" only for no/zero plane variation
    if GUIData.Algorithm3.PlaneVariationRange == 0
        set(GUIData.Algorithm1.Handle,'Enable','on') 
    else
        set(GUIData.Algorithm1.Handle,'Enable','off')
        set(GUIData.Algorithm1.Handle,'Value',0)
        GUIData.Algorithm1.PlotContours = 0;
    end
    guidata(hObject,GUIData);
end