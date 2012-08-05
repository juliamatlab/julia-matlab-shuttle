% zmq_connect: connect via ZeroMQ to a server
%
% Syntax:
%    [context,socket] = zmq_connect(url)
%    [context,socket] = zmq_connect(url, sockettype)
% where
%    url is the url string of the server port, e.g., 'tcp://localhost:5555'
%    sockettype is an integer giving the type of socket you want to connect
%      to (default: ZMQ_REQ)
% and
%    context is the ZMQ context (an unsigned integer representation of a
%      pointer)
%    socket is the ZMQ socket (")
%
% You should keep both variables in-scope for as long as you want to work
% with the server. When done, call zmq_cleanup.
%
% See also: zmq_cleanup, zmq_exec.

% Copyright 2012 by Timothy E. Holy
