%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

clearvars; close all

% Add src path
addpath(genpath(fullfile(fileparts([mfilename('fullpath'), '.m']), 'src')));

%% Clone example data
if ~exist('VSD', 'dir')
    try
        !git clone --depth 1 https://github.com/MCM-Fischer/VSDFullBodyBoneModels VSD
        rmdir(fullfile('VSD','.git'), 's')
    catch
        warning([newline 'Clone (or copy) the example data from: ' ...
            'https://github.com/MCM-Fischer/VSDFullBodyBoneModels' newline 'to: ' ...
            fullfile(fileparts([mfilename('fullpath'), '.m']), 'VSD') ...
            ' and try again!' newline])
        return
    end
end

%% Load subject names
subjectXLSX = fullfile('VSD', 'MATLAB', 'res', 'VSD_Subjects.xlsx');
Subjects = readtable(subjectXLSX);
Subjects{2:2:height(Subjects),7} = 'L';
Subjects{1:2:height(Subjects),7} = 'R'; 

for s=1%:size(Subjects, 1)
    name = Subjects{s,1}{1};
    side = Subjects{s,7};

    % Prepare distal femur
    load(fullfile('VSD', 'Bones', [name '.mat']), 'B');
    load(fullfile('data', [name '.mat']), 'inertiaTFM', 'uspPreTFM', 'distalCutPlaneInertia');
    femurInertia = transformPoint3d(B(ismember({B.name}, ['Femur_' side])).mesh, inertiaTFM);
    femurInertia = splitMesh(femurInertia, 'mostVertices');
    if strcmp(side, 'L')
        xReflection = eye(4);
        xReflection(1,1) = -1;
        distalCutPlaneInertia = reversePlane(distalCutPlaneInertia);
        uspPreTFM = createRotationOy(pi)*createRotationOz(pi)*uspPreTFM;
        distalCutPlaneInertia = transformPlane3d(distalCutPlaneInertia, xReflection);
    end
    distalFemurInertia = cutMeshByPlane(femurInertia, distalCutPlaneInertia);
    uspInitialRot = rotation3dToEulerAngles(uspPreTFM(1:3,1:3), 'ZYX');
    %% Select different options by (un)commenting
    % Default mode
    [USPTFM, PFEA, CEA] = USP(distalFemurInertia, side, uspInitialRot, 'Subject',name);
    % Silent mode
    % [USPTFM, PFEA, CEA] = USP(distalFemurInertia, side, uspInitialRot, 'Subject',name,...
    %    'Visu',false, 'Verbose',false);
    % The other options
    % [USPTFM, PFEA, CEA] = USP(distalFemurInertia, side, uspInitialRot, 'Subject',name,...
    %    'PlaneVariationRange',12, 'StepSize',3);
    % Special case: 'PlaneVariationRange', 0 -> 48 additional figures!
    % [USPTFM, PFEA, CEA] = USP(distalFemurInertia, side, uspInitialRot, 'Subject',name,...
    %   'PlaneVariationRange',0, 'StepSize',2);
end


% [List.f, List.p] = matlab.codetools.requiredFilesAndProducts([mfilename '.m']);
% List.f = List.f'; List.p = List.p';