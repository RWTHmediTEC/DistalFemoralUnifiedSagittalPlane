function GD = B_CB_SaveResults(hObject, GD)
if ishandle(hObject); GD = guidata(hObject); end

if isfield(GD.Results, 'PlaneRotMat')
    
    PRM = GD.Results.PlaneRotMat;
    
    load(GD.Subject.PathMAT)
    
    USPTFM  = GD.Subject.STL.TFM * PRM;
    PFEA = [GD.Results.pFociLine(1:3)*PRM(1:3,1:3), GD.Results.pFociLine(4:6)*PRM(1:3,1:3)];
    CEA = [GD.Results.CenterLine(1:3)*PRM(1:3,1:3), GD.Results.CenterLine(4:6)*PRM(1:3,1:3)];
    
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