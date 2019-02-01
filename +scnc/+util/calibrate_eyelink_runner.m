function calibrate_eyelink_runner(conf)

HideCursor();

try
  scnc.util.calibrate_eyelink( conf );
catch err
  warning( err.message );
end

ShowCursor();

end