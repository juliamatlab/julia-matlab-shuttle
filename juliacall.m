function varargout = juliacall(socket, cmd, varargin)
  % juliacall: run a Julia function on Matlab variables, and return the result
  %
  % This function allows Matlab to send a command to a running Julia server
  % and receive the output. The arguments to the command come from Matlab,
  % not internal variables in the Julia server session. Consequently, it
  % allows you to run Julia functions on Matlab variables.
  %
  % Syntax:
  %   [out1, out2, ...] = juliacall(socket, cmd, in1, in2, ...)
  % where
  %    socket is the ZeroMQ socket used to communicate with the Julia
  %      server (see juliastart)
  %    cmd is a string, the name of the Julia function you want to run
  %    in1, in2, ... are the argument values you want to pass to that
  %      function
  % and
  %    out1, out2 are the return values of the function.
  %
  % Examples:
  %    val = juliacall(socket, 'sin', pi/4)
  %    A = juliacall(socket, 'randn', 3, 5)
  %    A = juliacall(socket, 'randn', juliatype('Tuple', 3, 5))
  %    A = randn(4,2)
  %    Aabs = juliacall(socket, 'abs', A)
  % These correspond to Julia commands
  %    val = sin(pi/4)
  %    A = randn(3, 5)
  %    A = randn((3, 5)) # the tuple form of the above (equivalent)
  %    Aabs = abs(A)
  %
  % See also: juliaparse, juliasetvar, juliatype, juliastart.
  
  % Copyright 2012 by Timothy E. Holy
  
  if ~isa(socket, 'uint32') && ~isa(socket, 'uint64')
    error('First input must be the socket');
  end
  if ~ischar(cmd)
    error('Second input must be a command');
  end
  % Serialize the command and the arguments
  sym = juliatype('Symbol', cmd);
  % Put this into an expression
  expr = juliaserialize('ser', juliatype('Expr', juliatype(':call'), sym, varargin{:}));

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
