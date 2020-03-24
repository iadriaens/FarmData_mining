function [OUT] = CorLacN_DLV(INPUT,Lacdata)
% this function adds the lactation number to the Delaval data sets; it uses
% a double loop, initially assuming the calving dates provided are correct,
% but double checks this when inconsistencies in the INPUT dataset remain.
%
%
% INPUTS:   INPUT =     milk yield dataset, with Animal Identifier = BA, and
%                       containing a date variable 'EndTime' or 'Date'
%           Lacdata =   dataset containing  'BA'
%                                           'Calving'
%                                           'Lac'
%
% OUTPUTS:  OUT = INPUT with 3 columns added 'DIM', 'Calving', and 'Lac'
%
% STEP 1: delete 'lac = 0' in Lacdata
% STEP 2: sort data in Lacdata and INPUT for BA and Date
% STEP 3: based on the 'date'or 'Endtime', add Lac, Calving and DIM
% STEP 4: summarize and check inputdata for inconsistencies = gaps
% STEP 5: correct calving dates if needed and possible
%           if lactation = last in the dataset vs not last
% STEP 6: rerun loop to add/correct Lac, Calving and DIM of corrected lac


%% STEP 1: delete all records of birthdate (lac = 0) in Lactation Info
% delete birthdate
Lacdata(Lacdata.Lac == 0,:) = []; % delete lactations with parity number = 0

% sort per Animal ID and calving date
Lacdata = sortrows(Lacdata, {'BA','Calving'});


%% STEP 2: sort all milking / daily data for BA and Date
try
    OUT = sortrows(INPUT,{'BA','Date'});    % sort for date
catch
    OUT = sortrows(INPUT,{'BA','EndTime'}); % sort for EndTime
end

%% STEP 3: Based on the date, add lac no, DIM
% find all measurements after calving date - add lac/dim/calving > if
% sorted, this overwrites for later lactations
tic
for i = 1:length(Lacdata.BA)    % all lactations registered have a calving date and parity number
    try
        ind = find(OUT.BA == Lacdata.BA(i) & floor(datenum(OUT.Date)) >= datenum(Lacdata.Calving(i))); % find all after calving date
        OUT.Lac(ind) = Lacdata.Lac(i);          % add last lactation number to all after calving
        OUT.DIM(ind) = floor(datenum(OUT.Date(ind))) - floor(datenum(Lacdata.Calving(i)));  % add DIM since calving date
        OUT.Calving(ind) = Lacdata.Calving(i);  % add calving date
    catch
        ind = find(OUT.BA == Lacdata.BA(i) & floor(datenum(OUT.EndTime)) >= datenum(Lacdata.Calving(i)));
        OUT.Lac(ind) = Lacdata.Lac(i);          % add last lactation number to all after calving
        OUT.DIM(ind) = floor(datenum(OUT.EndTime(ind))) - floor(datenum(Lacdata.Calving(i)));   % add DIM since calving date
        OUT.Calving(ind) = Lacdata.Calving(i);  % add calving date
    end
end
toc

% if no calving date was found, delete the measurements (no data available)
OUT(isnat(OUT.Calving),:) = [];

% clear variables
clear i ind


%% STEP 4: summarize all lactations and check dates
% verify correctness of calving dates - if not correct then diff3 in cowlac
% will be > 21
% if earlier than 320 days in milk, do nothing
% if later than 

% find the index of cow ID, lac and calving
idx(1) = find(contains(OUT.Properties.VariableNames,'BA')==1,1); 
idx(2) = find(contains(OUT.Properties.VariableNames,'Lac')==1,1);
idx(3) = find(contains(OUT.Properties.VariableNames,'Calving')==1,1);

% unique calving cow ID/lac/calving
cowlac = sortrows(unique(OUT(:,idx),'rows'),[1 2]);   % select BA Lac Calving
% summarize the data for each lactation and each cow
for i = 1:length(cowlac.BA(:,1))
    ind = find(OUT.BA == cowlac.BA(i) & OUT.Lac == cowlac.Lac(i));
    try         % for daily data
        cowlac.StartDate(i,1) = min(OUT.Date(ind));
        cowlac.StartDIM(i,1) = min(OUT.DIM(ind));
        cowlac.StartDIMDate(i,1) = OUT.DIM(ind(OUT.Date(ind) == min(OUT.Date(ind))));
        cowlac.EndDate(i,1) = max(OUT.Date(ind));
        cowlac.EndDIM(i,1) = max(OUT.DIM(ind));
        cowlac.EndDIMDate(i,1) = OUT.DIM(ind(OUT.Date(ind) == max(OUT.Date(ind))));
    catch       % for per milk data
        cowlac.StartDate(i,1) = min(OUT.EndTime(ind));
        cowlac.StartDIM(i,1) = min(OUT.DIM(ind));
        cowlac.StartDIMDate(i,1) = min(OUT.DIM(ind(OUT.EndTime(ind) == min(OUT.EndTime(ind)))));
        cowlac.EndDate(i,1) = max(OUT.EndTime(ind));
        cowlac.EndDIM(i,1) = max(OUT.DIM(ind));
        cowlac.EndDIMDate(i,1) = OUT.DIM(ind(OUT.EndTime(ind) == max(OUT.EndTime(ind))));
    end    
    
    cowlac.diff1(i,1) = cowlac.StartDIMDate(i,1)-cowlac.StartDIM(i,1);
    cowlac.diff2(i,1) = cowlac.EndDIMDate(i,1)-cowlac.EndDIM(i,1);
    cowlac.Nmeas(i,1) = length(ind);
    cowlac.Ndays(i,1) = datenum(cowlac.EndDate(i,1))-datenum(cowlac.StartDate(i,1));

    if length(ind) > 1
        cowlac.diff3(i,1) = max(diff(OUT.DIM(ind)));  % detect gaps
    else
        cowlac.diff3(i,1) = 0;
    end 
end
clear idx i ind

%% STEP 5: correct calving dates

% find all gaps > 21 days
ind = find(cowlac.diff3 >= 21);
% for all lactations with a gap > 21
for i=1:length(ind)
    if i < length(ind)
        if cowlac.BA(ind(i)+1) == cowlac.BA(ind(i))  %  change date calving in Lacdata
            
            idx = find(OUT.BA == cowlac.BA(ind(i)) & (OUT.Lac == cowlac.Lac(ind(i)) | OUT.Lac == cowlac.Lac(ind(i)+1)));
            
            sub = OUT(idx,:);
            sub.DIF(1,1) = 1;
            try         % for daily datasets
                sub.DIF(2:end,1) = diff(datenum(sub.Date));
                idx = find(sub.DIF >= 21,1);
                Lacdata.Calving(Lacdata.BA == cowlac.BA(ind(i)+1) & Lacdata.Lac == cowlac.Lac(ind(i)+1)) = sub.Date(idx);
            catch       % for milk datasets
                sub.DIF(2:end,1) = diff(floor(datenum(sub.EndTime)));
                idx = find(sub.DIF >= 21,1);
                Lacdata.Calving(Lacdata.BA == cowlac.BA(ind(i)+1) & Lacdata.Lac == cowlac.Lac(ind(i)+1)) = datetime(floor(datenum(sub.EndTime(idx))),'ConvertFrom','datenum');
            end
            
        else            % add new lactation / calving to Lacdata
            
            idx = find(OUT.BA == cowlac.BA(ind(i)) & (OUT.Lac == cowlac.Lac(ind(i)) | OUT.Lac == cowlac.Lac(ind(i)+1)));
            sub = OUT(idx,:);
            sub.DIF(1,1) = 1;
            try         % for daily datasets
                sub.DIF(2:end,1) = diff(datenum(sub.Date));
                idx = find(sub.DIF >= 21,1);
                Lacdata.Calving(end+1,1) = sub.Date(idx);
            catch       % for milk datasets
                sub.DIF(2:end,1) = diff(floor(datenum(sub.EndTime)));
                idx = find(sub.DIF >= 21,1);
                Lacdata.Calving(end+1,1) = datetime(floor(datenum(sub.EndTime(idx))),'ConvertFrom','datenum');
            end
            
            Lacdata.BA(end) = sub.BA(idx);
            Lacdata.Lac(end) = sub.Lac(idx)+1;
            Lacdata = sortrows(Lacdata,[1 2]);
        end
    end
end

clear idx i sub ans

%% STEP 6: rerun adjustments for the corrected cows

cows = cowlac.BA(cowlac.diff3 >= 21);
LacNew = Lacdata(find(ismember(Lacdata.BA,cows)==1),:);

tic
for i = 1:length(LacNew.BA)
    try
        ind = find(OUT.BA == LacNew.BA(i) & floor(datenum(OUT.Date)) >= datenum(LacNew.Calving(i)));
        OUT.Lac(ind) = LacNew.Lac(i);
        OUT.DIM(ind) = floor(datenum(OUT.Date(ind))) - floor(datenum(LacNew.Calving(i)));
        OUT.Calving(ind) = LacNew.Calving(i);
    catch
        ind = find(OUT.BA == LacNew.BA(i) & floor(datenum(OUT.EndTime)) >= datenum(LacNew.Calving(i)));
        OUT.Lac(ind) = LacNew.Lac(i);
        OUT.DIM(ind) = floor(datenum(OUT.EndTime(ind))) - floor(datenum(LacNew.Calving(i)));
        OUT.Calving(ind) = LacNew.Calving(i);
    end
end
toc

clear i ind

