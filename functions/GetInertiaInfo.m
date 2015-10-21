function Bone = GetInertiaInfo(Bone)

% Get Volume (V), Center of Mass (b0), Inertia Tensor (J) of the Bone
[Bone.Props.V, Bone.Props.b0, Bone.Props.J] = VolumeIntegrate(Bone.Vertices, Bone.Faces);

% Get Principal Axis (Axes0) & Principal Moments of Inertia (Jii)
[Bone.Props.Axes0, Bone.Props.Jii] = eig(Bone.Props.J); % Sign of the Eigenvectors can change (In agreement with their general definition)

% Keep determinate of the Principal Axis (Axes0) positive
if det(Bone.Props.Axes0) < 0
    Bone.Props.Axes0 = -Bone.Props.Axes0;
end

% Create a Affine Transformation to move the Bone into his own Inertia System
Bone.Props.TfmToInertia = affine3d([ [Bone.Props.Axes0 Bone.Props.b0]; [0 0 0 1] ]');

end

