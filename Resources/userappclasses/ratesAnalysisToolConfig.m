% Paths
% Access the Resources folder (assuming it's packaged in the compiled app)
% resourcesFolder = fullfile(app.projectBasePath, '\Resources');
appFolder = app.projectBasePath;
% assuming app runs from 'G:\My Drive\Kaparra Software\Rates Analysis\Resources\userappclasses'
cd(appFolder)
cd('..\')
disp(pwd);
%resourceFolder = fullfile(pwd, '\Resources');
resourceFolder = pwd;
if ~exist(resourceFolder, 'dir')
    error('Resources folder not found in the compiled application. Check packaging.  '+ resourcesFolder);
end
addpath(resourceFolder);

    
% Valuation Date (Adjustable)
%ValuationDate = app.InputArgs.Dates.startDate; 
ValuationDate = datetime('2017-03-31');
Settle = datetime(ValuationDate,"InputFormat","dd/MM/uuuu");

% Other Settings
format('bank');
floatingPointTolerance = 1e-10;

cd('..\')
rootFolder =pwd;
% % Output Folders (Flexible) UPDATE FOR Projectbasepath before using
outputFolderBase = '\Output'; 
outputFolder = fullfile(outputFolderBase, string(datetime("today"))); % Date-specific subfolder & relative folder
outputFolder = createDirectory(rootFolder,outputFolder); 
% outputSummaryFolder = createDirectory(app.rootdir,fullfile(outputFolder,'\PortfolioSummaries')); 
% outputReportFolder = createDirectory(app.rootdir,fullfile(outputFolder,'\ReportSummaries'));

% Rates Data

inputFolderRates = fullfile(rootFolder,'\EIOPA Rates Data');
filePattern = fullfile(inputFolderRates, '*.xlsx'); 
xlsxFiles = dir(filePattern);
xlsFileNames = {xlsxFiles.name}; 

% inputFolderRates = fullfile(inputFolderBase,'\EIOPA Rates Data');
% inputFolderRates = string(app.rootdir) + inputFolderRates;

% Life Table Data
inputFolderLifeTables = fullfile(rootFolder,'\LifeTables');
disp(inputFolderLifeTables);
    if ~exist(inputFolderLifeTables, 'dir')
        error('Life Table data folder not found in the compiled application. Check packaging.  '+ resourcesFolder);
    end
    addpath(inputFolderLifeTables); % code to read life tables sits in this folder

initialDateRates = marketdata.extractDateEIOPAFile(char(xlsFileNames(1)));
startDateRates = datetime('30/09/2023', 'InputFormat', 'dd/MM/yyyy');
inputFileNameRates = 'EIOPA_RFR_' + string(year(startDateRates)) + num2str(month(startDateRates), '%02d') + string(day(startDateRates)) + '_Term_Structures.xlsx';

%display(inputFileNameRates);
showRatesImportProgress = 0;

%set up initial countries to compare
keyCountry1 = "AU"; 
keyCountry2 = "NZ"; 
countries = [keyCountry1,keyCountry2];
%display(keyCountry2);