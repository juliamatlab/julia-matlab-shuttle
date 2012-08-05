% zmq_exec: send a command to a ZMQ server, and receive the reply
%
% Syntax:
%   reply = zmq_exec(socket, request)
% where
%   socket is the ZMQ socket, created by zmq_connect;
%   request is an array of bytes (uint8), a serialized message to be sent
%     to the server
% and
%   reply is an array of bytes (uint8), the serialized reply from the
%     server.
%
% See also: zmq_connect, julia_serialize.

% Copyright 2012 by Timothy E. Holy
