data_p = fullfile( scnc.util.get_project_folder(), 'data', datestr(now, 'mmddyy') );

d = dir( data_p );
d = d( arrayfun(@(x) ~strcmp(x.name, '.') && ~strcmp(x.name, '..') && ~x.isdir, d) );
[~, m] = max( datenum( [d.datenum]) );

data_file = d(m).name;

file = load( fullfile(data_p, data_file) );

%%

data = file.DATA;
did_seen_cue = [ data.acquired_initial_fixation ];

cue_on = arrayfun( @(x) x.events.cue_onset, data(did_seen_cue) );
mask_on = arrayfun( @(x) x.events.mask_onset, data(did_seen_cue) );
targ_on = arrayfun( @(x) x.events.rt_response, data(did_seen_cue) );