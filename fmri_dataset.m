classdef fmri_dataset
    properties
        subjects      = {'sub-01' 'sub-02' 'sub-03'};
        sessions      = {'ses-01' 'ses-02' 'ses-03'}; 
        behavDir      = '/fullpath/to/behavioral/data/';
        behavFilt     = '.*events\.tsv';
        behavFiles    = {''};
        boldDir       = '/fullpath/to/bold/data/';
        boldFilt      = '.*_bold\.nii';
        boldFiles     = {''};
        anatDir       = '/fullpath/to/anat/data';
        anatFilt      = '.*_T1\.nii';
        anatFiles     = '';
        maskDir       = '/fullpath/to/mask/images'
        maskFilt      = '.*_mask\.nii';
        maskFiles     = {''};
        analysisDir   = '';
        censorTbl     = table();
        units         = 'secs';
        TR            = 2;
        derivDir      = '/fullpath/to/derivatives';
        derivFilt     = '^smooth_.*\.nii';
        derivFiles    = {''};
        analyses
    end
    methods
        function obj = fmri_dataset(varargin)

            if ~isempty(varargin)
            
                root = varargin{1};
                
                assert(exist(root, 'dir') == 7, 'BIDS root does not exist')

                % gunzip, if necessary
                if isempty(spm_select('FPListRec', root, '.*\.nii$'))
                    gzippedFiles = spm_select('FPListRec', root, '.*\.nii\.gz');
                    if ~isempty(gzippedFiles)
                        fprintf('gunzipping files...\n\n')
                        gunzip(gzippedFiles)
                    end
                end

                % an SPM tool
                BIDS = spm_BIDS(root);

                obj.subjects   = {BIDS.subjects.name};
                obj.behavDir   = root;
                obj.behavFilt  = '.*_events.tsv$';
                obj.boldDir    = root;
                obj.boldFilt   = '.*_bold\.nii$';
                obj.anatDir    = root;
                obj.anatFilt   = '_T1w\.nii$';
                obj.maskDir    = root;
                obj.maskFilt   = '.*_mask\.nii$';  
                
            end

        end
        function value = get.behavFiles(obj)
            value = cellstr(spm_select('FPListRec', obj.behavDir, obj.behavFilt));
        end
        function value = get.boldFiles(obj)
            value = cellstr(spm_select('ExtFPListRec', obj.boldDir, obj.boldFilt));
        end
        function value = get.derivFiles(obj)
            value = cellstr(spm_select('ExtFPListRec', obj.derivDir, obj.derivFilt));
        end
        function value = get.anatFiles(obj)
            value = cellstr(spm_select('FPListRec', obj.anatDir, obj.anatFilt));
        end
        function value = get.maskFiles(obj)
            value = cellstr(spm_select('FPListRec', obj.maskDir, obj.maskFilt));
        end
        function value = get.sessions(obj)
            value = unique(regexp(obj.boldFiles, 'run-[0-9]?[0-9]', 'match', 'once'))';
            value = value(~cellfun(@isempty, value));
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