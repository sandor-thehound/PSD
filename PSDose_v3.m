function [dosedata,fs,dist,addfilt] = PSDose_v3(filename)
%% PSDose
% A program that mines dicom headers to give the Peak Skin Dose;

%% Read Dicom Info
% reads in pertinent dicom info from headers

a=dicominfo(filename);

%% Fields to be extracted

% DOSE INFO and to find BSF
% ImageAnd FluoroscopyAreaDoseProduct
dosedata(1,1)=a.ImageAndFluoroscopyAreaDoseProduct;
% Series Number
dosedata(1,2)=a.SeriesNumber;
% Acquistion Number
dosedata(1,3)=a.AcquisitionNumber;
% KVP
if isempty(a.KVP)==0;
    dosedata(1,4)=a.KVP;
else
    dosedata(1,4)=0;
end
% kerma (uGy)
dosedata(1,5)=0;

% Added Filtration
check=size(a.Private_0021_100a);
if check(1,1)>1
    addfilt(1,1)=a.Private_0021_100a(1,1);
    addfilt(1,2)=a.Private_0021_100a(2,1);
    addfilt(1,3)=a.Private_0021_100a(3,1);
    addfilt(1,4)=a.Private_0021_100a(4,1);
else
    addfilt(1,1)=a.Private_0021_100a(1,1);
    addfilt(1,2)=0;
    addfilt(1,3)=0;
    addfilt(1,4)=0;
end


%% Need to Check to see what fields need to be extracted for FS
% FIELD SIZE INFO

if strcmp(a.CollimatorShape,'RECTANGULAR')==1
    % Collimator Left Vertical Edge
    fs(1,1)=a.CollimatorLeftVerticalEdge;
    % Collimator Right Vertical Edge
    fs(1,2)=a.CollimatorRightVerticalEdge;
    % Collimator Upper Horizontal Edge
    fs(1,3)=a.CollimatorUpperHorizontalEdge;
    % Collimator Lower Horizontal Edge
    fs(1,4)=a.CollimatorLowerHorizontalEdge;
elseif strcmp(a.CollimatorShape,'CIRCULAR')==1
    % Center of circular collimator
    fs(1,1)=a.CenterOfCircularCollimator;
    % Radius of circular collimator
    fs(1,2)=a.RadiusOfCircularCollimator;
    % Fillers
    fs(1,3)=a.CollimatorShape;
    fs(1,4)=0;
    
    %NEED TO ADD A WAY TO GET INFO FOR FIELD SIZE IF POLYGON COLLIMATOR.
elseif strcmp(a.CollimatorShape,'POLYGONAL')==1
    %Vertices of Polygonal Collimator
    error('myApp:Polygon','Cannot calculate with polygon.');
    
end
    
%% ISSUES
% If the following fields do not exist for a given patient, use the avg of
% the fields from remainder of exam to approximate
% Magnification Factor
if myIsField(a,'EstimatedRadiographicMagnificationFactor')==0
     fs(1,5)=0;
else fs(1,5)=a.EstimatedRadiographicMagnificationFactor(1,1);
end

% Imager Pixel Spacing X 
if myIsField(a,'ImagerPixelSpacing')==0
     fs(1,6)=0;
else fs(1,6)=a.ImagerPixelSpacing(1,1);
end

% Imager Pixel Spacing Y
if myIsField(a,'ImagerPixelSpacing')==0
     fs(1,7)=0;
else fs(1,7)=a.ImagerPixelSpacing(2,1);
end

% Distances
% Distance Source to Detector
if myIsField(a,'DistanceSourceToDetector')==0
     dist(1,1)=0;
else dist(1,1)=a.DistanceSourceToDetector;
end

% Distance Source to Patient
if myIsField(a,'DistanceSourceToPatient')==0
     dist(1,2)=0;
else dist(1,2)=a.DistanceSourceToPatient(1,1);
end





end

