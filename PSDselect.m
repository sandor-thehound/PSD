function [filename pathname R] = PSDselect()
%% Function to select Files for PSD Calculation in a GUI
%% Select all the dicom files to use
[filename pathname]=uigetfile('*','MultiSelect','on');
cd(pathname);

%% Finding how many files were selected before Filter
big=size(filename);
R=big(1,2); % number of iterations/files to run through

%% Loop selector 
count=0;   
for i=1:R
       a=dicominfo(filename{1,i});
       if myIsField(a,'ImageAndFluoroscopyAreaDoseProduct')==0
       else
           count=count+1;
           filename1(1,count)=filename(1,i);
       end
end
   filename=[];
   filename=filename1;
   
 %% Finding how many files were selected after Modality Filter
big=size(filename);
R=big(1,2); % number of iterations/files to run through
   
  
end