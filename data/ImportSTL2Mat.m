clearvars; close all

addpath(genpath('extern'));

% Settings
Side = 'Right';
InitialRot = [0 -90 -90];

[fn,pn,~] = uigetfile('*.stl','Select stl file');
[pathstr,name,ext] = fileparts([pn, fn]); 

[Vertices, Faces, ~, ~, ~] = stlread([pn,fn]);
[Vertices, Faces] = patchslim(Vertices, Faces);

Subject = name;

clearvars -except Side InitialRot Faces Vertices Subject

save([Subject '.mat'])