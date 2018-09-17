%%% Example %%%

%% fMRI dataset
cajalbidsroot = '/Users/kylekurkela/Documents/datasets/CajalMRI_BIDS';
Cajal = fmri_dataset(cajalbidsroot);

Cajal.analysisDir = pwd;
Cajal.derivDir    = cajalbidsroot;
Cajal.derivFilt   = '.*_bold\.nii$';

Cajal.disp();

%% First Level GLM

%%% Faces vs Scenes

Faces_vs_Scenes = glm_firstlevel(Cajal);
Faces_vs_Scenes.name = 'Faces_vs_Scenes';
Faces_vs_Scenes.task = 'TASK';

% trial types
Faces_vs_Scenes.trialtypes(1).name   = 'Faces';
Faces_vs_Scenes.trialtypes(1).filter = @(x) strcmp(x.category, 'face');
Faces_vs_Scenes.trialtypes(2).name   = 'Scenes';
Faces_vs_Scenes.trialtypes(2).filter = @(x) strcmp(x.category, 'scene');

% contrasts
Faces_vs_Scenes.contrasts(1).name     = {'Faces_vs_Baseline'};
Faces_vs_Scenes.contrasts(1).positive = {'Faces'};
Faces_vs_Scenes.contrasts(1).negative = {''};
Faces_vs_Scenes.contrasts(2).name     = {'Scenes_vs_Baseline'};
Faces_vs_Scenes.contrasts(2).positive = {'Scenes'};
Faces_vs_Scenes.contrasts(2).negative = {''};
Faces_vs_Scenes.contrasts(3).name     = {'Scenes_vs_Baseline'};
Faces_vs_Scenes.contrasts(3).positive = {'Faces'};
Faces_vs_Scenes.contrasts(3).negative = {'Scenes'};
Faces_vs_Scenes.contrasts(4).name     = {'Scenes_vs_Baseline'};
Faces_vs_Scenes.contrasts(4).positive = {'Scenes'};
Faces_vs_Scenes.contrasts(4).negative = {'Faces'};

% methods
Faces_vs_Scenes.define(1);
Faces_vs_Scenes.specify(true, true, 1);
Faces_vs_Scenes.estimate(1);
Faces_vs_Scenes.runcons(1);

%%% Famous vs Nonfamous

Famous_vs_Nonfamous = glm_firstlevel(Cajal);
Famous_vs_Nonfamous.name = 'Famous_vs_Nonfamous';
Famous_vs_Nonfamous.task = 'TASK';

% trial types
Famous_vs_Nonfamous.trialtypes(1).name   = 'Famous';
Famous_vs_Nonfamous.trialtypes(1).filter = @(x) strcmp(x.fame, 'yes');
Famous_vs_Nonfamous.trialtypes(2).name   = 'Nonfamous';
Famous_vs_Nonfamous.trialtypes(2).filter = @(x) strcmp(x.fame, 'no');

% contrasts
Famous_vs_Nonfamous.contrasts(1).name     = {'Famous'};
Famous_vs_Nonfamous.contrasts(1).positive = {'Famous'};
Famous_vs_Nonfamous.contrasts(1).negative = {''};
Famous_vs_Nonfamous.contrasts(2).name     = {'Nonfamous'};
Famous_vs_Nonfamous.contrasts(2).positive = {'Nonfamous'};
Famous_vs_Nonfamous.contrasts(2).negative = {''};
Famous_vs_Nonfamous.contrasts(3).name     = {'Famous_vs_NonFamous'};
Famous_vs_Nonfamous.contrasts(3).positive = {'Famous'};
Famous_vs_Nonfamous.contrasts(3).negative = {'Nonfamous'};
Famous_vs_Nonfamous.contrasts(4).name     = {'Nonfamous_vs_Famous'};
Famous_vs_Nonfamous.contrasts(4).positive = {'Nonfamous'};
Famous_vs_Nonfamous.contrasts(4).negative = {''};

% methods
Famous_vs_Nonfamous.define(1);
Famous_vs_Nonfamous.specify(true, true, 1);
Famous_vs_Nonfamous.estimate(1);
Famous_vs_Nonfamous.runcons(1);