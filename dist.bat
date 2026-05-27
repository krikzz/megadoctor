@echo off
copy app-pc\bin\Release\megadoctor.exe dist\megadoctor.exe
copy app-md\megadoctor.md dist\megadoctor.md
copy fpga\output_files\mega-pro.rbf dist\mega-pro.rbf
copy fpga\output_files\mega-core.rbf dist\mega-core.rbf
pause 