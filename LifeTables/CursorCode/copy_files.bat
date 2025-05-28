@echo off
echo Creating directories...
mkdir "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\lifeandothercontingencyclasses"
mkdir "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\+utilities"
mkdir "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\LifeTables"
mkdir "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\.github\ISSUE_TEMPLATE"

echo Copying core files...
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\Resources\lifeandothercontingencyclasses\*.m" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\lifeandothercontingencyclasses\"

echo Copying utilities...
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\Resources\+utilities\*.m" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\+utilities\"

echo Copying life tables...
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\Resources\LifeTables\*.xlsx" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\LifeTables\"
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\Resources\LifeTables\*.mat" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\LifeTables\"

echo Copying documentation files...
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\README.md" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\"
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\LICENSE.md" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\"
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\CONTRIBUTING.md" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\"
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\PROJECT_PLAN.md" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\"

echo Copying issue templates...
xcopy /Y "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\.github\ISSUE_TEMPLATE\*.md" "G:\My Drive\Kaparra Software\Rates Analysis\CursorCode\mortality-table-analysis\.github\ISSUE_TEMPLATE\"

echo Done! 