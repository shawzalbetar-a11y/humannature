[Setup]
AppName=human_nature_admin
AppVersion=1.0.0
AppPublisher=HUSEYIN GEDELOW
DefaultDirName={autopf}\human_nature_admin
PrivilegesRequired=lowest
DefaultGroupName=human_nature_admin
OutputBaseFilename=Installer
Compression=lzma
SolidCompression=yes
SetupIconFile=C:\Users\KDLO-X0X\Desktop\human nature\human_nature_admin\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\human_nature_admin.exe

[Files]
Source: "C:\Users\KDLO-X0X\Desktop\human nature\human_nature_admin\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\human_nature_admin"; Filename: "{app}\human_nature_admin.exe"
Name: "{autodesktop}\human_nature_admin"; Filename: "{app}\human_nature_admin.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Run]
Filename: "{app}\human_nature_admin.exe"; Description: "{cm:LaunchProgram,human_nature_admin}"; Flags: nowait postinstall skipifsilent
