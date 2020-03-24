function OUT = DLV_dailydata_v53(cd,FN_HA,FN_HALI,FN_HADD,cd_H)
% This function produces the 'daily data' from the delaval backups
% >>> software version v5.3
%
%
% INPUTS:   cd      current directory: folder of txt DATA files
%           cd_H    current directory headers: forlder of txt HEADER files 
%           FN_HA   Filename of the HistoryAnimal table
%           FN_HALI Filename of the HistoryAnimalLactationInfo table
%           FN_HADD Filename of the HistoryAnimalDailyData table
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

% History Animal
ha_H = readtable([cd_H FN_HA '_headers.txt'],'ReadVariableNames',0);    % read variable names
ha_H = ha_H{:,:}';                          % convert to cell array and transpose
writecell(ha_H,[newdir 'FN_HA.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_HA.txt"+' '"' cd FN_HA '.txt" "'  newdir 'FN_HA.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_HA.txt'],'r'); f=fread(fid,'*char')'; fclose(fid); % open en read combined data
f=f(1:length(f)-1); % remove last BOM character
fid = fopen([newdir 'FN_HA.txt'],'w');fwrite(fid,f); fclose(fid); % rewrite and close

% History Animal Lactation Info
hali_H = readtable([cd_H FN_HALI '_headers.txt'],'ReadVariableNames',0);    % read variable names
hali_H = hali_H{:,:}';                          % convert to cell array and transpose
writecell(hali_H,[newdir 'FN_HALI.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_HALI.txt"+' '"' cd FN_HALI '.txt" "'  newdir 'FN_HALI.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_HALI.txt'],'r'); f=fread(fid,'*char')'; fclose(fid); % open en read combined data
f=f(1:length(f)-1); % remove last BOM character
fid = fopen([newdir 'FN_HALI.txt'],'w');fwrite(fid,f); fclose(fid); % rewrite and close

% History Animal Daily Data
hadd_H = readtable([cd_H FN_HADD '_headers.txt'],'ReadVariableNames',0);    % read variable names
hadd_H = hadd_H{:,:}';                          % convert to cell array and transpose
writecell(hadd_H,[newdir 'FN_HADD.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_HADD.txt"+' '"' cd FN_HADD '.txt" "'  newdir 'FN_HADD.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_HADD.txt'],'r'); f=fread(fid,'*char')'; fclose(fid); % open en read combined data
f=f(1:length(f)-1); % remove last BOM character
fid = fopen([newdir 'FN_HADD.txt'],'w');fwrite(fid,f); fclose(fid); % rewrite and close

clear ha_H hali_H hadd_H ans

% redefine files
FN_HA = 'FN_HA';      % History Animal
FN_HALI = 'FN_HALI';  % History Animal Lactation Info
FN_HADD = 'FN_HADD';  % History Animal Daily Data
cd = newdir;          % new current directory



%% STEP 1 - load tables in matlab
% Combine filenames in one variable (redundant step)
ext = {'.txt'};   % all possible file extensions
FNS = {FN_HA,FN_HALI,FN_HADD};  % filenames
for i = 1:length(FNS)           % length
    FN{i} = [cd FNS{i} ext{1}]; % all three
end
% clear variables
clear i FN_HA FN_HALI FN_HADD FNS cd

% read tables
%   HISTORY ANIMAL
opts = detectImportOptions(FN{1});  % detect import options
opts.SelectedVariableNames = {'OID','ReferenceId','Number','OffRegNumber','Name','BirthDate'};% selected variable names
opts = setvartype(opts,{'OID','ReferenceId','Number'},'double'); % set var type to double
opts = setvartype(opts,{'BirthDate'},'datetime'); % set var type to datetime
a = readtable(FN{1},opts);  % read table 

%   HISTORY ANIMAL LACTATION INFO
opts = detectImportOptions(FN{2});  % detect import options
opts.SelectedVariableNames = {'OID','Animal','LactationNumber','StartDate'};% selected variable names
opts = setvartype(opts,{'OID','Animal','LactationNumber'},'double');% set var type to double
opts = setvartype(opts,{'StartDate'},'datetime');
b = readtable(FN{2},opts); % read table 

% 	HISTORY ANIMAL DAILY DATA
opts = detectImportOptions(FN{3}); % detect import options
opts.SelectedVariableNames = {'OID','BasicAnimal','DayDate','Animal','DIM','LactationNumber','DailyYield','Last7DayAvg','MilkingDurationInSec','Milkings','Kickoffs','Incompletes'};% selected variable names
opts = setvartype(opts,{'OID','BasicAnimal','DIM','LactationNumber','DailyYield','Last7DayAvg','MilkingDurationInSec','Milkings','Kickoffs','Incompletes'},'double');% set var type to double
opts = setvartype(opts,{'DayDate'},'datetime'); % set var type to datetime
c = readtable(FN{3},opts); % read table

% clear variable names
clear FN j ans DT1 DT2 exttype opts


%% STEP 2 : select columns we want to keep in each table
col_HA = {'OID','ReferenceId','Number','OffRegNumber','Name','BirthDate'};
col_HALI = {'OID','Animal','LactationNumber','StartDate'};
col_HADD = {'OID','BasicAnimal','DayDate','Animal','DIM','LactationNumber','DailyYield','Last7DayAvg','MilkingDurationInSec','Milkings','Kickoffs','Incompletes'};
idx_HA = zeros(1,length(col_HA));        % to fill in - column indices
idx_HALI = zeros(1,length(col_HALI));       % to fill in - column indices
idx_HADD = zeros(1,length(col_HADD));       % to fill in - column indices

for i = 1:length(col_HA)
    idx_HA(i) = find(contains(a.Properties.VariableNames,col_HA{i})==1,1); 
end
for i = 1:length(col_HALI)
    idx_HALI(i) = find(contains(b.Properties.VariableNames,col_HALI{i})==1,1); 
end
for i = 1:length(col_HADD)
    idx_HADD(i) = find(contains(c.Properties.VariableNames,col_HADD{i})==1,1); 
end
clear col_HA col_HALI col_HADD i

% select columns - for d all columns are kept
a = a(:,idx_HA);    % select columns to keep
b = b(:,idx_HALI);   % select columns to keep
c = c(:,idx_HADD);   % select columns to keep

% rename columns for merging - there are in order of col_XXX
a.Properties.VariableNames = {'BA','RefID','Number','OfficialRegNo','Name','BDate'};    %HA
b.Properties.VariableNames = {'OID','BA','Lac','Calving'};      % HALI
c.Properties.VariableNames = {'OID2','BA','Date','RefID','DIM','Lac','TDMY','A7DY','Dur','Milkings','Kickoffs','Incompletes'};  % HADD


clear idx_HALI idx_HA idx_HADD exttype Number


%% STEP 3: Correct Lactation numbers if not possible (similar to LELY)
% we notice that in some cases the laction number is increased while in the
% data it seems that no new lactation is started. 
% In AnimalLactationSummary, these records are
% associated with no calving date, and can be detected and corrected for as
% such.

b = sortrows(b,[2 3]);      % sort per BA and Lac
b = innerjoin(b,a(:,1:2));
idx = find(isnat(b.Calving) == 1 & b.Lac > 0);   % find all cases for which this happens
if isempty(idx) == 0
cows = b.RefID(idx);                    % select BA identity of these cows
    for i = 1:length(cows)
        sub = sortrows(c(c.RefID == cows(i),:),'Date'); % select all time data of this cow

        ind = find(datenum(sub.Date) > datenum(b.Calving(idx(i)-1))+100 & datenum(sub.Date) < datenum(b.Calving(idx(i)+1))-150 & sub.DIM < 10,1,'first');

        if isempty(ind)==1
            ind = find(datenum(sub.Date) > datenum(b.Calving(idx(i)-1))+100 & sub.DIM < 10,1,'first'); % if it is the last lactation
        end

        if isempty(ind) == 0
            DIM = sub.DIM(ind);                    % find DIM of this calving
            b.Calving(idx(i)) = sub.Date(ind)-DIM; % correct calving date
            b.IsCorrected(idx(i),1) = 1;            % add tracer that this is corrected
        end
    end
else
    b.IsCorrected(:,1) = 0;
end

b = b(isnat(b.Calving) == 0 & b.Lac ~= 0,:);   % find all cases for which this happens


clear idx ind i cows sub sub2 DIM test



%% STEP 3: Merge tables to one

c(c.Lac == 0 & isnan(c.TDMY),:) = [];      % delete all Lac = 0 and no milk yield registered
c(c.TDMY == 0 & c.A7DY == 0 & c.Dur == 0 & c.Milkings == 0,:) = []; % delete (MR?) empty data
c.Lac(c.Lac == 0) = 1;                          % correct lactation number when milk yield is registered
c(isnan(c.TDMY),:) = [];                     % delete registrations withuot data
c(isnan(c.A7DY) & isnan(c.Milkings) & isnan(c.Kickoffs) & isnan(c.Incompletes),:) = []; 
c.BA = [];

OUT = sortrows(innerjoin(a,c,'Keys',{'RefID'}),{'RefID','Date'});       % join HADD and HALI

OUT = CorLacN_DLV(OUT,b(:,[2 3 4]));


% sort rows
OUT = sortrows(OUT,{'RefID','Date'});


%% STEP 4: select variables and reorder
% Select the cols needed
col_OUT = {'OfficialRegNo','BA','Number','RefID','Name','BDate','Calving','Lac','Date','DIM','TDMY','A7DY','Dur','Milkings','Kickoffs','Incompletes'};
% prepare indices
idx_OUT = zeros(1,length(col_OUT));        % to fill in - column indices
% find indices
for i = 1:length(col_OUT)
    idx_OUT(i) = find(contains(OUT.Properties.VariableNames,col_OUT{i})==1,1,'Last'); 
end
% Change order of columns
OUT = OUT(:,idx_OUT);

%% STEP 5: construct summary table
% number of unique animals
% number of unique lactations
% startdate
% enddate
SUM = array2table([0 0], 'VariableNames',{'NUniAn','NUniLac'});
SUM.NUniAn(1,1) = length(unique(OUT.BA));
SUM.NUniLac(1,1) = length(unique(OUT{:,[2 8]},'rows'));
SUM.Start(1,1) = min(OUT.Date);
SUM.End(1,1) = max(OUT.Date);