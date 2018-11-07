
function save(conf)

%   SAVE -- Save the config file.

scnc.util.assertions.assert__is_config( conf );
const = scnc.config.constants();
fprintf( '\n Config file saved\n\n' );
save( fullfile(const.config_folder, const.config_filename), 'conf' );

end