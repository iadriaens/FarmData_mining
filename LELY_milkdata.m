function OUT = LELY_milkdata(cd,FN_DEV,FN_LAC,FN_ANI,FN_MVIS,cd_H)
% This function constructs the 'milk data' from the Lely backups
% >>> all software versions
% 
% INPUTS:   cd      current directory: where the xls/txt files are stored
%           FN_DEV  filename of the PrmDeviceVisit table
%           FN_LAC  filename of the RemLactation table
%           FN_ANI  filename of the HemAnimal table
%           FN_MVIS filename of the PrmMilkVisit table
%           cd_H    header directory
%
% OUTPUT    OUT     Merge and preprocessed table containing milking data
%
% STEP 0: Add headers to tables
% STEP 1: Load tables in matlab format
% STEP 2: Select columns we want to keep in each table & rename
% STEP 3: Merge tables into data table
% STEP 4: Check and correct for errors
%
%% STEP 0: combine header and results files
newdir = 'C:\Users\u0084712\Documents\Box Sync\Documents\MastiMan\Research\Data mining\BAKfiles scripts\tempFiles\';    % in this folder we store the tempfiles

% PrmDeviceVisit
dv_H = readtable([cd_H FN_DEV '_headers.txt'],'ReadVariableNames',0);    % read variable names
dv_H = dv_H{:,:}';                          % convert to cell array and transpose
writecell(dv_H,[newdir 'FN_DEV.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_DEV.txt"+' '"' cd FN_DEV '.txt" "'  newdir 'FN_DEV.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_DEV.txt'],'r'); f=fread(fid,'*char')'; fclose(fid);
f=f(1:length(f)-1);
fid = fopen([newdir 'FN_DEV.txt'],'w');fwrite(fid,f); fclose(fid);

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

% BenMilkVisit
mv_H = readtable([cd_H FN_MVIS '_headers.txt'],'ReadVariableNames',0);    % read variable names
mv_H = mv_H{:,:}';                          % convert to cell array and transpose
writecell(mv_H,[newdir 'FN_MVIS.txt'],'Delimiter',';');  % write headernames to file
system(['copy "' newdir 'FN_MVIS.txt"+' '"' cd FN_MVIS '.txt" "'  newdir 'FN_MVIS.txt"']);  % combine files using system cmd
fid = fopen([newdir 'FN_MVIS.txt'],'r'); f=fread(fid,'*char')'; fclose(fid);
f=f(1:length(f)-1);
fid = fopen([newdir 'FN_MVIS.txt'],'w');fwrite(fid,f); fclose(fid);

clear dv_H lac_H ani_H mv_H ans

% redefine files
FN_DEV = 'FN_DEV';      % PrmDeviceVisit
FN_LAC = 'FN_LAC';      % RemLactation
FN_ANI = 'FN_ANI';      % HemAnimal
FN_MVIS = 'FN_MVIS';    % BenMilkVisit
cd = newdir;          % new current directory


%% STEP 1 - load tables in matlab
% determine file extension, should be '.txt','csv','xls','xslx'
ext = {'.txt'};   % all possible file extensions
FNS = {FN_ANI,FN_LAC,FN_DEV,FN_MVIS}; % filenames
for i = 1:length(FNS)
    FN{i} = [cd FNS{i} ext{1}];
end
clear i j FN_MVIS FN_DEV FN_LAC FN_ANI cd ext


% Read tables
% HEMANIMAL
opts = detectImportOptions(FN{1}); 
opts.SelectedVariableNames = {'AniId','AniName','AniUserNumber','AniLifeNumber','AniBirthday'};
opts = setvartype(opts,{'AniId','AniUserNumber'},'double');
opts = setvartype(opts,{'AniName','AniLifeNumber'},'char');
opts = setvartype(opts,{'AniBirthday'},'datetime');
a = readtable(FN{1},opts);   % HemAnimal

% REMLACTATION
opts = detectImportOptions(FN{2}); 
opts.SelectedVariableNames = {'LacId','LacAniId','LacNumber','LacCalvingDate'};
opts = setvartype(opts,{'LacId','LacAniId','LacNumber'},'double');
opts = setvartype(opts,{'LacCalvingDate'},'datetime');
b = readtable(FN{2},opts);   % RemLactation

% PRMDEVICEVISIT
opts = detectImportOptions(FN{3}); 
opts.SelectedVariableNames = {'DviId','DviAniId','DviStartTime','DviEndTime','DviIntervalTime'};
opts = setvartype(opts,{'DviId','DviAniId','DviIntervalTime'},'double');
opts = setvartype(opts,{'DviStartTime','DviEndTime'},'datetime');
c = readtable(FN{3},opts);   % PrmDeviceVisit

% PRMMILKVISIT
opts = detectImportOptions(FN{4}); 
opts.SelectedVariableNames = {'MviId','MviDviId','MviMilkYield','MviMilkDuration','MviMilkSpeedMax','MviWeight','MviMilkTemperature','MviMilkDestination','MviMilkTime','MviLFMilkYield','MviRFMilkYield','MviLRMilkYield','MviRRMilkYield','MviLFConductivity','MviRFConductivity','MviLRConductivity','MviRRConductivity'};
opts = setvartype(opts,{'MviId','MviDviId','MviMilkYield','MviMilkDuration','MviMilkSpeedMax','MviWeight','MviMilkTemperature','MviMilkDestination','MviMilkTime','MviLFMilkYield','MviRFMilkYield','MviLRMilkYield','MviRRMilkYield','MviLFConductivity','MviRFConductivity','MviLRConductivity','MviRRConductivity'},'double');
d = readtable(FN{4},opts);   % PrmMilkVisit


%% STEP 2  select columns we want to keep in each table
col_ANI = {'AniId','AniName','AniUserNumber','AniLifeNumber','AniBirthday'};
col_LAC = {'LacId','LacAniId','LacNumber','LacCalvingDate'};
col_DEV = {'DviId','DviAniId','DviStartTime','DviEndTime','DviIntervalTime'};
col_MVIS = {'MviId','MviDviId','MviMilkYield','MviMilkDuration','MviMilkSpeedMax','MviWeight','MviMilkTemperature','MviMilkDestination','MviMilkTime','MviLFMilkYield','MviRFMilkYield','MviLRMilkYield','MviRRMilkYield','MviLFConductivity','MviRFConductivity','MviLRConductivity','MviRRConductivity'};

idx_ANI = zeros(1,length(col_ANI));        % to fill in - column indices
idx_LAC = zeros(1,length(col_LAC));       % to fill in - column indices
idx_DEV = zeros(1,length(col_DEV));       % to fill in - column indices
idx_MVIS = zeros(1,length(col_MVIS));       % to fill in - column indices

for i = 1:length(col_ANI)
    idx_ANI(i) = find(contains(a.Properties.VariableNames,col_ANI{i})==1,1); 
end
for i = 1:length(col_LAC)
    idx_LAC(i) = find(contains(b.Properties.VariableNames,col_LAC{i})==1,1); 
end
for i = 1:length(col_DEV)
    idx_DEV(i) = find(contains(c.Properties.VariableNames,col_DEV{i})==1,1); 
end
for i = 1:length(col_MVIS)
    idx_MVIS(i) = find(contains(d.Properties.VariableNames,col_MVIS{i})==1,1); 
end
clear col_ANI col_LAC col_DEV col_MVIS i

% select columns - for d all columns are kept
a = a(:,idx_ANI);    % select columns to keep
b = b(:,idx_LAC);   % select columns to keep
c = c(:,idx_DEV);   % select columns to keep
d = d(:,idx_MVIS);   % select columns to keep

% adjust VariableNames for merging
a.Properties.VariableNames = {'AniId','Name','UserN','LifeNumber','BDate'};
b.Properties.VariableNames = {'LacId','AniId','Lac','Calving'};
c.Properties.VariableNames = {'DviId','AniId','StartTime','EndTime','MI'};
d.Properties.VariableNames = {'MviId','DviId','TMY','Dur','Speed','Weight','MilkT','Dest','MilkTime','MYLF','MYRF','MYLR','MYRR','ECLF','ECRF','ECLR','ECRR'}; % VN MilkVisit


clear idx_ANI idx_LAC idx_DEV idx_MVIS ans

%% STEP 3: Merge tables to one

% per milking datasets

OUT = innerjoin(d,c,'Keys','DviId'); % join the per milking data
OUT = sortrows(OUT,{'AniId','StartTime'});           % sort on animal ID and date
OUT = CorLacN_LELY(OUT,b(:,[2 3 4])); % add lactation, DIM and calvingdate     
OUT = innerjoin(OUT,a,'Keys','AniId'); % add cow details to milk dataset
    
%% STEP 4: Sort and delete rows (preprocess)

OUT.DIM(:,1) = OUT.DIM(:,1) + rem(datenum(datestr(OUT.EndTime(:,1))),1);
OUT.MI(:,1) = OUT.MI(:,1)/3600;

% Select the cols needed
col_OUT = {'LifeNumber','AniId','UserN','Name','BDate','Calving','Lac',...
           'DIM','StartTime','EndTime','MI','TMY','Dest','MilkT','MilkTime','Speed','Dur','Weight',...
           'MYLF','MYRF','MYLR','MYRR','ECLF','ECRF','ECLR','ECRR'};
% prepare indices
idx_OUT = zeros(1,length(col_OUT));        % to fill in - column indices
% find indices
for i = 1:length(col_OUT)
    idx_OUT(i) = find(contains(OUT.Properties.VariableNames,col_OUT{i})==1,1,'first');
end
% Change order of columns
OUT = OUT(:,idx_OUT);

