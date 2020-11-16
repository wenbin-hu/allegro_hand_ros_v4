%% prepare
clear;
clc;
close all;
%% define the target file folder and output file name
Folder = 'data/two_finger_pinch_sliding';
saved_file_name = 'merged_two_finger_pinch_sliding.mat';
%% merge the data from different mat files
FileList = dir(fullfile(Folder, '*.mat'));  % List of all MAT files
allData  = struct();
for iFile = 1:numel(FileList)               % Loop over found files
  Data   = load(fullfile(Folder, FileList(iFile).name));
  Fields = fieldnames(Data);
  for iField = 1:numel(Fields)              % Loop over fields of current file
    aField = Fields{iField};
    if isfield(allData, aField)             % Attach new data:
       allData.(aField) = [allData.(aField), Data.(aField)];
    else
       allData.(aField) = Data.(aField);
    end
  end
end
save(fullfile(Folder, saved_file_name), '-struct', 'allData');