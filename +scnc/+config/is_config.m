
function out = is_config(conf)

%   IS_CONFIG -- Check if a variable is a config file.

out = true;

if ( ~isa(conf, 'struct') )
  out = false;
  return;
end

const = scnc.config.constants();

if ( ~isfield(conf, const.config_id) )
  out = false;
end

end