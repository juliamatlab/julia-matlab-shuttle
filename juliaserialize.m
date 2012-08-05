function varargout = juliaserialize(mode, arg)
  % juliaserialize: encode/decode Julia expressions as a packed array of bytes
  %
  % This uses the protocol defined by the native Julia serializer
  % (serialize.jl) to communicate over the wire. In general you don't call
  % this directly, it is used by juliacall and friends.
  %
  % See also: juliacall, juliatype.
  
  % Copyright 2012 by Timothy E. Holy
  
  %% The Julia-Matlab dictionary
  % Some of these functions are not defined, but at least that will help
  % give a more specific error. It's not clear what to do about types like
  % Int128 that are not available in Matlab.
  persistent jl_ser_fun jl_deser_fun jl_ser_encode mat_ser_decode mat_cast jl_type icoded ioffset jl_fieldnames jl_struct_action
  if isempty(jl_ser_fun)
    jl_ser_table = {...
      'Symbol', '', @jl_ser_symbol, @jl_deser_symbol, 2; ...
      'Int8', 'int8', @jl_ser_array, @jl_deser_scalar, 3; ...
      'Uint8', 'uint8', @jl_ser_array, @jl_deser_scalar, 4; ...
      'Int16', 'int16', @jl_ser_array, @jl_deser_scalar, 5; ...
      'Uint16', 'uint16', @jl_ser_array, @jl_deser_scalar, 6; ...
      'Int32', 'int32', @jl_ser_array, @jl_deser_scalar, 7; ...
      'Uint32', 'uint32', @jl_ser_array, @jl_deser_scalar, 8; ...
      'Int64', 'int64', @jl_ser_array, @jl_deser_scalar, 9; ...
      'Uint64', 'uint64', @jl_ser_array, @jl_deser_scalar, 10; ...
      'Int128', '', @jl_ser_bigint, @jl_deser_bigint, 11; ...
      'Uint128', '', @jl_ser_bigint, @jl_deser_bigint, 12; ...
      'Float32', 'single', @jl_ser_array, @jl_deser_scalar, 13; ...
      'Float64', 'double', @jl_ser_array, @jl_deser_scalar, 14; ...
      'Char', 'char', @jl_ser_string, @jl_deser_char, 15; ...
      'CompositeKind', '', @jl_ser_struct, @jl_deser_struct, 20; ...
      'Tuple', '', @jl_ser_tuple, @jl_deser_tuple, 22; ...
      'Array', '', @jl_ser_array, @jl_deser_array, 23; ...
      'Expr', '', @jl_ser_expr, @jl_deser_expr, 24; ...
      'LongSymbol', '', @jl_ser_symbol, @jl_deser_longsymbol, 25; ...
      'LongTuple', '', @jl_ser_tuple, @jl_deser_longtuple, 26; ...
      'LongExpr', '', @jl_ser_expr, @jl_deser_longexpr, 27; ...
      '()', '', @jl_lookup, @jl_deser_empty, 49; ...
      'Any', '', [], [], 51; ...
      ':call', '', @jl_lookup, @jl_deser_call, 63; ...
      ':(=)', '', @jl_lookup, @jl_deser_assign, 65; ...
      'nothing', [], @jl_lookup, @jl_deser_empty, 127; ...
      'ASCIIString', 'char', @jl_ser_string, @jl_deser_char, [];...
      };
    % The integer codes
    icoded = 0:32;
    ioffset = 128;
    
    jltypes = jl_ser_table(:,1);
    mattypes = jl_ser_table(:,2);
    jlserfun = jl_ser_table(:,3);
    jldeserfun = jl_ser_table(:,4);
    jlcodes = jl_ser_table(:,5);
    ejltypes = cellfun(@isempty,jltypes);
    emattypes = cellfun(@isempty,mattypes);
    ejlserfun = cellfun(@isempty,jlserfun);
    ejldeserfun = cellfun(@isempty,jldeserfun);
    ejlcodes = cellfun(@isempty,jlcodes);
    
    flag = ~(ejltypes | ejlserfun);
    jl_ser_fun = containers.Map(jltypes(flag), jlserfun(flag));
    flag = ~(ejlcodes | ejldeserfun);
    jl_deser_fun = containers.Map(jlcodes(flag), jldeserfun(flag));
    flag = ~(ejltypes | ejlcodes);
    jl_ser_encode = containers.Map(jltypes(flag), jlcodes(flag));
    flag = ~(ejlcodes | emattypes);
    mat_ser_decode = containers.Map(jlcodes(flag), mattypes(flag));
    flag = ~(ejltypes | emattypes);
    mat_cast = containers.Map(jltypes(flag), mattypes(flag));
    jl_type = containers.Map(mattypes(flag), jltypes(flag));
    
    % Definition of important Julia types (i.e., structures)
    % Format of each row:
    %   'typename', {'fieldname1', 'fieldname2', ...}; ...
    err_types = {...
      'ErrorException', {'msg'}; ...
      'SystemError', {'prefix', 'errnum'}; ...
      'TypeError', {'func', 'context', 'expected', 'got'}; ...
      'ParseError', {'msg'}; ...
      'ArgumentError', {'msg'}; ...
      'KeyError', {'key'}; ...
      'LoadError', {'file', 'line', 'error'}; ...
      'MethodError', {'f', 'args'}; ...
      'BoundsError', {}; ...
      'DivideByZeroError', {}; ...
      'DomainError', {}; ...
      'OverflowError', {}; ...
      'InexactError', {}; ...
      'MemoryError', {}; ...
      'IOError', {}; ...
      'StackOverflowError', {}; ...
      'EOFError', {}; ...
      'UndefRefError', {}; ...
      'InterruptException', {}; ...
      };
    jl_types = {...
      'ASCIIString', {'data'}; ...
      'UTF8String', {'data'}; ...
      };
    jl_types = [jl_types; err_types];
    
    jl_fieldnames = containers.Map(jl_types(:,1), jl_types(:,2));
    
    % Define the types that benefit from extra processing after deserialization
    jl_action_table = {...
      'ASCIIString', @(t) char(t.data); ...
      'UTF8String', @(t) char(t.data); ...
      };
    % Put all errors on the action table
    err_action_table = [err_types(:,1), repmat({@jlerror}, size(err_types,1), 1)];
    jl_action_table = [jl_action_table; err_action_table];
    
    jl_struct_action = containers.Map(jl_action_table(:,1), jl_action_table(:,2));
  end
  
  %% Input parsing
  switch mode
    case 'ser'
      buf = jl_serialize(arg);
      varargout = {buf};
    case 'deser'
      [pos, c] = jl_deserialize(1, arg);
      if pos <= length(arg)
        error('Message not fully deserialized');
      end
      if iscell(c)
        varargout = c;
      else
        varargout = {c};
      end
    otherwise
      error(['mode ' mode ' not recognized']);
  end
  return

  %% Serialize switchyard
  function buf = jl_serialize(arg)
    if isa(arg, 'juliatype')
      % Explicitly-declared type
      serfun = jl_ser_fun(arg.type);
      buf = serfun(arg.type, arg.args{:});
    else
      % Guess the correct Julia type
      if isstruct(arg)
        buf = jl_ser_struct('', arg);
      elseif iscell(arg)
        buf = jl_ser_cell('', arg);
      elseif numel(arg) > 1
        % It's an array type
        if ischar(arg)
          % Encode as ASCIIString
          buf = jl_ser_string('', arg);
        elseif isnumeric(arg)
          % Encode as a numeric array
          buf = jl_ser_array('', arg);
        else
          error('Don''t recognize type');
        end
      else
        buf = jl_ser_scalar('', arg);
      end
    end
  end
  
  %% Deserialize switchyard
  function [posout, c] = jl_deserialize(pos, s)
    if s(pos) < ioffset
      deserfun = jl_deser_fun(s(pos));
      [posout, c] = deserfun(pos, s);
    else
      c = icoded(s(pos)-ioffset+1);  % +1 for unit indexing
      posout = pos + 1;
    end
  end

  %% Serialization utilities
  function buf = jl_lookup(val, ~)
    buf = uint8(jl_ser_encode(val));
  end
  function buf = jl_ser_tuple(~, varargin)
    if numel(varargin) > 255
      buf = [uint8(jl_ser_encode('LongTuple')) typecast(uint32(numel(varargin)), 'uint8')];
    else
      buf = [uint8(jl_ser_encode('Tuple')) uint8(numel(varargin))];
    end
    buft = cell(size(varargin));
    for i = 1:numel(varargin)
      buft{i} = jl_serialize(varargin{i});
    end
    buf = [buf cat(2, buft{:})];
  end
  function buf = jl_ser_cell(~, c)
    % Serialized as an Array{Any}
    buf = [uint8(jl_ser_encode('Array')) uint8(jl_ser_encode('Any')) jl_ser_tuple('', num2cell(size(c)))];
    bufc = cell(size(c));
    for i = 1:numel(c)
      bufc{i} = jl_serialize(c{i});
    end
    buf = [buf cat(2, bufc{:})];
  end
  function buf = jl_ser_struct(~, s)
    fn = jl_fieldnames(s.typename);
    n = length(fn);
    buf = [uint8(jl_ser_encode('CompositeKind')) jl_ser_symbol([], s.typename) jl_ser_typedata([], s.typeparameters) jl_ser_scalar('Int32', n)];
    bufn = cell(1, n);
    for i = 1:n
      thisarg = s.(fn{i});
      if isa(thisarg, 'char')
        thisarg = uint8(thisarg(:));  % prevent recursion in jl_serialize
      end
      bufn{i} = jl_serialize(thisarg);
    end
    buf = [buf cat(2, bufn{:})];
  end
  function buf = jl_ser_typedata(~, type)
    if isempty(type)
      buf = jl_ser_encode('()');
    else
      switch type
        case []
          buf = jl_ser_encode('()');
        otherwise
          disp(type)
          error('Encoding for this typedata unknown');
      end
    end
  end
  function buf = jl_ser_scalar(scalartype, s)
    if any(s == icoded)
      buf = uint8(s+ioffset);
    else
      if isempty(scalartype)
        scalartype = jl_type(class(s));
      end
      if strcmp(scalartype, 'Char')
        buf = jl_ser_string([], s);
%         buf = [uint8(jl_ser_encode(scalartype)) uint8(s)];
      else
        buf = [uint8(jl_ser_encode(scalartype)) typecast(cast(s, mat_cast(scalartype)), 'uint8')];
      end
    end
  end
  function buf = jl_ser_string(~, str)
    str = str(:);
    buf = [uint8(jl_ser_encode('CompositeKind')) jl_ser_symbol([], 'ASCIIString') jl_ser_typedata([], []) jl_ser_scalar('Int32', 1) jl_ser_array([], uint8(str))];
  end
  function buf = jl_ser_array(~, A)
    sz = size(A);
    if sz(end) == 1
      sz = sz(1:end-1);
    end
    csz = num2cell(int64(sz));
    buf = [uint8(jl_ser_encode('Array')) jl_write_as_tag(jl_type(class(A))) jl_ser_tuple('', csz{:}) typecast(A(:)', 'uint8')];
  end
  function buf = jl_ser_symbol(~, s)
    l = length(s);
    if l > 255
      buf = [uint8(jl_ser_encode('LongSymbol')) typecast(uint32(l), 'uint8') uint8(s)];
    else
      buf = [uint8(jl_ser_encode('Symbol')) uint8(l) uint8(s)];
    end
  end
  function buf = jl_ser_expr(~, head, varargin)
    l = length(varargin);
    if l > 255
      buf = [uint8(jl_ser_encode('LongExpr')) typecast(uint32(l), 'uint8')];
    else
      buf = [uint8(jl_ser_encode('Expr')) uint8(l)];
    end
    buf = [buf jl_serialize(head) uint8(jl_ser_encode('Any'))];
    bufa = cell(size(varargin));
    for i = 1:numel(varargin)
      bufa{i} = jl_serialize(varargin{i});
    end
    buf = [buf cat(2, bufa{:})];
  end
  function buf = jl_write_as_tag(x)
    if ischar(x)
      buf = [uint8(0) uint8(jl_ser_encode(x))];
    else
      buf = uint8(ioffset+x);
    end
  end
  
  %% Deserialization utilities
  function [posout, ret] = jl_deser_empty(pos, ~)
    posout = pos+1;
    ret = [];
  end
  function [posout, ret] = jl_deser_scalar(pos, s)
    mattype = mat_ser_decode(s(pos));
    posout = pos + 1 + sizeof(mattype);
    ret = typecast(s(pos+1:posout-1), mattype);
  end
  function [pos, c] = jl_deser_cell(pos, s, sz)
    c = cell(sz);
    for i = 1:numel(c)
      [pos, c{i}] = jl_deserialize(pos, s);
    end
  end
  function [posout, c] = jl_deser_tuple(pos, s)
    n = s(pos+1);
    [posout, c] = jl_deser_cell(pos+2, s, [1 double(n)]);
  end
  function [posout, c] = jl_deser_longtuple(pos, s)
    n = typecast(s(pos+1:pos+sizeof('uint32')),'uint32');
    [posout, c] = jl_deser_cell(pos+1+sizeof('uint32'), s, [1 double(n)]);
  end
  function [posout, str] = jl_deser_chars(pos, s, len)
    str = char(s(pos:pos+len-1));
    posout = pos+len;
  end
  function [posout, sym] = jl_deser_symbol(pos, s)
    n = double(s(pos+1));
    [posout, sym] = jl_deser_chars(pos+2, s, n);
  end
  function [posout, sym] = jl_deser_longsymbol(pos, s)
    n = typecast(s(pos+1:pos+sizeof('uint32')),'uint32');
    [posout, sym] = jl_deser_chars(pos+1+sizeof('uint32'), s, n);
  end
  function [posout, out] = jl_deser_struct(pos, buf)
    [posout, out.typename] = jl_deser_symbol(pos+1, buf);
    out.typename = out.typename';
    [posout, out.typeparameters] = jl_deserialize(posout, buf);
    [posout, n_fields] = jl_deserialize(posout, buf);
    if isKey(jl_fieldnames, out.typename)
      fn = jl_fieldnames(out.typename);
      if length(fn) ~= n_fields
        error('Mismatch between expected fields and received fields');
      end
    else
      fn = cell(1,n_fields);
      for i = 1:n_fields
        fn{i} = sprintf('field%02d', i);
      end
    end
    n = length(fn);
    for i = 1:n
      [posout, out.(fn{i})] = jl_deserialize(posout, buf);
    end
    if isKey(jl_struct_action, out.typename)
      fun = jl_struct_action(out.typename);
      out = fun(out);
    end
  end
  function [posout, A] = jl_deser_array(pos, s)
    mattype = mat_ser_decode(s(pos+2));  % to compensate from 0 in write_as_tag
    [posout, csz] = jl_deserialize(pos+3, s);
    sz = double(cat(2,csz{:}));
    if length(sz) == 1
      sz = [1 sz];
    end
    if strcmp(mattype, 'any')
      % Return a cell array
      A = cell(sz);
      for i = 1:prod(sz)
        [posout, A{i}] = jl_deserialize(posout, s);
      end
    else
      nbytes = prod(sz)*sizeof(mattype);
      A = typecast(s(posout:posout+nbytes-1), mattype);
      A = reshape(A, sz);
      posout = posout+nbytes;
    end
  end
  
  %% Actions triggered by receipt of particular CompositeKinds
  function out = jlerror(t)
    % out is a dummy just to avoid complaints about too many outputs
    % requested
    out = 0;
    errstr = ['Julia error: ' t.typename '\n'];
    trest = rmfield(t, {'typename', 'typeparameters'});
    fn = fieldnames(trest);
    if ~isempty(fn)
      cstr = cell(1,length(fn));
      for i = 1:length(fn)
        if ischar(t.(fn{i}))
          cstr{i} = ['  ' fn{i} ': ' t.(fn{i})];
        else
          cstr{i} = ['  ' fn{i} ': ' num2str(t.(fn{i}))];
        end
      end
      errstr = cat(2, errstr, cstr{:});
    end
    error(['julia:' t.typename], errstr);
  end
end
