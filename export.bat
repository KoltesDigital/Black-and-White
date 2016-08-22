RMDIR /S /Q export
MKDIR export\BnW
COPY bin\Release\* export\BnW
XCOPY wd\* export\BnW /S /EXCLUDE:export-wd-exclude

CD export
"C:\Program Files\7-Zip\7z.exe" a BnW.7z BnW