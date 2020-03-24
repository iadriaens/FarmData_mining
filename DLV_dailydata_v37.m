function OUT = DLV_dailydata_v37(cd,FN_BA,FN_ALS,FN_AHD,FN_DM,cd_H)
% This function produces the 'daily data' from the delaval backups
% >>> software version v3.7
%
%
% INPUTS:   cd      current directory: folder of txt DATA files
%           cd_H    current directory headers: forlder of txt HEADER files 
%           FN_BA   Filename of the BasicAnimal table
%           FN_ALS  Filename of the Animal Lactation Summary table
%           FN_AHD  Filename of the Animal Historical Data table
%           FN_DM   Filename of the Daily Milk table
%
% OUTPUT    OUT     Merged and preprocessed table containing daily data
%
% STEP 0: Add headers to tables
% STEP 1: Load tables in matlab format
% STEP 2: Select columns we want to keep in each table & rename
% STEP 3: Merge tables into data table
% STEP 4: Check and correct for errors
%
%
%% STEP 0: combine header and results files
newdir = 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Research\Data mining\BAKfiles scripts\tempFiles\';    % in this folder we store the tempfiles

% Basic Animal
ba_H = readtable([cd_H FN_BA '_headers.txt'],'ReadVariableNames',0);    % read variable names
ba_H = ba_H{:,:}';                          % convert to cell array and transpose
writecell(ba_H,[newdir 'FN_BA.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_BA.txt"+' '"' cd FN_BA '.txt" "'  newdir 'FN_BA.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_BA.txt'],'r'); f=fread(fid,'*char')'; fclose(fid); % open en read combined data
f=f(1:length(f)-1); % remove last BOM character
fid = fopen([newdir 'FN_BA.txt'],'w');fwrite(fid,f); fclose(fid); % rewrite and close

% Animal Lactation Summary
als_H = readtable([cd_H FN_ALS '_headers.txt'],'ReadVariableNames',0);    % read variable names
als_H = als_H{:,:}';                          % convert to cell array and transpose
writecell(als_H,[newdir 'FN_ALS.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_ALS.txt"+' '"' cd FN_ALS '.txt" "'  newdir 'FN_ALS.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_ALS.txt'],'r'); f=fread(fid,'*char')'; fclose(fid); % open en read combined data
f=f(1:length(f)-1); % remove last BOM character
fid = fopen([newdir 'FN_ALS.txt'],'w');fwrite(fid,f); fclose(fid);% rewrite and close

% Animal Historical Data
ahd_H = readtable([cd_H FN_AHD '_headers.txt'],'ReadVariableNames',0);    % read variable names
ahd_H = ahd_H{:,:}';                          % convert to cell array and transpose
writecell(ahd_H,[newdir 'FN_AHD.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_AHD.txt"+' '"' cd FN_AHD '.txt" "'  newdir 'FN_AHD.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_AHD.txt'],'r'); f=fread(fid,'*char')'; fclose(fid);% open en read combined data
f=f(1:length(f)-1);% remove last BOM character
fid = fopen([newdir 'FN_AHD.txt'],'w');fwrite(fid,f); fclose(fid);% rewrite and close

% Daily Milk
dm_H = readtable([cd_H FN_DM '_headers.txt'],'ReadVariableNames',0);    % read variable names
dm_H = dm_H{:,:}';                          % convert to cell array and transpose
writecell(dm_H,[newdir 'FN_DM.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_DM.txt"+' '"' cd FN_DM '.txt" "'  newdir 'FN_DM.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_DM.txt'],'r'); f=fread(fid,'*char')'; fclose(fid);% open en read combined data
f=f(1:length(f)-1); % remove last BOM character
fid = fopen([newdir 'FN_DM.txt'],'w');fwrite(fid,f); fclose(fid);% rewrite and close

clear als_H ba_H ahd_H dm_H ans

% redefine files
FN_BA = 'FN_BA';        % Basic Animal
FN_ALS = 'FN_ALS';      % Animal Lactation Summary
FN_AHD = 'FN_AHD';      % Animal Historical Data
FN_DM = 'FN_DM';        % Daily Milk
cd = newdir;            % new current directory


%% STEP 1 - load tables in matlab
% Combine filenames in one variable (redundant step)
ext = {'.txt'};   % all possible file extensions
FNS = {FN_BA,FN_ALS,FN_AHD,FN_DM};  % filenames
for i = 1:length(FNS)           % length
    FN{i} = [cd FNS{i} ext{1}]; % all three
end
% clear variables
clear i FN_BA FN_ALS FN_AHD FN_DM FNS cd ext

% read tables
%   BASIC ANIMAL
opts = detectImportOptions(FN{1});  % detect import options
opts.SelectedVariableNames = {'OID','Number','OfficialRegNo','Name','BirthDate'}; % selected variable names
opts = setvartype(opts,{'OID','Number'},'double'); % set var type to double
opts = setvartype(opts,{'BirthDate'},'datetime'); % set var type to datetime
opts = setvartype(opts,{'OfficialRegNo','Name'},'char'); % set var type to char
a = readtable(FN{1},opts);  % read table 
    
%   ANIMAL LACTATION SUMMARY
opts = detectImportOptions(FN{2});  % detect import options
opts.SelectedVariableNames = {'OID','Animal','LactationNumber','StartDate'};
opts = setvartype(opts,{'OID','Animal', 'LactationNumber'},'double'); % set var type to double
opts = setvartype(opts,{'StartDate'},'datetime'); % set var type to datetime
b = readtable(FN{2},opts);   % read table

%   ANIMAL HISTORICAL DATA
opts = detectImportOptions(FN{3});  % detect import options
opts.SelectedVariableNames = {'OID','DateAndTime','BasicAnimal','DIM','LactationNumber'};
opts = setvartype(opts,{'OID','BasicAnimal','DIM','LactationNumber'},'double'); % set var type to double
opts = setvartype(opts,{'DateAndTime'},'datetime'); % set var type to datetime
c = readtable(FN{3},opts);  % read table 

%   DAILY MILK
opts = detectImportOptions(FN{4}); % detect import options
opts = setvartype(opts,'double'); % set var type to double
d = readtable(FN{4},opts);  % read table 

% clear variable names
clear FN j ans DT1 DT2 exttype opts


%% STEP 2 : select columns we want to keep in each table

% Select the cols needed
col_BA = {'OID','Number','OfficialRegNo','Name','BirthDate'};
col_ALS = {'OID','Animal','LactationNumber','StartDate'};
col_AHD = {'OID','DateAndTime','BasicAnimal','DIM','LactationNumber'};

% prepare indices
idx_BA = zeros(1,5);        % to fill in - column indices
idx_ALS = zeros(1,4);       % to fill in - column indices
idx_AHD = zeros(1,5);       % to fill in - column indices

% find indices
for i = 1:length(col_BA)
    idx_BA(i) = find(contains(a.Properties.VariableNames,col_BA{i})==1); 
end
for i = 1:length(col_ALS)
    idx_ALS(i) = find(contains(b.Properties.VariableNames,col_ALS{i})==1); 
end
for i = 1:length(col_AHD)
    idx_AHD(i) = find(contains(c.Properties.VariableNames,col_AHD{i})==1); 
end
clear col_BA col_ALS col_AHD i

% select columns - for d all columns are kept
a = a(:,idx_BA);    % select columns to keep
b = b(:,idx_ALS);   % select columns to keep
c = c(:,idx_AHD);   % select columns to keep

% rename columns for merging - there are in order of col_XXX
a.Properties.VariableNames = {'BA','Number','OfficialRegNo','Name','BDate'};    %BA
b.Properties.VariableNames = {'OID','BA','Lac','Calving'};      % ALS
c.Properties.VariableNames = {'OID2','Date','BA','DIM','Lac'};  % AHD
d.Properties.VariableNames = {'OID2','TDMY','Dur','A7DY'};      % DM

clear idx_ALS idx_BA idx_AHD


%% STEP 3: Correct Lactation numbers if not possible (similar to LELY)
% we notice that in some cases the laction number is increased while in the
% data it seems that no new lactation is started. 
% In AnimalLactationSummary, these records are
% associated with no calving date, and can be detected and corrected for as
% such.

b = sortrows(b,[2 3]);      % sort per BA
idx = find(isnat(b.Calving) == 1);   % find all cases for which this happens
if isempty(idx) == 0
    cows = b.BA(idx);                    % select BA identity of these cows
    for i = 1:length(cows)
        sub = sortrows(c(c.BA == cows(i),:),2); % select all time data of this cow
        sub2 = innerjoin(sub, d,'Keys','OID2'); % merge with DAILY data to obtain only the milkings
        
        ind = find(datenum(sub2.Date) > datenum(b.Calving(idx(i)-1))+100 & datenum(sub2.Date) < datenum(b.Calving(idx(i)+1))-150 & sub2.DIM < 10,1,'first');
        
        if isempty(ind)==1
            ind = find(datenum(sub2.Date) > datenum(b.Calving(idx(i)-1))+100 & sub2.DIM < 10,1,'first'); % if it is the last lactation
        end
        
        DIM = sub2.DIM(ind);                    % find DIM of this calving
        b.Calving(idx(i)) = sub2.Date(ind)-DIM; % correct calving date
        b.IsCorrected(idx(i),1) = 1;            % add tracer that this is corrected
    end
end

clear cows DIM i ind sub sub2 idx

%% STEP 3: Merge tables to one
OUT = innerjoin(d,c,'Keys','OID2');      % join AHD and DM, this also selects the daily milk data
OUT.OID2 = [];                           % Delete OID2 variable
OUT = sortrows(OUT,{'BA','Date'});

% rare occasions: 2 rows from the same cow / lac
[~,ind] = unique(b(:,[2 3 4]),'rows');
b = b(ind,:);
b = sortrows(b,{'BA','Calving'}); 
b(b.Lac > 20,:) = [];

OUT = outerjoin(OUT, a,'Keys', {'BA'},'MergeKeys',1);   % add BasicAnimal data

OUT = CorLacN_DLV(OUT,b(:,[2 3 4]));

% delete records with no data
OUT(isnat(OUT.Date) ==1,:) = [];

clear BA DIM cows ext i idx ind sub sub2 sub3

%% STEP 4: select variables and reorder
% Select the cols needed
col_OUT = {'OfficialRegNo','BA','Number','Name','BDate','Calving','Lac','Date','DIM','TDMY','A7DY','Dur'};
% prepare indices
idx_OUT = zeros(1,length(col_OUT));        % to fill in - column indices
% find indices
for i = 1:length(col_OUT)
    idx_OUT(i) = find(contains(OUT.Properties.VariableNames,col_OUT{i})==1,1,'first'); 
end
% Change order of columns
OUT = OUT(:,idx_OUT);


%% STEP 5: construct summary table
% number of unique animals
% number of unique lactations
% startdate
% enddate
% SUM = array2table([0 0], 'VariableNames',{'NUniAn','NUniLac'});
% SUM.NUniAn(1,1) = length(unique(OUT.BA));
% SUM.NUniLac(1,1) = length(unique(OUT{:,[2 7]},'rows'));
% SUM.Start(1,1) = min(OUT.Date);
% SUM.End(1,1) = max(OUT.Date);




