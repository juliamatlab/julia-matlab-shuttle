function varargout = juliaparse(socket, str)
  % juliaparse: send operations/programs to be parsed and executed by Julia
  %
  % This function allows Matlab to send a command to a running Julia server
  % and receive the output. This command does not take arguments: it is a
  % pure string, exactly as you would type at the Julia interactive prompt.
  % You can define new Julia functions, load extra modules, run for loops,
  % etc, in this way.
  %
  % Syntax:
  %   [out1, out2, ...] = juliaparse(socket, str)
  % where
  %    socket is the ZeroMQ socket used to communicate with the Julia
  %      server (see juliastart)
  %    str is a string that, for example, you could type into the Julia
  %      command line
  % and
  %    out1, out2 are (possibly) the return values of the function.
  %
  % Examples:
  %    xs = juliaparse(socket, 'x = randn(7); sort(x)')
  %    juliaparse(socket, 'load("glpk.jl")')
  %    juliaparse(socket, 'fib(n) = n < 2 ? n : fib(n-1) + fib(n-2)')
  % The latter defines the Fibonacci function in Julia, which you can then
  % use like this:
  %    f = juliacall(socket, 'fib', 25)  % computes 25th Fibonacci number
  % It is instructive to compare the speed of the latter against the
  % following Matlab version:
  %   function f = fib(n)
  %     if n < 2
  %       f = n;
  %       return
  %     else
  %       f = fib(n-1) + fib(n-2);
  %     end
  %   end
  %
  % See also: juliacall, juliasetvar, juliastart.
  
  % Copyright 2012 by Timothy E. Holy
  
  if ~isa(socket, 'uint32') && ~isa(socket, 'uint64')
    error('First input must be the socket');
  end
  if ~ischar(str)
    error('Second input must be a command');
  end
  % Serialize the command
  expr = juliaserialize('ser', juliatype('Expr', juliatype(':call'), juliatype('Symbol', 'parse_eval'), juliatype('ASCIIString', str)));

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
