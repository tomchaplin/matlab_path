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
	else
		% We prepend these with pfl_
		% So that they are note affected by workspace
		% Not sure if necessary?
		pfl_workingOn = ones(1, num_iterators);
	end
	% Start the work loop
	while ~isa(pfl_workingOn,'char')
		% Do the work
		zippedWorkingOn = [1:num_iterators; pfl_workingOn];
		zippedWorkingOn = zippedWorkingOn(:);
		argStr = sprintf('varargin{%d}(%d),', zippedWorkingOn);
		argStr = argStr(1:end-1);
		workSnippet = append('f(',argStr,')');
		outputOfWork = eval(workSnippet);
		% Save work to file
		workStr = join(split(num2str(pfl_workingOn)),'_');
		workStr = workStr{1};
		thisWorksFilename = append(identifier,'__',workStr,'.mat');
		save(thisWorksFilename,'outputOfWork');
		% Get next work and save progress
		pfl_workingOn = getNextWork(pfl_workingOn, iterator_sizes);
		save(filename, 'pfl_workingOn');
		% Report
		fprintf('Finished %s\n', workStr)
	end
	fprintf('Rejoining save files, please do not abort!\n')
	% Rejoin save files
	pfl_workingOn = ones(1, num_iterators);
	pfl_output = cell(iterator_sizes);
	while ~isa(pfl_workingOn,'char')
		workStr = join(split(num2str(pfl_workingOn)),'_');
		workStr = workStr{1};
		thisWorksFilename = append(identifier,'__',workStr,'.mat');
		load(thisWorksFilename,'outputOfWork');
		% Store the work
		idx_str = sprintf('%d,', pfl_workingOn);
		idx_str = idx_str(1:end-1);
		storageSnippet = append('pfl_output{', idx_str, '} = outputOfWork;');
		eval(storageSnippet);
		% Delete save file
		delete(thisWorksFilename);
		% Get next work
		pfl_workingOn = getNextWork(pfl_workingOn, iterator_sizes);
	end
	% Clean up persistence file
	delete(filename)
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
