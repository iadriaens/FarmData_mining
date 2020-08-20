%% this script will load and merge all LELY data based on the text files
%   Data-files
%   Header files
% Call functions 'daily'
% 
%
%
%
% Vertically merge data and delete overlap
% Store datasets
%
%
% STEP 0: overview of all files in the folder - find version, farmname,
% date

clear variables
close all
clc
datetime.setDefaultFormats('defaultdate','dd-MM-yyyy');

%% STEP 1: Hard code directories

% directory of txt files with data
cd_txt = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\4.OUTPUT3txt\';       % all data files in txt format
cd_H = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\4.OUTPUT3head\';        % all header files

% temporary directory
temp_dir = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\5.TEMPFILES\';

% directory of output data
savedir_DAY = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\6.ALLDAY\';
savedir_MILK = 'C:\Users\u0132268\Documents\FarmData_Mining_SQL_Matlab_Files\6.ALLMILK\';


%% Store and collect file data
% find all the files in the folder
FNfiles = ls(cd);        % this is the list with files in the folder where I saved the MPR results of MCC
ind = []; for i  = 1:size(FNfiles,1); if isempty(find(contains(FNfiles(i,:),'.txt'))) == 1; ind = [ind; i]; end; end; % find no filenames
FNfiles(ind,:) = []; clear ind     % delete

% find all farmnames = for all files everything before '_'
files = array2table((1:size(FNfiles,1))','VariableNames',{'No'});
files.Farm(:,:) = repmat({'na'},size(FNfiles,1),1);
files.Date(:,1) = NaT;
files.Table(:,:) = repmat({'na'},size(FNfiles,1),1);
files.FN(:,:) = repmat({'na'},size(FNfiles,1),1);
for i = 1:length(FNfiles(:,1))   % run through all the files in the folder
    numLoc = regexp(FNfiles(i,:),'_');       % this functions finds the unique positions of 2 successive numbers in a filename
    endLoc = regexp(FNfiles(i,:),'.txt');    % this gives the end of the filename
    
    % Store data in 'files'
    files.Farm{i,1} = FNfiles(i,1:numLoc(1)-1);   % FarmName:length(FN(i,1:numLoc(1)-1))}
    files.Date(i,1) = datetime(FNfiles(i,numLoc(1)+1:numLoc(1)+8),'InputFormat','yyyyMMdd','Format','dd/MM/yyyy'); % Date
    files.Table{i,1} = FNfiles(i,numLoc(end)+1:endLoc-1);           % TableName
    files.FN{i,1} = FNfiles(i,1:endLoc-1);      % full FileName    
end
files = sortrows(files, {'Farm','Date'});

clear i endLoc numLoc 


%% STEP 1 : load, vertically merge and sort DAILY data of each farm
% unique farms in the dataset
Farms = unique(files.Farm);  % all unique farms in the dataset

for i = 1:length(Farms)
    % find unique dates of the back up files for that farm
    bakdates = sortrows(unique(files.Date(contains(files.Farm,Farms{i})==1)),'descend');  % all unique back up dates
    
    % print farmname
    disp(['      Current farm = ' Farms{i}])
            
    % find the filenames
    for j = 1:length(bakdates) % for all the back ups of that farm - run from last to first back-up file
        % show current backup
        disp(['      Backup date = '  datestr(bakdates(j))])

        % Initialise store
        D = ['BU' datestr(bakdates(j),'yyyyMMdd')];   % prepare structure - names = dates
       
        % Define filenames for this farm: MilkDayProduction, Lactation, Animal
        cd = 'C:\Users\u0132268\Documents\LORE\MastiManResearch\Github\FarmData_mining\OUTPUT_Lelytxt\';     % all data files in txt format
        FN_MDP = files.FN{find(contains(files.Farm,Farms{i})== 1 & datenum(files.Date) == datenum(bakdates(j)) & contains(files.Table,'PrmMilkDayProduction')==1,1,'first')};
        FN_LAC = files.FN{find(contains(files.Farm,Farms{i})== 1 & datenum(files.Date) == datenum(bakdates(j)) & contains(files.Table,'RemLactation')==1,1,'first')};
        FN_ANI = files.FN{find(contains(files.Farm,Farms{i})== 1 & datenum(files.Date) == datenum(bakdates(j)) & contains(files.Table,'HemAnimal')==1,1,'first')};
        
        % run function to extract and combine data
        DAY.(Farms{i}).(D) = LELY_dailydata(cd,FN_MDP,FN_LAC,FN_ANI,cd_H,temp_dir);
    end
    
    % find unique rows
    fields = fieldnames(DAY.(Farms{i}));
    for j = 1:length(fields)
      
        % merge 
        if j == 1
            DAYm.(Farms{i})= DAY.(Farms{i}).(fields{j});
        else
            DAYm.(Farms{i}) = [DAYm.(Farms{i});DAY.(Farms{i}).(fields{j})];
        end
        
        % select unique rows
        [~,ind] = unique(DAYm.(Farms{i})(:,[2 8 10]),'rows'); % AniId Date TMY
        DAYm.(Farms{i}) = DAYm.(Farms{i})(ind,:);
    end 
end

% save statements
fields = fieldnames(DAYm);
savedir = 'C:\Users\u0132268\Documents\LORE\MastiManResearch\Github\FarmData_mining\ALLDAY\';
for i = 1:length(fields)
    mindate = datestr(min(DAYm.(fields{i}).Date),'yyyymmdd');
    maxdate = datestr(max(DAYm.(fields{i}).Date),'yyyymmdd');

    writetable(DAYm.(fields{i}),[savedir 'DAY_' fields{i} '_' mindate '_' maxdate '.txt'],'Delimiter',';');
end



%% STEP 2 : load, vertically merge and sort PER MILKING data of each farm
% unique farms in the dataset
Farms = unique(files.Farm);  % all unique farms in the dataset
% allVarNames = {'OfficialRegNo','BA','Number','RefID','Name','BDate','Calving','Lac','Date','DIM','TDMY','A7DY','Dur','Milkings','Kickoffs','Incompletes'}; % all varNames

for i = 1:20%length(Farms)
    % find unique dates of the back up files for that farm
    bakdates = sortrows(unique(files.Date(contains(files.Farm,Farms{i})==1)),'descend');  % all unique back up dates
    
    % print farmname
    disp(['      Current farm = ' Farms{i}])
            
    % find the filenames
    for j = 1:length(bakdates) % for all the back ups of that farm - run from last to first back-up file
        % show current backup
        disp(['      Backup date = '  datestr(bakdates(j))])

        % Initialise store
        D = ['BU' datestr(bakdates(j),'yyyyMMdd')];   % prepare structure - names = dates
       
        % Define filenames for this farm: MilkDayProduction, Lactation, Animal
        cd = 'C:\Users\u0132268\Documents\LORE\MastiManResearch\Github\FarmData_mining\OUTPUT_Lelytxt\';     % all data files in txt format
        FN_DEV = files.FN{find(contains(files.Farm,Farms{i})== 1 & datenum(files.Date) == datenum(bakdates(j)) & contains(files.Table,'PrmDeviceVisit')==1,1,'first')};
        FN_LAC = files.FN{find(contains(files.Farm,Farms{i})== 1 & datenum(files.Date) == datenum(bakdates(j)) & contains(files.Table,'RemLactation')==1,1,'first')};
        FN_ANI = files.FN{find(contains(files.Farm,Farms{i})== 1 & datenum(files.Date) == datenum(bakdates(j)) & contains(files.Table,'HemAnimal')==1,1,'first')};
        FN_MVIS = files.FN{find(contains(files.Farm,Farms{i})== 1 & datenum(files.Date) == datenum(bakdates(j)) & contains(files.Table,'PrmMilkVisit')==1,1,'first')};

        % run function to extract and combine data
        MILK.(Farms{i}).(D) = LELY_milkdata(cd,FN_DEV,FN_LAC,FN_ANI,FN_MVIS,cd_H,temp_dir);
    end
    
    % find unique rows
    fields = fieldnames(MILK.(Farms{i}));
    for j = 1:length(fields)
      
        % merge 
        if j == 1
            MILKm.(Farms{i})= MILK.(Farms{i}).(fields{j});
        else
            MILKm.(Farms{i}) = [MILKm.(Farms{i}); MILK.(Farms{i}).(fields{j})];
        end
        
        % select unique rows
        [~,ind] = unique(MILKm.(Farms{i})(:,[2 9 12]),'rows'); % AniId Date TMY
        MILKm.(Farms{i}) = MILKm.(Farms{i})(ind,:);
    end 
end


% save statements

fields = fieldnames(MILKm);
savedir = 'C:\Users\u0132268\Documents\LORE\MastiManResearch\Github\FarmData_mining\ALLMILK\';
for i = 1:length(fields)
    mindate = datestr(min(MILKm.(fields{i}).EndTime),'yyyymmdd');
    maxdate = datestr(max(MILKm.(fields{i}).EndTime),'yyyymmdd');
    writetable(MILKm.(fields{i}),[savedir 'MILK_' fields{i} '_' mindate '_' maxdate '.txt'],'Delimiter',';');
end