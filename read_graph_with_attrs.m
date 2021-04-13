function G = read_graph_with_attrs(filename,varargin)
	% Handle options
	directed = ismember('directed', varargin);
	selfloops = ismember('selfloops', varargin);

	% Read atribute file
	attr_filename = sprintf('%s.attrs.csv', filename);
	%disp(attr_filename)
	attrT = readtable(attr_filename);

	% Init graph
	N = height(attrT);
	if directed
		G = digraph();
	else
		G = graph();
	end
	G = addnode(G, N);

	% Add atributes
	num_attrs = length(attrT.Properties.VariableNames);
	for i=2:num_attrs
		attr_name = attrT.Properties.VariableNames{i};
		G.Nodes.(attr_name) = attrT.(attr_name);
	end

	% Add edges
	edgeT = readtable(filename);
	s = edgeT.Var1 + 1;
	t = edgeT.Var2 + 2;
	G = addedge(G, s, t);
	
	% Remove any self loops
	if ~selfloops
		G = rmedge(G, 1:N, 1:N);
	end
end
