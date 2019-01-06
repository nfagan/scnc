function t = get_current_time(opts, data)

task = opts.Value.TASK;
clock_offset = data.Value.timing_data.clock_offset;

t = elapsed( task ) + clock_offset;

end