function B_CB_RotateBone(hObject, ~, Axis, Angle)
GUIData = guidata(hObject);

if isfield(GUIData.Subject,'PatchHandle')
    
    ClearPlot(GUIData.Figure.Handle, GUIData.Figure.LeftSpHandle, {'Patch','Scatter','Line'})
 
    rotate(GUIData.Subject.PatchHandle,Axis, Angle, [0,0,0])
    % Calculate the Rotation Matrix for the plane variation
    %                                    (Z-Axis,Y-Axis,X-Axis)
    if     sum(Axis == [1, 0, 0]) == 3
            TFM = eulerAnglesToRotation3d(     0,     0,-Angle);
    elseif sum(Axis == [0, 1, 0]) == 3
            TFM = eulerAnglesToRotation3d(     0,-Angle,     0);
    elseif sum(Axis == [0, 0, 1]) == 3
            TFM = eulerAnglesToRotation3d(-Angle,     0,     0);
    end
    TFM = GUIData.Subject.STL.TFM*TFM;
    GUIData.Subject.STL.TFM = TFM;
    GUIData.Subject.STL.V_C_tfm = ...
        transformPointsInverse(affine3d(TFM'), GUIData.Subject.STL.Vertices);
    
    %% Find the mpCPts & plot the cutting boxes
    GUIData = SetStartSetup(GUIData);
    
else
    uiwait(errordlg('Load a bone!','modal'));
end

% assignin('base','GUIData',GUIData);
guidata(hObject,GUIData);

