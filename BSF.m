function [BSfact] = BSF(Askin,HVL)
% This function finds the BSF for corresponding patient thickness, beam
% quality, and field size. 

% need to define look up tables
% Fluoro Mode Look Up Table

% Define Table for HVL vs FS giving BSF: first column: HVL, second column:
% BSF FS-100 cm^2, third column BSF FS-400 cm^(2), fourth column BSF FS-625
% cm^(2)
BSFtable=[[2.5 3 3.5 4 4.5 5 5.5 6 6.5 7]' [1.31 1.335 1.351 1.356 1.38...
1.385 1.395 1.405 1.41 1.415]' [1.352 1.395 1.435 1.451 1.4575 1.4595...
1.51 1.52 1.525 1.527]' [1.353 1.405 1.44 1.453 1.459 1.51 1.525 1.54...
1.549 1.551]'];

% finding bsf as if the field size was 100,400, and 625
BSF100=interp1(BSFtable(:,1),BSFtable(:,2),HVL,'linear','extrap');
BSF400=interp1(BSFtable(:,1),BSFtable(:,3),HVL,'linear','extrap');
BSF625=interp1(BSFtable(:,1),BSFtable(:,4),HVL,'linear','extrap');



%variable to use interpolation to accomodate different field sizes
areaskin=[100 400 625]';
bsfhelp=[BSF100 BSF400 BSF625]';

BSfact=interp1(areaskin(:,1),bsfhelp(:,1),Askin,'linear','extrap');



end

