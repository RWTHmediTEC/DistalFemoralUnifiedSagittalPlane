function GD = B_CB_SaveResults(hObject, GD)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

if ishandle(hObject); GD = guidata(hObject); end

if isfield(GD.Results, 'PlaneRotMat')
    
    USPTFM  = GD.Results.USPTFM;
    PFEA = GD.Results.PFEA;
    CEA = GD.Results.CEA;
    
    if ~isfolder(fullfile(GD.ToolPath, 'results'))
        mkdir(fullfile(GD.ToolPath, 'results'))
    end
    save(fullfile(GD.ToolPath, 'results', [GD.Subject.Name '.mat']), 'USPTFM', 'PFEA', 'CEA')
    
    disp('Results saved.')
else
    uiwait(errordlg('There are no results to save'));
end

if isfield(GD.Figure, 'SaveResultsHandle')
    GD.Figure.SaveResultsHandle.Enable = 'off';
end

if ishandle(hObject); guidata(hObject,GD); end

end