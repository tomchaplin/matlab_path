function pfl_output = persForLoop( varargin )
	% Handle args and setup
	if isa(varargin{nargin}, 'char')
		filename = append('__pfl_state__', varargin{nargin}, '.mat');
		f = varargin{nargin - 1};
		num_iterators = nargin - 2;
	else
		filename = '__pfl_state.mat';
		f = varargin{nargin - 1};
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
		pfl_output = cell(iterator_sizes);
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
		% Store the work
		idx_str = sprintf('%d,', pfl_workingOn);
		idx_str = idx_str(1:end-1);
		storageSnippet = append('pfl_output{', idx_str, '} = outputOfWork;');
		eval(storageSnippet);
		% Get next work
		pfl_workingOn = getNextWork(pfl_workingOn, iterator_sizes);
		% Save work and progress to file
		save(filename);
		% Report
		fprintf('Finished %s\n', idx_str)
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
				workingOn = 'finished'
				return
			end
			workingOn(i) = workingOn(i) - iterator_sizes(i);
			workingOn(i-1) = workingOn(i-1) + 1;
		end
	end
end
