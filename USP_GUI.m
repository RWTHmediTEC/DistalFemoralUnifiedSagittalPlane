clearvars; close all

% USP path
GD.ToolPath = [fileparts([mfilename('fullpath'), '.m']) '\'];

% Add src path
addpath(genpath([GD.ToolPath 'src']));

% Compile mex file if not exist
mexPath = [GD.ToolPath 'src\external\intersectPlaneSurf'];
if ~exist([mexPath '\IntersectPlaneTriangle.mexw64'],'file')
    mex([mexPath '\IntersectPlaneTriangle.cpp'],'-v','-outdir', mexPath);
end

%% Get Subjects
GD.Subject.DataPath = {'VSD\Bones\','data\'};
subjectXLSX = 'VSD\MATLAB\res\VSD_Subjects.xlsx';
Subjects = readtable(subjectXLSX);
Subjects{2:2:height(Subjects),7} = 'L';
Subjects{1:2:height(Subjects),7} = 'R'; 

%% Number of cutting planes per cuting box
GD.Algorithm3.NoCuttingPlanes = 8;

%% Figure
GD.Verbose = true;
GD.Visualization = true;
GD.Figure.Color = 'w';
MonitorsPos = get(0,'MonitorPositions');
FH = figure(...
    'Units','pixels',...
    'NumberTitle','off',...
    'Color',GD.Figure.Color,...
    'ToolBar','figure',...
    'WindowScrollWheelFcn',@M_CB_Zoom,...
    'WindowButtonDownFcn',@M_CB_RotateWithMouse);
if     size(MonitorsPos,1) == 1
    set(FH,'OuterPosition',MonitorsPos(1,:));
elseif size(MonitorsPos,1) == 2
    set(FH,'OuterPosition',MonitorsPos(2,:));
end
FH.MenuBar = 'none';
FH.ToolBar = 'none';
FH.WindowState = 'maximized';
GD.Figure.Handle = FH;

%% 3D view
LPT = uipanel('Title','3D view','FontSize',14,'BorderWidth',2,...
    'BackgroundColor',GD.Figure.Color,'Position',[0.01 0.05 0.49 0.9]);
LH = axes('Parent', LPT, 'Visible','off', 'Color',GD.Figure.Color,'Position',[0.05 0.01 0.9 0.9]);
GD.Figure.D3Handle = LH;

%% 2D view
RPT = uipanel('Title','2D view','FontSize',14,'BorderWidth',2,...
    'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.51 0.48 0.44]);
RH = axes('Parent', RPT, 'Visible','off', 'Color',GD.Figure.Color);
axis(RH, 'on'); axis(RH, 'equal'); grid(RH, 'on'); xlabel(RH, 'X [mm]'); ylabel(RH, 'Y [mm]');
GD.Figure.D2Handle = RH;

%% Convergence plot
% A convergence plot as a function of alpha and beta.
RPB = uipanel('Title','Convergence progress','FontSize',14,'BorderWidth',2,...
    'BackgroundColor',GD.Figure.Color,'Position',[0.51 0.05 0.48 0.44]);
IH = axes('Parent', RPB, 'Visible','off', 'Color',GD.Figure.Color);
axis(IH, 'equal', 'tight'); view(IH,3);
xlabel(IH,'\alpha [°]');
ylabel(IH,'\beta [°]');
zlabel(IH, 'Dispersion [mm]')
title(IH, 'Dispersion of the posterior foci as function of \alpha & \beta','FontSize',14)
GD.Figure.DispersionHandle = IH;

%% GUI
% uicontrol Size
BSX = 0.12; BSY = 0.023;

%Font properies
FontPropsA.FontUnits = 'normalized';
FontPropsA.FontSize = 0.8;

FontPropsB.FontUnits = 'normalized';
FontPropsB.FontSize = 0.5;

%% Controls on the Top of the GUI - LEFT SIDE
% Entries of the dropdown menue as string
GD.Subject.Name = Subjects{1,1}{1};
GD.Subject.Side = Subjects{1,7};
% Subject static text
uicontrol('Style','text','String','Subject: ','HorizontalAlignment','Right','BackgroundColor',GD.Figure.Color,...
    'Units','normalized','Position',      [0.13-BSX 0.97 BSX/2 BSY],FontPropsA)
% Subject dropdown menue
uicontrol('Style', 'popup', 'String',Subjects.ID,...
    'Units','normalized','Position',      [0.13-BSX*1/2 0.97 BSX BSY],FontPropsB,...
    'Callback', {@DD_CB_Subject, Subjects});
% Load button
uicontrol('Units','normalized','Position',[0.13+BSX*1/2 0.97 BSX BSY],FontPropsA,...
    'String','Load','Callback',@LoadSubject);
% Start button
uicontrol('Units','normalized','Position',[0.13+BSX*3/2 0.97 BSX BSY],FontPropsA,...
        'String','Start Calculation','Callback',@RoughFineIteration);

%% Controls on the Top of the GUI - RIGHT SIDE
GD.Algorithm1.PlotContours = 0;
GD.Algorithm1.Handle = ...
    uicontrol('Style','checkbox','Units','normalized','Position',[0.95-BSX*11/3 0.97 BSX*4/3 BSY],...
    FontPropsB,'BackgroundColor',GD.Figure.Color,'Enable','off',...
    'String','Alg. 1: Plot Contours, CSS Image & Curvature','Callback',@CB_CB_PlotContours);
GD.Algorithm3.EllipsePlot = 0;
uicontrol('Style','checkbox','Units','normalized','Position',[0.95-BSX*7/3 0.97 BSX BSY],FontPropsB,...
    'BackgroundColor',GD.Figure.Color,'String','Alg. 3: Plot Ellipses & Foci','Callback',@CB_CB_EllipsePlot,'Value',0);
GD.Algorithm3.PlotPlaneVariation = 0;
uicontrol('Style','checkbox','Units','normalized','Position',[0.95-BSX*4.5/3 0.97 BSX BSY],FontPropsB,...
    'BackgroundColor',GD.Figure.Color,'String','Alg. 3: Plot Plane Variation','Callback', @CB_CB_PlaneVariation);
GD.Algorithm3.PlaneVariationRange = 4;
uicontrol('Style','text','Units','normalized','Position',[0.95-BSX*2/3 0.97 BSX*2/3 BSY],FontPropsB,...
    'BackgroundColor',GD.Figure.Color,'String','-/+ Plane Variaton in [°]: ','HorizontalAlignment','Right')
uicontrol('Style', 'popup','Units','normalized','Position',[0.95-BSX*0/3 0.97 BSX*1/3 BSY],FontPropsB,...
    'String',cellfun(@num2str,num2cell(0:16),'UniformOutput',false),'Callback',@DD_CB_PlaneVariationRange,'Value',5);
uicontrol('Style','text','Units','normalized','Position',[0.95-BSX*2/3 0.97-BSY BSX*2/3 BSY],FontPropsB,...
    'BackgroundColor',GD.Figure.Color,'String','Step size [°]: ','HorizontalAlignment','Right')
GD.Algorithm3.StepSize = 2;
uicontrol('Style', 'popup','Units','normalized','Position',[0.95-BSX*0/3 0.97-BSY BSX*1/3 BSY],FontPropsB,...
    'String',cellfun(@num2str,num2cell(1:4),'UniformOutput',false),'Callback',@DD_CB_StepSize,'Value',2);

%% Controls on the Bottom of the GUI - LEFT SIDE
% Fine-tuning Rotate-buttons
uicontrol('Units','normalized','Position',[0.25-BSX*3/2 0.01+BSY/2 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around pos. X-Axis','Callback',{@B_CB_RotateBone, [1, 0, 0], 2});
uicontrol('Units','normalized','Position',[0.25-BSX*3/2 0.01 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around neg. X-Axis','Callback',{@B_CB_RotateBone, [1, 0, 0], -2});
uicontrol('Units','normalized','Position',[0.25-BSX*1/2 0.01+BSY/2 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around pos. Y-Axis','Callback',{@B_CB_RotateBone, [0, 1, 0], 2});
uicontrol('Units','normalized','Position',[0.25-BSX*1/2 0.01 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around neg. Y-Axis','Callback',{@B_CB_RotateBone, [0, 1, 0], -2});
uicontrol('Units','normalized','Position',[0.25+BSX*1/2 0.01+BSY/2 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around pos. Z-Axis','Callback',{@B_CB_RotateBone, [0, 0, 1], 2});
uicontrol('Units','normalized','Position',[0.25+BSX*1/2 0.01 BSX BSY/2],FontPropsA,...
    'String','Rotate bone around neg. Z-Axis','Callback',{@B_CB_RotateBone, [0, 0, 1], -2});

%% Controls on the Bottom of the GUI - RIGHT SIDE
% Save button
GD.Figure.SaveResultsHandle = ...
uicontrol('Units','normalized','Position',[0.75-BSX*1/2 0.01 BSX BSY],FontPropsA,...
    'String','Save Results','Enable','off','Callback',@B_CB_SaveResults);

%% Guidata to share data among callbacks
guidata(FH, GD);

% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts('USP_GUI.m');
% List.f = List.f'; List.p = List.p';