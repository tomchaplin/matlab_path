function pfl_output = persForLoopSplitSaves( varargin )
    % Handle args and setup
    if isa(varargin{nargin}, 'char')
        identifier = append('__pfl_state__', varargin{nargin});
        filename = append(identifier, '.mat');
        f = varargin{nargin - 1};
        num_iterators = nargin - 2;
    else
        identifier = '__pfl_state';
        filename = append(identifier, '.mat');
        f = varargin{nargin};
        num_iterators = nargin - 1;
    end
    iterator_sizes = cellfun(@(x) length(x) , varargin(1:num_iterators));
    if ~isa(f, 'function_handle')
        err(append('Expected function_handle, received ', class(f)))
    end
    % Check for existing state
    if isfile(filename)
        load(filename)
        % Load up previous state of rng
        rng(pfl_rng);
    else
        % We prepend these with pfl_
        % So that they are note affected by workspace
        % Not sure if necessary?
        pfl_workingOn = ones(1, num_iterators);
        pfl_rng = rng;
    end
    % Start the work loop
    while ~isa(pfl_workingOn,'char')
        % Do the work
        workSnippet = getWorkSnippet(num_iterators, pfl_workingOn);
        outputOfWork = eval(workSnippet);
        % Save work to file
        thisWorksFilename = getWorkFilename(pfl_workingOn, identifier);
        save(thisWorksFilename,'outputOfWork');
        % Get next work and save progress
        pfl_workingOn = getNextWork(pfl_workingOn, iterator_sizes);
        pfl_rng = rng;
        save(filename, 'pfl_workingOn', 'pfl_rng');
        % Report
        workStr = getWorkStr(pfl_workingOn);
        fprintf('Finished %s\n', workStr)
    end
    fprintf('Rejoining save files, please do not abort!\n')
    % Rejoin save files
    pfl_workingOn = ones(1, num_iterators);
    pfl_output = cell(iterator_sizes);
    while ~isa(pfl_workingOn,'char')
    thisWorksFilename = getWorkFilename(pfl_workingOn, identifier);
        load(thisWorksFilename,'outputOfWork');
        % Store the work
        storageSnippet = getStorageSnippet(pfl_workingOn);
        eval(storageSnippet);
        % Get next work
        pfl_workingOn = getNextWork(pfl_workingOn, iterator_sizes);
    end
    fprintf('Deleting save files, please do not abort!\n')
    % Clean up split saves
    pfl_workingOn = ones(1, num_iterators);
    pfl_output = cell(iterator_sizes);
    while ~isa(pfl_workingOn,'char')
        thisWorksFilename = getWorkFilename(pfl_workingOn, identifier);
            delete(thisWorksFilename);
      end
    % Clean up persistence file
    delete(filename)
end

function snippet = getWorkSnippet(num_iterators, workingOn)
    zippedWorkingOn = [1:num_iterators; workingOn];
    zippedWorkingOn = zippedWorkingOn(:);
    argStr = sprintf('varargin{%d}(%d),', zippedWorkingOn);
    argStr = argStr(1:end-1);
    snippet = append('f(',argStr,')');
end

function workStr = getWorkStr(workingOn)
    workStr = join(split(num2str(workingOn)),'_');
    workStr = workStr{1};
end

function worksFilename = getWorkFilename(workingOn, identifier)
    workStr = getWorkStr(workingOn);
    worksFilename = append(identifier,'__',workStr,'.mat');
end

function snippet = getStorageSnippet(workingOn)
    idx_str = sprintf('%d,', workingOn);
    idx_str = idx_str(1:end-1);
    snippet = append('output{', idx_str, '} = outputOfWork;');
end

function workingOn = getNextWork(workingOn, iterator_sizes)
    workingOn(end) = workingOn(end) + 1;
    for i=length(iterator_sizes):(-1):1
        if workingOn(i) > iterator_sizes(i)
            if i == 1
                % We've done all the work
                workingOn = 'finished';
                return
            end
            workingOn(i) = workingOn(i) - iterator_sizes(i);
            workingOn(i-1) = workingOn(i-1) + 1;
        end
    end
end
