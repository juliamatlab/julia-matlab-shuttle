classdef juliatype
  % juliatype: explicitly specify the Julia type corresponding to matlab variable(s)
  %
  % You only need the constructor:
  %   jlt = juliatype(juliatypename, args...)
  % where
  %   juliatypename is the name of a Julia type,
  %   args is a list of variables
  % and
  %   jlt "wraps" the args in a way that specifies to juliaserialize how to
  %     encode these inputs.
  %
  % Example:
  %   A = juliacall(socket, 'randn', juliatype('Tuple', 3, 5))
  % would make a 3-by-5 random matrix, equivalent to the Julia command
  %   A = randn((3,5))
  %
  % See also: juliacall, juliaserialize.
  
  % Copyright 2012 by Timothy E. Holy
  
  properties (Access = public)
    type
    args
  end
  methods
    function obj = juliatype(t, varargin)
      obj.type = t;
      obj.args = varargin;
    end
  end
end
