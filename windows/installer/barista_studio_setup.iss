; Inno Setup Script for Barista Studio
#ifndef MyAppVersion
#define MyAppVersion "1.5.2"
#endif

[Setup]
AppId={{D37E5652-3FA2-4EA4-A754-0C54B78A1D54}
AppName=Barista Studio
AppVersion={#MyAppVersion}
AppPublisher=Barista Studio Community
AppPublisherURL=https://github.com/Rosselman/barista-studio
AppSupportURL=https://github.com/Rosselman/barista-studio/issues
AppUpdatesURL=https://github.com/Rosselman/barista-studio/releases
DefaultDirName={autopf}\Barista Studio
DefaultGroupName=Barista Studio
AllowNoIcons=yes
OutputDir=.
OutputBaseFilename=barista-studio-windows-{#MyAppVersion}-setup
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
DisableProgramGroupPage=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Barista Studio"; Filename: "{app}\barista_studio.exe"
Name: "{group}\{cm:UninstallProgram,Barista Studio}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Barista Studio"; Filename: "{app}\barista_studio.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\barista_studio.exe"; Description: "{cm:LaunchProgram,Barista Studio}"; Flags: nowait postinstall skipifsilent
