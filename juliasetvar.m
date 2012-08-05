function juliasetvar(socket, varname, varvalue)
  % juliasetvar: set a variable within a Julia session
  %
  % This defines a variable within a running Julia session
  %
  % Syntax:
  %   juliasetvar(socket, varname, varvalue)
  % where
  %    socket is the ZeroMQ socket used to communicate with the Julia
  %      server (see juliastart)
  %    varname is the name of the new variable you want to define
  %    varvalue is the value you want to assign to it
  %
  % Examples:
  %    A = randn(4,4);
  %    juliasetvar(socket, 'B', A);
  %
  % To get the value of a variable, use
  %    C = juliaparse(socket, 'B');
  % and you can check the result:
  %    isequal(C, A)
  %
  % See also: juliaparse, juliacall, juliastart.
  
  % Copyright 2012 by Timothy E. Holy
  
  if ~isa(socket, 'uint32') && ~isa(socket, 'uint64')
    error('First input must be the socket');
  end
  if ~ischar(varname)
    error('Second input must be the name of a variable');
  end
  % Serialize the command
  expr = juliaserialize('ser', juliatype('Expr', juliatype(':(=)'), juliatype('Symbol', varname), varvalue));

  % Send the command to Julia, and receive the reply  
  retser = zmq_exec(socket, expr);
  
  % Deserialize the reply
  varargout = juliaserialize('deser', retser);
  if isempty(varargout)
    if nargout > 0
      error('This command did not produce any output, but you asked for one or more outputs. The Julia command itself ran without errors.');
    end
  elseif ~iscell(varargout)
    varargout = {varargout};
  end
end
