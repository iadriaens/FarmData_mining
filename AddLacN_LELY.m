function [OUT] = AddLacN_LELY(INPUT,Lacdata)
% this function aims to add the lactation number to the Lely datasets
% INPUTS:   INPUT = milk yield dataset, with Animal Identifier = AniId, and
%                       containing a date variable 'Date'
%           Lacdata = dataset containing 'AniId'
%                                        'Calving'
%                                        'Lac'
%
% OUTPUTS:  INPUT with 3 columns added 'DIM', 'Calving', and 'Lac'
%
% STEP 1: identify the maximum lactation number in the Lacdata
% STEP 2: split Lacdata in unique parts containing at most 1 lactation per
%         animal
% STEP 3: stepwise add lactationnumber, calving and DIM to INPUT dataset

%% STEP 1: delete all records of birthdate (lac = 0) in RemLactation
% delete lactations with parity number = 0
Lacdata(Lacdata.Lac == 0,:) = []; 

% sort per AniId and calving date
Lacdata = sortrows(Lacdata, [1 3]);

%% STEP 2: Based on the date, add lac no, DIM
OUT = INPUT; 

tic
for i = 1:length(Lacdata.AniId)
    try
        ind = find(OUT.AniId == Lacdata.AniId(i) & floor(datenum(OUT.Date)) >= datenum(Lacdata.Calving(i)));
        OUT.Lac(ind) = Lacdata.Lac(i);
        OUT.DIM(ind) = floor(datenum(OUT.Date(ind))) - floor(datenum(Lacdata.Calving(i)));
        OUT.Calving(ind) = Lacdata.Calving(i);
    catch
        ind = find(OUT.AniId == Lacdata.AniId(i) & floor(datenum(OUT.EndTime)) >= datenum(Lacdata.Calving(i)));
        OUT.Lac(ind) = Lacdata.Lac(i);
        OUT.DIM(ind) = floor(datenum(OUT.EndTime(ind))) - floor(datenum(Lacdata.Calving(i)));
        OUT.Calving(ind) = Lacdata.Calving(i);
    end
end
toc

% delete for which calving is not available (these are MR/DHI analysis
% before robot was installed typically
OUT(isnat(OUT.Calving),:) = [];

clear i ind


%% STEP 3: summarize all lactations and check dates
% verify correctness of calving dates - if not correct then diff3 in cowlac
% The problem in the LELY datasets seems to be the many missing DAILY milk
% data, and so, it's delicate to correct based on the length of the gaps. 


% if earlier than 320 days in milk, do noth

idx(1) = find(contains(OUT.Properties.VariableNames,'AniId')==1,1); 
idx(2) = find(contains(OUT.Properties.VariableNames,'Lac')==1,1,'first');
if contains(OUT.Properties.VariableNames{idx(2)},'Lactose')
    idx(2) = find(contains(OUT.Properties.VariableNames,'Lac')==1,1,'last');
end
idx(3) = find(contains(OUT.Properties.VariableNames,'Calving')==1,1);

cowlac = sortrows(unique(OUT(:,idx),'rows'),[1 2]);   % select AniId Lac Calving
for i = 1:length(cowlac.AniId(:,1))
    ind = find(OUT.AniId == cowlac.AniId(i) & OUT.Lac == cowlac.Lac(i));
    try
        cowlac.StartDate(i,1) = min(OUT.Date(ind));
        cowlac.StartDIM(i,1) = min(OUT.DIM(ind));
        cowlac.StartDIMDate(i,1) = OUT.DIM(ind(OUT.Date(ind) == min(OUT.Date(ind))));
        cowlac.EndDate(i,1) = max(OUT.Date(ind));
        cowlac.EndDIM(i,1) = max(OUT.DIM(ind));
        cowlac.EndDIMDate(i,1) = OUT.DIM(ind(OUT.Date(ind) == max(OUT.Date(ind))));
    catch
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
        cowlac.diff3(i,1) = max(diff(OUT.DIM(ind)));
    else
        cowlac.diff3(i,1) = 0;
    end %cowlac.Ndays(i,1) - cowlac.Nmeas(i,1); 
end
clear idx i ind


%% STEP 5: correct calving dates

ind = find(cowlac.diff3 >= 21);
for i=1:length(ind)
    if i < length(ind)
        if cowlac.AniId(ind(i)+1) == cowlac.AniId(ind(i)) 
            if abs(diff(datenum(cowlac.EndDate(ind(i))),datenum(cowlac.Calving(ind(i)+1)))) <= 10  %  if there is data from a next lactation available and the endDate of the previous is within 10 days of the new lactation
                % then correct the calving date
                idx = find(OUT.AniId == cowlac.AniId(ind(i)) & (OUT.Lac == cowlac.Lac(ind(i)) | OUT.Lac == cowlac.Lac(ind(i)+1)));

                sub = OUT(idx,:);
                sub.DIF(1,1) = 1;
                try         % for daily datasets
                    sub.DIF(2:end,1) = diff(datenum(sub.Date));
                    idx = find(sub.DIF >= 21 );
                    Lacdata.Calving(Lacdata.AniId == cowlac.AniId(ind(i)+1) & Lacdata.Lac == cowlac.Lac(ind(i)+1)) = sub.Date(idx);
                catch       % for milk datasets
                    sub.DIF(2:end,1) = diff(floor(datenum(sub.EndTime)));
                    idx = find(sub.DIF >= 21,1);
                    Lacdata.Calving(Lacdata.AniId == cowlac.AniId(ind(i)+1) & Lacdata.Lac == cowlac.Lac(ind(i)+1)) = datetime(floor(datenum(sub.EndTime(idx))),'ConvertFrom','datenum');
                end
            end
        else            % in the case this is the last lactation for this cow, we only correct if the 'gap' happens at least 340 days after the previous calving
            
            idx = find(OUT.AniId == cowlac.AniId(ind(i)) & OUT.Lac == cowlac.Lac(ind(i))); % find all data of this cow and lactation
            sub = OUT(idx,:);       % select data
            sub.DIF(1,1) = 1;       % prepare calculation of gaps
            try         % for daily datasets
                sub.DIF(2:end,1) = diff(datenum(sub.Date));
            catch       % for milk datasets
                sub.DIF(2:end,1) = diff(floor(datenum(sub.EndTime)));
            end
            
            idx = find(sub.DIF >= 21,1); % find first with gap > 21
            try
                if datenum(sub.Date(idx)) - datenum(sub.Date(1)) > 340 % correct calving date if after 340 days
                    Lacdata.Calving(end+1,1) = sub.Date(idx);   % add new line to Lacdata, with first easurement after gap = calving date
                    Lacdata.AniId(end) = sub.AniId(idx); % add AniId
                    Lacdata.Lac(end) = sub.Lac(idx)+1;
                    Lacdata = sortrows(Lacdata,[1 2]);
                end
            catch
                if datenum(sub.EndTime(idx)) - datenum(sub.EndTime(1)) > 340
                    Lacdata.Calving(end+1,1) =  datetime(floor(datenum(sub.EndTime(idx))),'ConvertFrom','datenum');   % add new line to Lacdata, with first easurement after gap = calving date
                    Lacdata.AniId(end) = sub.AniId(idx); % add AniId
                    Lacdata.Lac(end) = sub.Lac(idx)+1;
                    Lacdata = sortrows(Lacdata,[1 2]);
                end
            end
        end
    end
end

clear idx i sub ans

%% STEP 5: rerun adjustments for the corrected cows

cows = cowlac.AniId(cowlac.diff3 >= 21);
LacNew = Lacdata(find(ismember(Lacdata.AniId,cows)==1),:);

tic
for i = 1:length(LacNew.AniId)
    try
        ind = find(OUT.AniId == LacNew.AniId(i) & floor(datenum(OUT.Date)) >= datenum(LacNew.Calving(i)));
        OUT.Lac(ind) = LacNew.Lac(i);
        OUT.DIM(ind) = floor(datenum(OUT.Date(ind))) - floor(datenum(LacNew.Calving(i)));
        OUT.Calving(ind) = LacNew.Calving(i);
    catch
        ind = find(OUT.AniId == LacNew.AniId(i) & floor(datenum(OUT.EndTime)) >= datenum(LacNew.Calving(i)));
        OUT.Lac(ind) = LacNew.Lac(i);
        OUT.DIM(ind) = floor(datenum(OUT.EndTime(ind))) - floor(datenum(LacNew.Calving(i)));
        OUT.Calving(ind) = LacNew.Calving(i);
    end
end
toc

clear i ind

