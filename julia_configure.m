function julia_configure
  % Configure interaction between Matlab and Julia
  %
  % This configures Matlab to be able to call out to Julia. For
  % across-network interaction, you need to manually start Julia on the
  % remote server.
  %
  % This only needs to be run once. Afterwards, juliastart should work
  % properly. If not:
  %   1. Check that the julia executable is on the system PATH
  %   2. Check that you've saved the "juliaconfig.mat" file somewhere on
  %      your Matlab path
  %   3. Check that you've used correct settings for the local and/or
  %      remote servers.
  %
  % See also: juliastart.
  
  % Copyright 2012 by Timothy E. Holy
  
  key = {};
  url = {};
  julia_local_server_file = '';
  button = questdlg('Do you want to configure a local Julia instance? Do this only if Julia is installed on this machine.');
  switch button
    case 'Cancel'
      return
    case 'Yes'
      [filename,pathname] = uigetfile('*.jl', 'Find the julia server program you want to run (presumably, the file zmq_server_julia');
      if ~isequal(filename, 0)
        julia_local_server_file = [pathname filename];
        key{end+1} = 'local';
        urlstr = 'tcp://*';
        answer = inputdlg('Port number (e.g., 5555)', 'Default port for local connection', 1);
        if isempty(answer)
          url{end+1} = [urlstr ':5555'];
        else
          url{end+1} = [urlstr ':' answer{1}];
        end
      end
  end
  while true
    answer = inputdlg({'Key (e.g., server1)', 'URL (e.g., tcp://server1.myuniversity.edu)', 'Default port (e.g., 5555)'}, 'Configure next remote server', 1);
    if isempty(answer)
      break
    else
      key{end+1} = answer{1};
      url{end+1} = [answer{2} ':' answer{3}];
    end
  end
  urlmap = containers.Map(key, url);
  
  pathname = uigetdir(pwd, 'Pick a directory on your Matlab path to save the configuration file');
  save([pathname filesep 'juliaconfig'], 'urlmap', 'julia_local_server_file');
end
