classdef glm_firstlevel
   properties
       name
       dir
       task
       trialtypes    = struct('name', '', 'filter', @(x) x)
       contrasts     = struct('name', '', 'positive', '', 'negative', '')
       mask
       subjects      = {'sub-01' 'sub-02' 'sub-03'};
       sessions      = {'ses-01' 'ses-02' 'ses-03'};
       behavFiles    = {''};
       derivFiles    = {''};
       derivDir      = '';
       maskFiles     = {''};
       exclusionTbl  = table();
       units         = 'seconds';
       TR            = 2;
   end
   properties(Dependent)
       fullpath
       SPMmats
       multiRegs
       multiConds
   end
   methods
        function obj = glm_firstlevel(dataset)
            if isa(dataset, 'fmri_dataset')
                obj.dir          = dataset.analysisDir;
                obj.subjects     = dataset.subjects;
                obj.sessions     = dataset.sessions;
                obj.behavFiles   = dataset.behavFiles;
                obj.derivDir     = dataset.derivDir;
                obj.derivFiles   = dataset.derivFiles;
                obj.maskFiles    = dataset.maskFiles;
                obj.exclusionTbl = dataset.exclusionTbl;
                obj.units        = dataset.units;
                obj.TR           = dataset.TR;
            end
        end
        function value = get.fullpath(obj)
            value = fullfile(obj.dir, obj.name);
        end
        function value = get.multiConds(obj)
            value = cellstr(spm_select('FPListRec', obj.fullpath, '.*_multicond\.mat'));
        end
        function value = get.SPMmats(obj)
            value = spm_select('FPListRec', obj.fullpath, 'SPM.mat$');
            if isempty(value)
                return
            end
            value = cellstr(value);
            value = value(~contains(value, 'SecondLevel'));
        end
        function value = get.multiRegs(obj)
            value = spm_select('FPListRec', obj.derivDir, '^rp_.*\.txt$');
        end
        function define(obj, subrange)
            % Write out the necessary multiple condition files for a SPM
            % analysis.
            % columns = cell array of the names of the columns that define 
            % the various trial types for this model. These columns must 
            % be logical, such that TRUE = this event belongs in this 
            % trial bin and FALSE = this event DOES NOT belong in this 
            % trial bin.
            
            event_tsvs = obj.behavFiles;
    
            % loop over a range of subjects specified as a vector by the
            % user
            for sub = subrange
                
                % Has this subject already been run?
                if ~isempty(obj.multiConds(contains(obj.multiConds, obj.subjects{sub})))
                    fprintf('Subject %s has already been defined for this model ... \n\n', obj.subjects{sub})
                    continue
                end
                
                fprintf('Defining Subject %s ... \n\n', obj.subjects{sub})

                if ~exist(fullfile(obj.fullpath, obj.subjects{sub}), 'dir')
                    mkdir(fullfile(obj.fullpath, obj.subjects{sub}))
                end
                
                % 
                event_tsvs(~contains(event_tsvs, obj.subjects{sub})) = [];
                event_tsvs(~contains(event_tsvs, obj.task)) = [];
                event_tbls = cellfun(@(x) readtable(x, 'FileType', 'text', 'Delimiter', '\t'), event_tsvs, 'UniformOutput', false);

                % See spm12 manual. Defining multiple conditions files
                names     = [];
                onsets    = [];
                durations = [];

                % over sessions
                for ses = 1:length(event_tbls)
                    curSess = event_tbls{ses};
                    % over trial types
                    for tt = 1:length(obj.trialtypes)
                        belongs_in_current_tt = obj.trialtypes(tt).filter(curSess);
                        names{tt}     = obj.trialtypes(tt).name;
                        onsets{tt}    = curSess.onset(belongs_in_current_tt);
                        durations{tt} = curSess.duration(belongs_in_current_tt);
                    end
                    outfilename = sprintf('sub-%s_ses-%02d_multicond.mat', obj.subjects{sub}, ses);
                    outfile = fullfile(obj.fullpath, obj.subjects{sub}, outfilename);
                    save(outfile, 'names', 'onsets', 'durations')
                end
            end
        end
        function specify(obj, show, run, subrange)
            % show = true = display in GUI
            % MUST "define" the model first
            
            boldFiles = obj.derivFiles;
            boldFiles(~contains(boldFiles, obj.task)) = []; % remove other tasks

            for s = subrange
                
                % Has this subject already been run?
                if ~isempty(obj.SPMmats(contains(obj.SPMmats, obj.subjects{s})))
                    fprintf('This model has already been specified for Subject %s ... \n\n', obj.subjects{s})
                    continue
                end

                % Specify the first level glm with SPM.
                onsets    = [];
                durations = [];
                names     = [];
                pmod      = [];
                runs      = unique(regexp(boldFiles, 'run-[0-9]?[0-9]', 'match', 'once'))';
                if isempty(char(runs))
                    runs = unique(regexp(boldFiles, 'ses-[0-9]?[0-9]', 'match', 'once'))';
                end

                % Directory
                matlabbatch{1}.spm.stats.fmri_spec.dir = cellstr(fullfile(obj.fullpath, obj.subjects{s}));

                % Model Parameters
                matlabbatch{1}.spm.stats.fmri_spec.timing.units   = obj.units;
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT      = obj.TR;
                matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = 16;
                matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;

                % Session Specific
                for curRun = 1:length(runs)
                    
                    subFilt = contains(boldFiles, obj.subjects{s});
                    runFilt = contains(boldFiles, runs{curRun});
                    matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).scans = boldFiles(subFilt & runFilt); %#ok<*AGROW>
                    
                    subFilt = contains(obj.multiConds, obj.subjects{s});
                    runFilt = contains(obj.multiConds, runs{curRun}); 
                    if ~show
                        matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond  = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});                       
                        matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).multi = cellstr(obj.multiConds(subFilt & runFilt));
                    elseif show
                        load(obj.multiConds{subFilt & runFilt})
                        for curTrialType = 1:length(names)
                            matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).name     = names{curTrialType};
                            matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).onset    = onsets{curTrialType};
                            matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).duration = durations{curTrialType};
                            matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).tmod     = 0;
                            if isempty(pmod)
                                matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).pmod = struct('name', {}, 'param', {}, 'poly', {});
                            else
                                matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).pmod.name  = pmod(curTrialType).name{1};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).pmod.param = pmod(curTrialType).param{1};
                                matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond(curTrialType).pmod.poly  = pmod(curTrialType).poly{1};
                            end
                        end
                    end
                    matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).regress   = struct('name', {}, 'val', {});
                    
                    subFilt = contains(obj.multiRegs, obj.subjects{s});
                    runFilt = contains(obj.multiRegs, runs{curRun});
                    matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).multi_reg = cellstr(obj.multiRegs(subFilt & runFilt));
                    
                    matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).hpf       = 128;
                end

                % Misc
                matlabbatch{1}.spm.stats.fmri_spec.fact = struct('name', {}, 'levels', {});
                matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
                matlabbatch{1}.spm.stats.fmri_spec.volt = 1;
                matlabbatch{1}.spm.stats.fmri_spec.global = 'None';
                if ~isempty(obj.mask)
                    matlabbatch{1}.spm.stats.fmri_spec.mask = {obj.mask};
                else
                    matlabbatch{1}.spm.stats.fmri_spec.mask = {''};
                end
                matlabbatch{1}.spm.stats.fmri_spec.cvi = 'AR(1)';

                if run
                    spm_jobman('run', matlabbatch);
                else
                    spm_jobman('interactive', matlabbatch);
                    input('Enter to continue: ')
                end

            end

        end
        function inspect(obj, srange)
            % display the design matrix for subject in a specific range
            %   range = 1:5;   --> subjects 1 - 5
            %   range = 1;     --> subject 1 only
            %   range = 20:25; --> subject 20 through 25.
            SPM = [];
            for r = srange
                load(fullfile(obj.fullpath, obj.subjects{r}, 'SPM.mat'))
                fprintf('This is subject %s ''s design matrix.\n\n', obj.subjects{r})
                spm_DesRep('DesMtx', SPM.xX, SPM.xY.P)
                input('Press enter to continue: ')
            end
        end
        function estimate(obj, subrange)
            % Estimate the first level glm with SPM.

            for s = subrange
                
                % This subject's SPMmat file
                SPMmat = obj.SPMmats(contains(obj.SPMmats, obj.subjects{s}));
                
                SPM = [];
                load(char(SPMmat));
                
                try
                    SPM.xVol.S;
                    fprintf('This model has already been estimated for Subject %s \n\n', obj.subjects{s});
                    continue
                catch
                end
                
                % matlabbatch. See SPM12 manual
                matlabbatch{1}.spm.stats.fmri_est.spmmat           = SPMmat;
                matlabbatch{1}.spm.stats.fmri_est.write_residuals  = 0;
                matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
                
                % spm_jobman. See SPM12 manual
                spm_jobman('run', matlabbatch)

            end

        end
        function runcons(obj, subrange)
            % run the contrasts
            
            if isempty(obj.contrasts)
                error('Define contrasts')
            end
            
            for s = subrange
                
                SPM = [];
                SPMmat = obj.SPMmats(contains(obj.SPMmats, obj.subjects{s}));
                if iscellstr(SPMmat)
                    SPMmat = char(SPMmat);
                end
                load(SPMmat);
                
                if ~isempty(SPM.xCon)
                    fprintf('There already appears to be contrasts defined for subject %s\n\n', obj.subjects{s})
                    continue
                end
                
                estimateability = spm_SpUtil('isCon',SPM.xX.X);
                
                matlabbatch{1}.spm.stats.con.spmmat = cellstr(SPMmat);
                
                count = 0;
                
                for c = 1:length(obj.contrasts)
                    
                    % find the columns of the design matrix that have the
                    % positive side of the contrast in its name AND are
                    % able to be estimated
                    isemptycellstr = @(x) isempty(x{:});
                    if isemptycellstr(obj.contrasts(c).positive)
                        pos    = false(1, length(SPM.xX.name));
                    else
                        pos    = contains(SPM.xX.name, obj.contrasts(c).positive) & estimateability;
                        pos    = pos / length(find(pos));   
                    end
                    if isemptycellstr(obj.contrasts(c).negative)
                        neg    = false(1, length(SPM.xX.name));
                    else
                        neg    = contains(SPM.xX.name, obj.contrasts(c).negative) & estimateability;
                        neg    = - neg / length(find(neg));
                    end
                    
                    % if you don't find any, skip
                    if ~any(pos) && ~any(neg)
                        continue
                    end
                    
                    % wieght by the number of columns; combine to form
                    % contrast vector
                    
                    convec = pos + neg;
                    
                    count  = count + 1;
                    
                    matlabbatch{1}.spm.stats.con.consess{count}.tcon.name    = char(obj.contrasts(c).name);
                    matlabbatch{1}.spm.stats.con.consess{count}.tcon.weights = convec;
                    matlabbatch{1}.spm.stats.con.consess{count}.tcon.sessrep = 'none';
                    
                end
                matlabbatch{1}.spm.stats.con.delete = 1;
                spm_jobman('run', matlabbatch);
                
            end
            
        end
   end
   methods(Static)
        function check_for_spm()    
            % Check to see if SPM is on the MATLAB searchpath
            if isempty(which('spm'))
                error('SPM is not on the MATLAB search path')
            elseif size(which('spm'), 1) > 1
                error('Multiple SPMs on the MATLAB search path')
            end
        end       
   end
end