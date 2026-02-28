clear;
clc;

subdir = [1:12];
filebase = '/path/';
masksPth = '/path/';
corr_type = 'Pearson';

ROIs = {'IFG_L', 'IFG_R', 'IFGorb_L', 'IFGorb_R', 'MFG_L', 'MFG_R', 'AntTemp_L', 'AntTemp_R', 'PostTemp_L', 'PostTemp_R'};

for j = 1:length(ROIs)

    for i = 1:length(subdir)

        cfg = decoding_defaults;
        cfg.plot_design = 0;
        cfg.results.overwrite = 1;
        cfg.analysis = 'roi';

        cfg.results.dir = [filebase num2str(subdir(i), '%.2d') '/Results_' ROIs{j} '/'];
        cfg.files.mask = [masksPth 'r' ROIs{j} '.nii'];

        beta_loc = ([filebase num2str(subdir(i), '%.2d')  '/']);
        regressor_names = design_from_spm(beta_loc);

        beta_indices = [1:32, 39:71, 78:117, 124:147, 154:177, 184:216, 223:252, 259:285, 292:312, 319:344, 351:392, 399:438, 445:468, 475:502, 509:540, 547:578, 585:614, 621:651, 658:684, 691:714, 721:754, 761:790, 797:823, 830:860, 867:898, 905:928, 935:962, 969:1001, 1008:1038, 1045:1066, 1073:1113, 1120:1150, 1157:1188, 1195:1225, 1232:1261, 1268:1298, 1305:1333, 1340:1373, 1380:1403, 1410:1432, 1439:1469, 1476:1509, 1516:1552, 1559:1584, 1591:1622, 1629:1656, 1663:1695, 1702:1734, 1741:1766, 1773:1803, 1810:1845, 1852:1887, 1894:1927, 1934:1968, 1975:2003, 2010:2037, 2044:2077, 2084:2110, 2117:2145, 2152:2182];

        labelnames = regressor_names(1,beta_indices);

        if length(beta_indices) ~= length(labelnames)
            error('标签数量与 beta 文件数量不匹配');
        end

        cfg.files.name = {};
        for i_label = 1:length(labelnames)
            cfg.files.name{i_label, 1} = fullfile(beta_loc, sprintf('beta_%04i.nii', beta_indices(i_label)));
        end
        cfg.files.label = (1:length(labelnames))';
        cfg.files.chunk = [repelem(1, length(1:32))'; repelem(2, length(39:71))'; ...
        repelem(3, length(78:117))'; repelem(4, length(124:147))';...
        repelem(5, length(154:177))'; repelem(6, length(184:216))';...
        repelem(7, length(223:252))'; repelem(8, length(259:285))';...
        repelem(9, length(292:312))'; repelem(10, length(319:344))';...
        repelem(11, length(351:392))'; repelem(12, length(399:438))';...
        repelem(13, length(445:468))'; repelem(14, length(475:502))';...
        repelem(15, length(509:540))'; repelem(16, length(547:578))';...
        repelem(17, length(585:614))'; repelem(18, length(621:651))';...
        repelem(19, length(658:684))'; repelem(20, length(691:714))';...
        repelem(21, length(721:754))'; repelem(22, length(761:790))';...
        repelem(23, length(797:823))'; repelem(24, length(830:860))';...
        repelem(25, length(867:898))'; repelem(26, length(905:928))';...
        repelem(27, length(935:962))'; repelem(28, length(969:1001))';...
        repelem(29, length(1008:1038))'; repelem(30, length(1045:1066))';...
        repelem(31, length(1073:1113))'; repelem(32, length(1120:1150))';...
        repelem(33, length(1157:1188))'; repelem(34, length(1195:1225))';...
        repelem(35, length(1232:1261))'; repelem(36, length(1268:1298))';...
        repelem(37, length(1305:1333))'; repelem(38, length(1340:1373))';...
        repelem(39, length(1380:1403))'; repelem(40, length(1410:1432))';...
        repelem(41, length(1439:1469))'; repelem(42, length(1476:1509))';...
        repelem(43, length(1516:1552))'; repelem(44, length(1559:1584))';...
        repelem(45, length(1591:1622))'; repelem(46, length(1629:1656))';...
        repelem(47, length(1663:1695))'; repelem(48, length(1702:1734))';...
        repelem(49, length(1741:1766))'; repelem(50, length(1773:1803))';...
        repelem(51, length(1810:1845))'; repelem(52, length(1852:1887))';...
        repelem(53, length(1894:1927))'; repelem(54, length(1934:1968))';...
        repelem(55, length(1975:2003))'; repelem(56, length(2010:2037))';...
        repelem(57, length(2044:2077))'; repelem(58, length(2084:2110))';...
        repelem(59, length(2117:2145))';...
        repelem(60, length(2152:2182))' ];

        cfg.decoding.software = 'similarity';
        cfg.decoding.method = 'classification';
        cfg.decoding.train.classification.model_parameters = corr_type;
        cfg.results.output = 'other';
        cfg.verbose = 0;

        cfg.design = make_design_similarity(cfg);
        results = decoding(cfg);

        dissimilarity_matrix = 1 - results.other.output{1};
        FrontalInf_results = dissimilarity_matrix;

        disp('Dissimilarity Matrix:');
        disp(dissimilarity_matrix);

        figure;
        imagesc(dissimilarity_matrix);
        colorbar;
        title(['Dissimilarity Matrix: ' ' Sub' num2str(subdir(i), '%.2d') ' ' ROIs{j}]);
        xlabel('Conditions');
        ylabel('Conditions');

        image_save_path = fullfile(cfg.results.dir, 'dissimilarity_matrix.jpg');

        saveas(gcf, image_save_path);
        close(gcf);

        mat_save_path = fullfile(cfg.results.dir, 'dissimilarity_matrix.mat');

        save(mat_save_path, 'dissimilarity_matrix');
    end
end