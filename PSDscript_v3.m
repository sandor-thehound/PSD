%function [PSDt PSDf PSDd] = PSDscript_v3(TKar,IRP)
%% Prolonged Fluoro PSD Script
% Uses PSDose function to mine dicom headers to pull pertinent information.
% With the information, a peak skin dose estimate is found. The PSD is used
% to determine whether or not notifying the patient and Doctor needs to be
% notifed. 
tic
%% Select all the dicom files to use
filename=uigetfile('*','MultiSelect','on');
% finding how many files were selected
big=size(filename);
R=big(1,2); % number of iterations/files to run through

% preallocate for varibles being used
dosedata(R,1:5)=0;
fs(R,1:7)=0;
dist(R,1:2)=0;
addfilt(R,1:4)=0;
angles(R,1:2)=0;


%% f-factor table
% Table 4 rom Calculating peak skin dose, Part I: Methods, based off of
% ICRU soft tissue
% First Column is kVp, Second column is f-factor fluoro mode, Third Column
% is f-factor for Digital Acquistion Mode
ffactor=[[60 65 70 75 85 95 100 105 115 120 125 130]' [1.061 1.063 1.065 1.066...
1.068 1.069 1.070 1.071 1.073 1.074 1.074 1.075]' [1.056 1.058 1.059 1.061 1.063...
1.066 1.067 1.068 1.070 1.071 1.071 1.072]'];

% ffactor according HVL
fHVL=[[1.058 1.059 1.061 1.0621 1.0622 1.063 1.066 1.068]' [3.25 3.75 4.25 4.75 5.25 5.75 6.25 6.75]'];

% Define where Dose is being Calculated (IRP)
IRP=60; % (cm) found from operators manual 

% Define Table for HVL vs FS giving BSF: first column: HVL, second column:
% BSF FS-100 cm^2, third column BSF FS-400 cm^(2), fourth column BSF FS-625
% cm^(2)
BSFtable=[[2.5 3 3.5 4 4.5 5 5.5 6 6.5 7]' [1.31 1.335 1.351 1.356 1.38...
1.385 1.395 1.405 1.41 1.415]' [1.352 1.395 1.435 1.451 1.4575 1.4595...
1.51 1.52 1.525 1.527]' [1.353 1.405 1.44 1.453 1.459 1.51 1.525 1.54...
1.549 1.551]'];


%% Running through the files to get data

for i=1:R
    
    [dosedata(i,1:5),fs(i,1:7),dist(i,1:2),addfilt(i,1:4)]=PSDose_v3(filename{1,i});
    
end

% Quick Check to make sure kVp is at least 60 (if not raise to at least 60)
for i=1:R
    if dosedata(i,4)<60
        dosedata(i,4)=60;
    end
    if dosedata(i,4)>130
        dosedata(i,4)=130;
    end
end
%% Catching The Outliers for ImagerPixelSpacing, Source to Patient, and Mag Factor

count1=0;count2=0;count3=0;count4=0;count5=0;
for i=1:R
    if fs(i,5)==0
        count1=1+count1;
    end 
    if fs(i,6)==0
        count2=1+count2;
    end
    if fs(i,7)==0
        count3=1+count3;
    end
    if dist(i,1)==0
        count4=1+count4;
    end
    if dist(i,2)==0
        count5=1+count5;
    end
end

% Find Average Values to fill in blanks
avg1=sum(fs(:,5))/(R-count1);
avg2=sum(fs(:,6))/(R-count2);
avg3=sum(fs(:,7))/(R-count3);
avg4=sum(dist(:,1))/(R-count4);
avg5=sum(dist(:,2))/(R-count5);

% Fill in fields that are 0 with avg values
for i=1:R
    if fs(i,5)==0
        fs(i,5)=avg1;
    end
    if fs(i,6)==0
        fs(i,6)=avg2;
    end
    if fs(i,7)==0
        fs(i,7)=avg3;
    end
    if dist(i,1)==0
        dist(i,1)=avg4;
    end
    if dist(i,2)==0
        dist(i,2)=avg5;
    end      
end

%Find average source to patient distance (SPD):
avgSPD=mean(dist(:,2));
%Find average kVp:
avgkVp=mean(dosedata(:,4));
%% Make All Data Unique (get rid of dupes)

%adding all variables to one variable=bb for bookkeeping
bb=[dosedata fs dist addfilt];
% sort the rows according to the series number
bb=sortrows(bb,2);
% get rid of duplicate rows
bb=unique(bb,'rows');
% sort the rows according to the series number
bb=sortrows(bb,2);

% Clearing and filling old variables back in without dupes (maybe choose to
% preallocate if takes too long)

dosedata=[];
fs=[];
dist=[];
addfilt=[];

dosedata=bb(:,1:5);
fs=bb(:,6:12);
dist=bb(:,13:14);
addfilt=bb(:,15:18);


%% Sum The Doses
% Since the DAP assigned to a series is for all acquistiosn; only need the
% first  
p=size(dosedata);
p=p(1,1);%finding the number of acquistions to loop through
% Preallocate space for Kar
Kar(p,1)=0;

for i=1:p
    % Determing the area of the skin being irradiated (cm^(2))
    if strcmp(fs(i,3),'CIRCULAR')==1
        Askin(i,1)=(pi*((fs(i,2)*fs(1,7))*(fs(i,2)*fs(i,6))))*(dist(i,2)/dist(i,1));
    else 
        Askin(i,1)=((abs(fs(i,1)-fs(i,2))*(fs(i,6)/10))*(abs(fs(i,3)-fs(i,4))*(fs(i,7)/10)))*(dist(i,2)/dist(i,1));
    end
    
    % Area at IRP
    AreaIRP(i,1)=((abs(fs(i,1)-fs(i,2))*(fs(i,6)/10))*(abs(fs(i,3)-fs(i,4))*(fs(i,7)/10)))*((double(IRP)*10)/dist(i,1));
    
    %Find f-factor for each DAS
    ffactorD(i,1)=interp1(ffactor(:,1),ffactor(:,3),dosedata(i,4));
    %find HVL (beam quality) for each DAS
    HVLd(i,1)=interp1(fHVL(:,1),fHVL(:,2),ffactorD(i,1),'linear','extrap');
    
    % Calling function BSF which uses a table of BSF according to their
    % field size and the beam quality (HVL)
    BSfact(i,1)=BSF(Askin(i,1),HVLd(i,1));
    
    %finds Kerma at the IRP (dosedata is in dGy so *100 to get
    %to mGy) ESAK
        Kar(i,1)=(dosedata(i,1)*100)/Askin(i,1);
        %Inverse Square Corrected
        KarISC(i,1)=Kar(i,1)*((IRP*IRP)/(.01*dist(i,2)*dist(i,2)));
        
        % Dose at reference point (part of internal check using)
        KarIRP(i,1)=(dosedata(i,1)*100)/AreaIRP(i,1);
        
        % 2nd method (summing Kar and inverse square correcting (KAR 
        % from dicom files)
        Ktab2(i,1)=dosedata(i,5)*(IRP*IRP)/(.01*dist(i,2)*dist(i,2));
 
end
% CAN take into account table factor
tablefactor=1.0;
%Average Field Size
avgFS=mean(Askin(:,1));
%Average BSF
avgBSF=mean(BSfact(:,1));


%% Total Doses

% In order to make an estimate of the fluoro. contributions were to the
% PSD. We must make some assumptions. We use the avg. SPD to change the
% total entrance skin exposure. Also, we will need to find the parameters
% which means we will need avg. kVp, avg. FS, avg. f-factor
% Input Total Dose (mGy)

TKar=9257.55; % (mGy)
%summing total calcualted air kerma at ref. point from Digital Acq.
esakd=sum(Kar);
% finding the fluoro contribution by subtracting the contributions from the
% Digital Acq from the Total
esakf=TKar-esakd;


%f-factor for fluoro mode using avg kVp
avgffactorF=interp1(ffactor(:,1),ffactor(:,2),avgkVp);


% Units of Gy for the following PSD after dividing by 1000
%PSD from DAS mode:
spam1=KarISC.*ffactorD.*BSfact;
spam2=spam1*tablefactor;
PSDd=sum(spam2)/1000;

%PSD from fluoro mode. (Making sure avgSPD is in cm with .1)
PSDf=(IRP^(2)/(.1*avgSPD)^(2))*(esakf*avgffactorF*tablefactor*avgBSF)/1000;

%Total PSD (PSDd + PSDf)
PSDt=PSDf+PSDd;

%% 2nd method (implemented 11/25/13)

% Total Kerma at IRP from Digital Acquistions
TKarD=sum(dosedata(:,5));
% Subtract KarD from the Total Kerma to get fluoro contributions
TKarF=TKar-TKarD;


% Calculate PSD contributions from Digital Acquistion
prePSDd=Ktab2.*ffactorD.*BSfact;
prePSDd=prePSDd*tablefactor;
TPSDd=sum(prePSDd)/1000;

% Calculate PSD contributions from Fluoro 
TPSDf=TKarF*(IRP^(2)/(.1*avgSPD)^(2))*avgffactorF*tablefactor*avgBSF*.001;

TPSDt=TPSDf+TPSDd;

%% Display these final values
% Percent difference
PSDt
TPSDt

esakf
TKarF

Diff_Total=(TPSDt-PSDt)/TPSDt
Diff_DSA=(TPSDd-PSDd)/TPSDd
Diff_Fluoro=(TPSDf-PSDf)/TPSDf

%quick sanity check
disp('Check # of Exposures and Cum. Dose from Report...');

toc
%end