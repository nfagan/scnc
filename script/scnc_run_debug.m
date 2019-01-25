function scnc_run_debug(conf)

if ( nargin < 1 || isempty(conf) )
  conf = scnc.config.load();
end

conf.INTERFACE.use_mouse = true;
conf.INTERFACE.use_reward = false;
conf.INTERFACE.save = false;
conf.INTERFACE.skip_sync_tests = true;
conf.INTERFACE.use_auto_paths = true;
conf.INTERFACE.use_brains_arduino = false;
conf.INTERFACE.allow_hide_mouse = false;

conf.SCREEN.rect = [0, 0, 800, 800];

scnc.task.start( conf );

end