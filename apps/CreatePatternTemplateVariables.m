CreatePatternTemplateVariables.m
% Create the appropriate template variables from the excel files and save
% them in a single mat file to be used by the app designer app.
%
% The variables needed are:
% templateSize - how many templates, could be determined by the Matrix size
% templateCommandArray
% templateNames
% templateMuscleTypes
% templateMatrix

% All of these can be read from the PatternTemplates.xlsx file directly

templateCommandArray=[0, 32, 64, 96, 128, 160, 192, 224, 255];
templateCommandSize=size(templateCommandArray,2);
patternTemplateFileName='PatternTemplates.xlsx';
templateRange='B5:J17';
typeRange='A4:A17'; % unless the type list changes
templateNames = sheetnames(patternTemplateFileName);
templateSize=size(templateNames,1);

% read first sheet to get types - assume uniform size for all templates
templateMuscleTypes=readtable(patternTemplateFileName,'Range',typeRange,'ReadVariableNames',true,'sheet',templateNames(1));
typeSize=size(templateMuscleTypes,1);

templateMatrix=zeros(templateSize,typeSize,templateCommandSize); % create matrix, where first index is template index
for i=1:templateSize
    T=readtable(patternTemplateFileName,'Range',templateRange,'ReadVariableNames',false,'sheet',i);
    templateMatrix(i,:,:)=table2array(T);
end

% Having read the values, save the variables
defaultTemplateMatFile='PatternTemplateConstants.mat';
[filename, filepath] = uiputfile('.mat', 'Save Template Parameters As...',defaultTemplateMatFile);

if filename
    saveFile=[filepath,filename];
    save(saveFile, 'templateSize','templateCommandArray','templateNames','templateMuscleTypes','templateMatrix');
end
