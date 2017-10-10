function GD = B_CB_SaveResults(hObject, GD)
if ishandle(hObject); GD = guidata(hObject); end

if isfield(GD.Results, 'PlaneRotMat')
    load(GD.Subject.PathMAT)
    
    USPTFM  = GD.Results.USPTFM;
    PFEA = GD.Results.PFEA;
    CEA = GD.Results.CEA;
    
    save(GD.Subject.PathMAT, 'USPTFM', 'PFEA', 'CEA', '-append')

    disp('Results saved.')
else
    uiwait(errordlg('There are no results to save'));
end

if isfield(GD.Results, 'B_H_SaveResults')
    set(GD.Results.B_H_SaveResults,'Enable','off')
end

if ishandle(hObject); guidata(hObject,GD); end
end