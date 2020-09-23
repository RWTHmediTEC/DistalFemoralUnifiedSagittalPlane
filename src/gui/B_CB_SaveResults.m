function GD = B_CB_SaveResults(hObject, GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

if ishandle(hObject); GD = guidata(hObject); end

if isfield(GD.Results, 'PlaneRotMat')
    
    USPTFM  = GD.Results.USPTFM;
    PFEA = GD.Results.PFEA;
    CEA = GD.Results.CEA;
    
    if ~isfolder([GD.ToolPath 'results\'])
        mkdir([GD.ToolPath 'results\'])
    end
    save([GD.ToolPath 'results\' GD.Subject.Name '.mat'], 'USPTFM', 'PFEA', 'CEA')
    
    disp('Results saved.')
else
    uiwait(errordlg('There are no results to save'));
end

if isfield(GD.Results, 'B_H_SaveResults')
    set(GD.Results.B_H_SaveResults,'Enable','off')
end

if ishandle(hObject); guidata(hObject,GD); end
end