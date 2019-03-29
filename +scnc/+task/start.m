
function err = start(conf, task_func)

%   START -- Attempt to setup and run the task.
%
%     OUT:
%       - `err` (double, MException) -- 0 if successful; otherwise, the
%         raised MException, if setup / run fails.

ListenChar( 2 );

if ( nargin < 1 || isempty(conf) )
  conf = scnc.config.load();
else
  scnc.util.assertions.assert__is_config( conf );
end

if ( nargin < 2 )
  task_func = @scnc.task.run;
end

try
  opts = scnc.task.setup( conf );
catch err
  scnc.task.cleanup();
  throw( err );
end

try
  err = 0;
  task_func( opts );
  scnc.task.cleanup();
catch err
  scnc.task.cleanup();
  throw( err );
end

end