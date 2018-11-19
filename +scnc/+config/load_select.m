function conf = load_select(filename, conf)

if ( nargin < 2 || isempty(conf) )
  conf = scnc.config.load();
else
  scnc.util.assertions.assert__is_config( conf );
end

fname = fullfile( scnc.util.get_project_folder(), 'config', filename );

other_conf = shared_utils.io.fload( fname );

match_fields = { 'TIMINGS', 'STIMULI', 'REWARDS', 'META', 'STRUCTURE' };

for i = 1:numel(match_fields)
  conf.(match_fields{i}) = other_conf.(match_fields{i});
end

end