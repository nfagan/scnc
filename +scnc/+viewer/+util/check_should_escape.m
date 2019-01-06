function [tf, check_time] = check_should_escape(opts, data, event_name, is_next)

if ( nargin < 4 ), is_next = false; end

current_time = scnc.viewer.util.get_current_time( opts, data );

trial_number = data.Value.timing_data.trial;
trial_data = data.Value.trial_data;

if ( is_next )
  trial_number = trial_number + 1;
end

check_time = trial_data(trial_number).events.(event_name);

tf = current_time >= check_time;

end