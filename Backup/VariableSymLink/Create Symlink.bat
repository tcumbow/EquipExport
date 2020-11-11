pushd %~dp0
del ..\..\..\SavedVariables\EquipExport.lua
mklink ..\..\..\SavedVariables\EquipExport.lua ..\AddOns\EquipExport\VariableSymLink\EquipExport.lua
md c:\users\public\SymLinks
del c:\users\public\SymLinks\EquipExport.lua
mklink c:\users\public\SymLinks\EquipExport.lua "%~dp0EquipExport.lua"
del c:\users\public\SymLinks\LibSets_SetData.xlsx
cd ..
cd ..
mklink c:\users\public\SymLinks\LibSets_SetData.xlsx "%cd%\LibSets\LibSets_SetData.xlsx"
pause
