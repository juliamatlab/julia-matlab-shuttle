function [socket, stopflag] = juliastart(key, port)
% juliastart: initiate a Julia session and connect to it
%
% This allows you to initialize a connection to Julia. If your connection
% is local, it will start Julia for you. If your connection is remote, you
% need to launch the Julia server manually on the remote machine, but you
% can use this function to initiate the connection between Matlab and
% Julia.
%
% Before you run this for the first time, you need to configure by running
% julia_configure. This only needs to be done once.
%
% Syntax:
%   [socket, stopflag] = juliastart
%   [socket, stopflag] = juliastart(key)
%   [socket, stopflag] = juliastart(key, port)
% where
%   key is a string, defining which server configuration you want to use.
%     It must be one of the configurations that you defined by running
%     julia_configure. Default: 'local', meaning run a julia instance
%     locally, or if there is no local configuration, the first key
%     alphabetically in your configuration file.
%   port is a port number for the connection (default 5555). Switch to a
%     different port if the server complains that the default is already in
%     use.
% and
%   socket is returned from zmq_connect. The socket is used for
%     sending all commands to julia.
%   stopvar is a variable that, when it is cleared (or if it goes out of
%     scope), will cause the Julia session to terminate. Consequently, you
%     need to "hold on" to these variables for the duration of the time you
%     want to use Julia over this socket.
%
% You can terminate the running Julia instance by typing "clear stopflag"
% from the Matlab prompt. Note that the socket variable gets set to 0 by
% this action, indicating that it is no longer valid.
% 
% Note: even though this function returns quickly, Julia will take a few
% seconds to start up. Moreover, the first time a particular command is
% executed, it gets compiled on-the-fly. Consequently, it can take extra
% time for the first execution of a function.
%
% You can execute commands via juliacall and friends.
%
% See also: juliacall, julia_configure.

% Copyright 2012 by Timothy E. Holy

  s = load('juliaconfig');
  if nargin < 1
    key = 'local';
    if ~isKey(s.urlmap, key)
      allkeys = keys(s.urlmap);
      key = allkeys{1};
    end
  end
  url = s.urlmap(key);
  if nargin > 1
    % Replace the default port number with the specified port number
    i = length(url);
    while url(i) ~= ':'
      i = i-1;
    end
    url = [url(1:i) num2str(port)];
  end
  if strcmp(key, 'local')
    cmd = ['bash --login -c "julia -L \"' s.julia_local_server_file '\" -e ''run_server(\"' url '\")''" &'];
    disp(cmd)
    [status, result] = system(cmd);
    if status ~= 0
      error('Error starting julia process: %s', result);
    end
    [ctx, socket] = zmq_connect(url);
    stopflag = onCleanup(@() juliacleanup(ctx, socket));
  else
    [ctx, socket] = zmq_connect(url);
    stopflag = onCleanup(@() zmq_cleanup(ctx, socket));
  end
end

function juliacleanup(ctx, socket)
  juliacall(socket, 'zmqquit');
  zmq_cleanup(ctx, socket);
end
