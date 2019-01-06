function [out_x, out_y] = get_nearest_eye_sample(eye_data, mat_t)

out_x = nan;
out_y = nan;

x = eye_data.x;
y = eye_data.y;
t = eye_data.t;

mat_sync = eye_data.mat_sync;
edf_sync = eye_data.edf_sync;

edf_t = round( shared_utils.sync.cinterp(mat_t, mat_sync, edf_sync) );

if ( isnan(edf_t) ), return; end

ind = t == edf_t;

if ( nnz(ind) == 0 ), return; end

out_x = x(ind);
out_y = y(ind);

end