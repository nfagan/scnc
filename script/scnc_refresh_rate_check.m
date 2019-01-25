w = Screen( 'OpenWindow', 2, [], [] );

ts = nan( 1e4, 1 );
stp = 0;

while ( true )
  
  if ( stp == 0 )
    t = tic();
  else
    ts(stp) = toc( t );
    t = tic();
  end

  Screen( 'Flip', w );
  
  stp = stp + 1;
end