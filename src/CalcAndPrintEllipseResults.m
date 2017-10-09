function M = CalcAndPrintEllipseResults(C, NoPpC, Print)

ma = []; la = [];
mb = []; lb = [];
% Get data from struct
for s=1:2
    for c=1:NoPpC
        switch C(s).Zone
            case 'NZ'
                ma(end+1) = norm(C(s).P(c).Ell.AB(1,:));
                mb(end+1) = norm(C(s).P(c).Ell.AB(2,:));
            case 'PZ'
                la(end+1) = norm(C(s).P(c).Ell.AB(1,:));
                lb(end+1) = norm(C(s).P(c).Ell.AB(2,:));
        end
    end; clear c
end; clear s

colh = {'Mean','Std'};
rowh = {' a med.', ' a lat.',...
        ' b med.', ' b lat.',...
        ' a/b med.', ' a/b lat.'};

% Calculate Mean and Std
M(1,1) = mean(ma); M(1,2) = std(ma);
M(2,1) = mean(la); M(2,2) = std(la);

M(3,1) = mean(mb); M(3,2) = std(mb);
M(4,1) = mean(lb); M(4,2) = std(lb);

M(5,1) = mean(ma./mb); M(5,2) = std(ma./mb);
M(6,1) = mean(la./lb); M(6,2) = std(la./lb);

if Print == 1
    display(...
        [' Summary of the major and minor axis lengths, and the ratio between ' char(10) ...
        ' the major and minor axis lengths of the best-fit ellipses for the ' char(10) ...
        ' cross sections along the unified sagittal plane.' char(10)])
    
    displaytable(M,colh,8,'.4f',rowh,1)
    
    display(' ');
end

end

