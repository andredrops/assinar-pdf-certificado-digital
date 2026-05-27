#define MyAppName "AulaFast Prototipo Assinatura PDF"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "EcoCentauro"
#define MyAppExeName "AulaFast.exe"

[Setup]
AppId={{9AFA2E2A-7D6A-4ECA-B077-D6DCE53A6F36}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\AulaFastPrototipo
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=.
OutputBaseFilename=Setup_AulaFast_Prototipo
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho na area de trabalho"; GroupDescription: "Atalhos:"

[Files]
; executavel principal
Source: "..\Win32\Debug\AulaFast.exe"; DestDir: "{app}"; Flags: ignoreversion
; relatorio FR3 usado pelo prototipo
Source: "..\RelClientes.fr3"; DestDir: "{app}"; Flags: ignoreversion

; assinador JSignPdf (estrutura esperada pelo app)
Source: "..\AssinarPDF\BIN\JSignPdfC.exe"; DestDir: "{app}\AssinarPDF\BIN"; Flags: ignoreversion
Source: "..\AssinarPDF\BIN\app\*"; DestDir: "{app}\AssinarPDF\BIN\app"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\AssinarPDF\BIN\runtime\*"; DestDir: "{app}\AssinarPDF\BIN\runtime"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
; pasta de saida padrao para PDFs assinados
Name: "{app}\AssinarPDF\PDFAssinados"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Executar {#MyAppName}"; Flags: nowait postinstall skipifsilent
