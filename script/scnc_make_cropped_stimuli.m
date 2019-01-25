function scnc_make_cropped_stimuli(stim_p, save_p, input_ext, output_ext)

if ( nargin < 4 ), output_ext = 'png'; end
if ( nargin < 3 ), input_ext = 'png'; end

if ( nargin < 1 )
  stim_p = fullfile( scnc.util.get_project_folder(), 'stimuli', 'archive', input_ext );
end

if ( nargin < 2 ), save_p = fullfile( stim_p, 'cropped' ); end

imgs = shared_utils.io.find( stim_p, sprintf('.%s', input_ext) );
fnames = shared_utils.io.filenames( imgs );

for i = 1:numel(imgs)
  [img_mat, color_map] = imread( imgs{i} );
  
  sz = size( img_mat );
  
  min_dim = min( sz );
  
  img_mat_l = img_mat(:, 1:min_dim);
  img_mat_r = img_mat(:, end-min_dim+1:end);
  
  shared_utils.io.require_dir( save_p );
  
  fname_l = sprintf( '%s__left.%s', fnames{i}, output_ext );
  fname_r = sprintf( '%s__right.%s', fnames{i}, output_ext );
  
  imwrite( img_mat_l, color_map, fullfile(save_p, fname_l) );
  imwrite( img_mat_r, color_map, fullfile(save_p, fname_r) );
end

end