classdef fmri_dataset
    properties
        subjects
        behavDir
        behavFilt
        boldDir
        boldFilt
        anatDir
        anatFilt
        maskDir
        maskFilt
        exclusionTbl
        units
        TR
        derivspath
    end
    properties(Dependent)
        sessions
        behavFiles
        boldFiles
        anatFiles
        maskFiles
    end
    methods
        function obj = fmri_dataset(varargin)
            switch varargin{1}
                case 'auto'

                    % BIDS formatted dataset
                    root = varargin{2};

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

                    obj.subjects   = {BIDS.subjects.name}';
                    obj.behavDir   = root;
                    obj.behavFilt  = '.*_events.tsv$';
                    obj.boldDir    = root;
                    obj.boldFilt   = '.*_bold\.nii$';
                    obj.anatDir    = root;
                    obj.anatFilt   = '_T1w\.nii$';
                    obj.maskDir    = root;
                    obj.maskFilt   = '.*_mask\.nii$';

                case 'manual'

                    [subjects, bDir, bFilt, iDir, iFilt, maskDir, maskFilt, exclusionTbl] = varargin{2:end};
                    obj.subjects   = subjects;
                    obj.behavDir   = bDir;
                    obj.behavFilt  = bFilt;
                    obj.boldDir    = iDir;
                    obj.boldFilt   = iFilt;
                    obj.maskDir    = maskDir;
                    obj.maskFilt   = maskFilt;
                    obj.exclusionTbl = exclusionTbl;

            end
        end
        function value = get.behavFiles(obj)
            value = cellstr(spm_select('FPListRec', obj.behavDir, obj.behavFilt));
        end
        function value = get.boldFiles(obj)
            value = cellstr(spm_select('ExtFPListRec', obj.boldDir, obj.boldFilt));
        end
        function value = get.anatFiles(obj)
            value = cellstr(spm_select('FPListRec', obj.anatDir, obj.anatFilt));
        end
        function value = get.maskFiles(obj)
            value = cellstr(spm_select('FPListRec', obj.maskDir, obj.maskFilt));
        end
        function value = get.sessions(obj)
            value = unique(regexp(obj.boldFiles, 'ses-[0-9]?[0-9]', 'match', 'once'))';
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