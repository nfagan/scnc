
function err = start(conf)

%   START -- Attempt to setup and run the task.
%
%     OUT:
%       - `err` (double, MException) -- 0 if successful; otherwise, the
%         raised MException, if setup / run fails.

if ( nargin < 1 || isempty(conf) )
  conf = scnc.config.load();
else
  scnc.util.assertions.assert__is_config( conf );
end

try
  opts = scnc.task.setup( conf );
catch err
  scnc.task.cleanup();
  scnc.util.print_error_stack( err );
  return;
end

try
  err = 0;
  scnc.task.run( opts );
  scnc.task.cleanup();
catch err
  scnc.task.cleanup();
  scnc.util.print_error_stack( err );
end

end