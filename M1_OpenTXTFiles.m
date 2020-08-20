

daydir = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\6.ALLDAY\';
milkdir = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\6.ALLMILK\';
savedir = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\7.MATLAB FILES\';

%% ALLDAY
tic

% FNfiles = ls(daydir);
% ind = [];
% for i  = 1:size(FNfiles,1)
%     if isempty(find(contains(FNfiles(i,:),'.txt'))) == 1;
%         ind = [ind; i];
%     end
% end % find no filenames
% FNfiles(ind,:) = []; clear ind     % delete

opts = detectImportOptions([daydir 'DAY_DeBrabander_20140725_20200724.txt']);
% opts2 = detectImportOptions(['MILK_Sanders_20180224_20180823.txt']);

opts = setvartype(opts,{'BA','Number','RefID','Lac','DIM','TDMY','A7DY','Dur','Milkings','Kickoffs','Incompletes'},'double');
opts = setvartype(opts,{'BDate','Calving','Date'},'datetime');
opts = setvartype(opts,{'OfficialRegNo','Name'},'char');

DeBrabander = readtable([daydir 'DAY_DeBrabander_20140725_20200724.txt'],opts);
% out2 = readtable('MILK_Sanders_20180224_20180823.txt',opts);

DeBrabander=unique(DeBrabander);
DeBrabander=sortrows(DeBrabander,{'BA', 'Date'});
save([savedir 'DeBrabander.mat'],'DeBrabander')

clear out1 out2 opts workdir
toc