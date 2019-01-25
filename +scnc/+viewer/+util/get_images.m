function image_info = get_images(image_path, is_debug, max_n, subfolders)

import shared_utils.io.dirnames;
percell = @(varargin) cellfun( varargin{:}, 'un', 0 );

% walk setup
fmts = { '.png', '.jpg', '.jpeg' };
max_depth = 3;
%   exclude files that have __archive__ in them
condition_func = @(p) isempty(strfind(p, '__archive__'));
%   find files that end in any of `fmts`
find_func = @(p) percell(@(x) shared_utils.io.find(p, x), fmts);
%   include files if more than 0 files match, and condition_func returns
%   false.
include_func = @(p) condition_func(p) && numel(horzcat_mult(find_func(p))) > 0;

if ( nargin < 4 )
  subfolders = shared_utils.io.dirnames( image_path, 'folders' );
end

image_info = struct();

for i = 1:numel(subfolders)
  
  walk_func = @(p, level) ...
    deal( ...
        {horzcat_mult(percell(@(x) shared_utils.io.find(p, x), fmts))} ...
      , include_func(p) ...
    );

  [image_fullfiles, image_components] = shared_utils.io.walk( ...
      fullfile(image_path, subfolders{i}), walk_func ...
    , 'outputs', true ...
    , 'max_depth', max_depth ...
  );

  images = cell( size(image_fullfiles) );
  image_filenames = cell( size(image_fullfiles) );

  for j = 1:numel(image_fullfiles)
    if ( is_debug )
      fprintf( '\n Image set %d of %d', j, numel(image_fullfiles) );
    end
    
    fullfiles = image_fullfiles{j};
    
    use_n = min( numel(fullfiles), max_n );
    imgs = cell( use_n, 1 );
    
    for k = 1:use_n
      if ( is_debug )
        [~, filename] = fileparts( fullfiles{k} );
        fprintf( '\n\t Image "%s": %d of %d', filename, k, numel(imgs) );
      end
      
      [img, map] = imread( fullfiles{k} );
      
      if ( ~isempty(map) )
        img = ind2rgb( img, map );
      end
      
      if ( isfloat(img) )
        imgs{k} = uint8( img .* 255 );
      else
        imgs{k} = img;
      end
    end
    
    images{j} = imgs;
    image_filenames{j} = cellfun( @fname, image_fullfiles{j}, 'un', 0 );
  end

  image_info.(subfolders{i}) = [ image_components, image_fullfiles, image_filenames, images ];

end

end

function y = fname(x)
[~, y, ext] = fileparts( x );
y = [ y, ext ];
end

function y = horzcat_mult(x)
y = horzcat( x{:} );
end