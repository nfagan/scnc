
function cleanup(tracker)

%   CLEANUP -- Close open files, ports, etc.

sca;

ListenChar( 0 );

scnc.util.close_ports();

if ( nargin >= 1 && ~isempty(tracker) )
  tracker.shutdown()
end

end