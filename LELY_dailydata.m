function OUT = LELY_dailydata(cd,FN_MDP,FN_LAC,FN_ANI,cd_H)
% This function produces the 'daily data' from the lely backups
% >>> all software versions
%
%
% INPUTS:   cd      current directory: folder of txt DATA files
%           cd_H    current directory headers: forlder of txt HEADER files 
%           FN_MPD  Filename of the PrmMilkDayProduction table
%           FN_LAC Filename of the RemLactation table
%           FN_ANI Filename of the HemAnimal table
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

% PrmMilkDayProduction
mdp_H = readtable([cd_H FN_MDP '_headers.txt'],'ReadVariableNames',0);    % read variable names
mdp_H = mdp_H{:,:}';                          % convert to cell array and transpose
writecell(mdp_H,[newdir 'FN_MDP.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_MDP.txt"+' '"' cd FN_MDP '.txt" "'  newdir 'FN_MDP.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_MDP.txt'],'r'); f=fread(fid,'*char')'; fclose(fid);
f=f(1:length(f)-1);
fid = fopen([newdir 'FN_MDP.txt'],'w');fwrite(fid,f); fclose(fid);

% RemLactation
lac_H = readtable([cd_H FN_LAC '_headers.txt'],'ReadVariableNames',0);    % read variable names
lac_H = lac_H{:,:}';                          % convert to cell array and transpose
writecell(lac_H,[newdir 'FN_LAC.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_LAC.txt"+' '"' cd FN_LAC '.txt" "'  newdir 'FN_LAC.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_LAC.txt'],'r'); f=fread(fid,'*char')'; fclose(fid);
f=f(1:length(f)-1);
fid = fopen([newdir 'FN_LAC.txt'],'w');fwrite(fid,f); fclose(fid);

% HemAnimal
ani_H = readtable([cd_H FN_ANI '_headers.txt'],'ReadVariableNames',0);    % read variable names
ani_H = ani_H{:,:}';                          % convert to cell array and transpose
writecell(ani_H,[newdir 'FN_ANI.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_ANI.txt"+' '"' cd FN_ANI '.txt" "'  newdir 'FN_ANI.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_ANI.txt'],'r'); f=fread(fid,'*char')'; fclose(fid);
f=f(1:length(f)-1);
fid = fopen([newdir 'FN_ANI.txt'],'w');fwrite(fid,f); fclose(fid);

clear mdp_H lac_H ani_H ans

% redefine files
FN_MDP = 'FN_MDP';      % History Animal
FN_LAC = 'FN_LAC';  % History Animal Lactation Info
FN_ANI = 'FN_ANI';  % History Animal Daily Data
cd = newdir;          % new current directory


%% STEP 1 - load tables in matlab
% Combine filenames in one variable (redundant step)
ext = {'.txt'};   % all possible file extensions
FNS = {FN_ANI,FN_LAC,FN_MDP};  % filenames
for i = 1:length(FNS)           % length
    FN{i} = [cd FNS{i} ext{1}]; % all three
end
% clear variables
clear i j FN_MDP FN_LAC FN_ANI cd ext

% Read tables
%   HEMANIMAL
opts = detectImportOptions(FN{1}); % detect import options
opts.SelectedVariableNames = {'AniId','AniName','AniUserNumber','AniLifeNumber','AniBirthday'}; % select variable names
opts = setvartype(opts,{'AniId','AniUserNumber'},'double');  % set variable type to double
opts = setvartype(opts,{'AniName','AniLifeNumber'},'char');  % set variable type to char
opts = setvartype(opts,{'AniBirthday'},'datetime');          % set variable type to datetime
a = readtable(FN{1},opts);   % read table

%   REMLACTATION
opts = detectImportOptions(FN{2});  % detect import options
opts.SelectedVariableNames = {'LacId','LacAniId','LacNumber','LacCalvingDate'}; % select variable names
opts = setvartype(opts,{'LacId','LacAniId','LacNumber'},'double'); % set variable type to double
opts = setvartype(opts,{'LacCalvingDate'},'datetime'); % set variable type to datetime
b = readtable(FN{2},opts);   % read table

%   PRMMILKDAYPRODUCTION
opts = detectImportOptions(FN{3});  % detect import options
opts.SelectedVariableNames = {'MdpId','MdpAniId','MdpProductionDate','MdpDayProduction','MdpISK','MdpMilkings','MdpRefusals','MdpFailures','MdpFatPercentage','MdpProteinPercentage','MdpLactosePercentage','MdpSCC','MdpAverageWeight'};  % select variable names
opts = setvartype(opts,{'MdpId','MdpAniId','MdpDayProduction','MdpISK','MdpMilkings','MdpRefusals','MdpFailures','MdpFatPercentage','MdpProteinPercentage','MdpLactosePercentage','MdpSCC','MdpAverageWeight'},'double'); % set variable type to double
opts = setvartype(opts,{'MdpProductionDate'},'datetime'); % set variable type to datetime
c = readtable(FN{3},opts);    % read table

% clear variables
clear opts ext FNS ans FN cd

%% STEP 2  select columns we want to keep in each table
col_ANI = {'AniId','AniName','AniUserNumber','AniLifeNumber','AniBirthday'};
col_LAC = {'LacId','LacAniId','LacNumber','LacCalvingDate'};
col_MDP = {'MdpId','MdpAniId','MdpProductionDate','MdpDayProduction','MdpISK','MdpMilkings','MdpRefusals','MdpFailures','MdpFatPercentage','MdpProteinPercentage','MdpLactosePercentage','MdpSCC','MdpAverageWeight'};
idx_ANI = zeros(1,length(col_ANI));        % to fill in - column indices
idx_LAC = zeros(1,length(col_LAC));       % to fill in - column indices
idx_MDP = zeros(1,length(col_MDP));       % to fill in - column indices

for i = 1:length(col_ANI)
    idx_ANI(i) = find(contains(a.Properties.VariableNames,col_ANI{i})==1,1); 
end
for i = 1:length(col_LAC)
    idx_LAC(i) = find(contains(b.Properties.VariableNames,col_LAC{i})==1,1); 
end
for i = 1:length(col_MDP)
    idx_MDP(i) = find(contains(c.Properties.VariableNames,col_MDP{i})==1,1); 
end
clear col_ANI col_LAC col_MDP i

% select columns - for d all columns are kept
a = a(:,idx_ANI);    % select columns to keep
b = b(:,idx_LAC);   % select columns to keep
c = c(:,idx_MDP);   % select columns to keep

% adjust VariableNames for merging
a.Properties.VariableNames = {'AniId','Name','UserN','LifeNumber','BDate'};
b.Properties.VariableNames = {'LacId','AniId','Lac','Calving'};
c.Properties.VariableNames = {'MdpId','AniId','Date','TDMY','ISK','Milkings','Refusals','Failures','Fat','Protein','Lactose','SCC','Weight'};


clear idx_ANI idx_LAC idx_MDP ans

%% STEP 3: Merge tables to one
    
% delete MPR/MR/DHI data
c(isnan(c.Milkings)==1 | c.Milkings == 0,:) = [];
[~,ind] = unique(c(:,[2 3 4]),'rows');  % find unique rows
c = c(ind,:);

% merge tables
OUT = CorLacN_LELY(c,b(:,[2 3 4]));              % add calving, lac and DIM
OUT = sortrows(OUT,[2 3]);                       % sort on animal ID and date
OUT = innerjoin(OUT,a,'Keys','AniId'); % add Animal information

%% STEP 4: Sort and delete rows (preprocess)

% Select the cols needed
col_OUT = {'LifeNumber','AniId','UserN','Name','BDate','Calving','Lac',...
           'Date','DIM','TDMY','ISK','Milkings','Refusals','Failures',...
           'Fat','Protein','Lactose','SCC','Weight'};
% prepare indices
idx_OUT = zeros(1,length(col_OUT));        % to fill in - column indices
% find indices
for i = 1:length(col_OUT)
    idx_OUT(i) = find(contains(OUT.Properties.VariableNames,col_OUT{i})==1,1,'first');
end
idx_OUT(7) = 14; % lac ipv lactose
% Change order of columns
OUT = OUT(:,idx_OUT);


