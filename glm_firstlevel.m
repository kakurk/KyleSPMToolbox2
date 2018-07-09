classdef glm_firstlevel
   properties
       dataset
       name
       dir
       task
       trialtypes
       contrasts
       mask
   end
   properties(Dependent)
       fullpath
       SPMmats
       multiConds
   end
   methods
        function obj = glm(dataset, name, dir, task, trialtypes, contrasts, exclusionTbl)
            obj.dataset      = dataset;
            obj.name         = name;
            obj.dir          = dir;
            obj.task         = task;
            obj.trialtypes   = trialtypes;
            obj.contrasts    = contrasts;
            obj.exclusionTbl = exclusionTbl;
        end
        function value = get.fullpath(obj)
            value = fullfile(obj.dir, obj.name);
        end
        function value = get.multiConds(obj)
            value = spm_select('FPListRec', obj.fullpath, '.*_mutlicond.mat');
        end
        function value = get.SPMmats(obj)
            value = spm_select('FPListRec', obj.fullpath, 'SPM.mat$');
            value = value(~contains(value, 'SecondLevel'));
        end
        function define(obj, subrange)
            % Write out the necessary multiple condition files for a SPM
            % analysis.
            % columns = cell array of the names of the columns that define 
            % the various trial types for this model. These columns must 
            % be logical, such that TRUE = this event belongs in this 
            % trial bin and FALSE = this event DOES NOT belong in this 
            % trial bin.

            % loop over a range of subjects specified as a vector by the
            % user
            for sub = subrange

                % 
                event_tsvs(~contains(event_tsvs, obj.dataset.subjects{sub})) = [];
                event_tsvs(~contains(event_tsvs, obj.task{sub})) = [];
                event_tbls = cellfun(@(x) readtable(x, 'FileType', 'text', 'Delimiter', '\t'), event_tsvs, 'UniformOutput', false);

                % See spm12 manual. Defining multiple conditions files
                names     = [];
                onsets    = [];
                durations = [];

                % over sessions
                for ses = 1:length(event_tbls)
                    curSess = events_tbls(ses);
                    % over trial types
                    for tt = 1:length(obj.trialtypes)
                        belongs_in_current_tt = event_tbls{sub}.(obj.trialtypes{tt});
                        names{tt}     = obj.trialtypes{tt};
                        onsets{tt}    = curSess.onset(belongs_in_current_tt);
                        durations{tt} = curSess.duration(belongs_in_current_tt);
                    end
                    outfilename = sprintf('sub-%s_ses-%02d_multicond.mat', obj.subjects{sub}, ses);
                    save(outfilename, 'names', 'onsets', 'durations')
                end
            end
        end
        function specify(obj, show, run, subrange)
            % show = true = display in GUI
            % MUST "define" the model first

            for s = subrange

                % Specify the first level glm with SPM.
                onsets    = [];
                durations = [];
                names     = [];
                pmod      = [];
                sessions  = unique(regexp(obj.dataset.boldFiles, 'ses-[0-9]?[0-9]', 'match', 'once'))';

                % Directory
                matlabbatch{1}.spm.stats.fmri_spec.dir = {obj.fullpath};

                % Model Parameters
                matlabbatch{1}.spm.stats.fmri_spec.timing.units   = obj.dataset.units;
                matlabbatch{1}.spm.stats.fmri_spec.timing.RT      = obj.dataset.TR;
                matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t  = 16;
                matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0 = 1;

                % Session Specific
                for curRun = 1:length(sessions)
                    subFilt = contains(obj.boldFiles, obj.subjects{s});
                    sesFilt = contains(obj.boldFiles, sessions{curRun});
                    matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).scans = obj.boldFiles(subFilt & sesFilt); %#ok<*AGROW>
                    subFilt = contains(obj.multiConds, obj.subjects{s});
                    sesFilt = contains(obj.multiConds, sessions{curRun}); 
                    if show == 0
                        matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).cond  = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});                       
                        matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).multi = {obj.multiConds(subFilt & sesFilt)};
                    elseif show == 1
                        load(obj.multiConds(subFilt & sesFilt))
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
                    matlabbatch{1}.spm.stats.fmri_spec.sess(curRun).multi_reg = {Model.runs{curRun}.motion};
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

                SPMmat = obj.SPMmats(contains(obj.SPMmats), obj.subjects{s});
                matlabbatch{1}.spm.stats.fmri_est.spmmat = SPMmat;
                matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
                matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
                spm_jobman('run', matlabbatch)

            end

        end
        function run_cons(obj, subrange)
            % run the contrasts
            
        end
   end
   methods(Static)
        function check_for_spm()
            % Check to see if SPM is on the MATLAB searchpath
            if isempty(which('spm'))
                error('SPM is not on the MATLAB search path')
            elseif numel(which('spm')) > 1
                error('Multiple SPMs on the MATLAB search path')
            end
        end       
   end
end