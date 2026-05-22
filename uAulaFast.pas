unit uAulaFast;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBGrids, Vcl.StdCtrls, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, Vcl.Grids, frxClass, frxDBSet, System.IOUtils,
  System.UITypes;

type
  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    btnImprimir: TButton;
    btnAssinarPdf: TButton;
    btnDiagnostico: TButton;
    dsDados: TDataSource;
    mtDados: TFDMemTable;
    frxRelClientes: TfrxReport;
    frxDBClientes: TfrxDBDataset;
    Memo1: TMemo;
    Label1: TLabel;
    procedure FormShow(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnAssinarPdfClick(Sender: TObject);
    procedure btnDiagnosticoClick(Sender: TObject);
  private
    FStampAssinadoPor: string;
    FStampCpfCnpj: string;
    FStampDataHora: string;
    FStampAlgoritmo: string;
    FStampIdValidacao: string;
    FStampUrlValidacao: string;
    procedure PopularMemTable;
    function GetAppDir: string;
    function GetReportPath: string;
    function GetSignedOutputDir: string;
    function GetJSignPdfCliPath: string;
    function BuildUnsignedPdfName: string;
    function ExecuteAndCaptureOutput(const ACommandLine, AWorkingDir: string): string;
    function ExecuteAndCaptureOutputWithExitCode(const ACommandLine, AWorkingDir: string; out AExitCode: Cardinal): string;
    function GetWindowsCertificateAliases: TStringList;
//    function GetCertificateValidityByDocument: TStringList;
//    function ExtractDigits(const AValue: string): string;
    procedure SetReportVariable(const AName, AValue: string);
    procedure PrepareSignatureStampVariables(const ASelectedAlias: string);
    procedure ApplySignatureStampVariablesToReport;
    procedure GerarPDF(out AArquivoPDF: string);
    procedure ExportReportToPdf(const AOutputPdfPath: string);
    procedure OpenFileInDefaultViewer(const AFilePath: string);
    function BuildDiagnosticsLogName: string;
    procedure WriteDiagnosticsLog(const ALogFileName: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
 frxDesgn, frxExportPDF, System.StrUtils, Winapi.ShellAPI, uAssinarPDF;

const
  C_JSignPdfCliRelativePath = 'C:\Tools\JSignPdf\app\JSignPdf\JSignPdfC.exe';

procedure TForm1.FormShow(Sender: TObject);
begin
  PopularMemTable;
end;

procedure TForm1.btnImprimirClick(Sender: TObject);
begin
  frxRelClientes.LoadFromFile(GetReportPath);


  if IsDebuggerPresent then
	  frxRelClientes.DesignReport
  else
	  frxRelClientes.ShowReport;
end;

function TForm1.GetAppDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function TForm1.GetReportPath: string;
begin
  Result := GetAppDir + 'RelClientes.fr3';
end;

function TForm1.GetSignedOutputDir: string;
begin
  Result := IncludeTrailingPathDelimiter(GetAppDir + 'PDF_Assinados');
end;

function TForm1.GetJSignPdfCliPath: string;
begin
  Result := C_JSignPdfCliRelativePath;
end;

function TForm1.BuildUnsignedPdfName: string;
begin
  Result := Format('RelClientes_%s.pdf', [FormatDateTime('yyyymmdd_hhnnss', Now)]);
end;

function TForm1.BuildDiagnosticsLogName: string;
begin
  Result := GetSignedOutputDir + Format('diagnostico_jsignpdf_%s.log',
    [FormatDateTime('yyyymmdd_hhnnss', Now)]);
end;

function TForm1.ExecuteAndCaptureOutput(const ACommandLine, AWorkingDir: string): string;
var
  ExitCode: Cardinal;
begin
  Result := ExecuteAndCaptureOutputWithExitCode(ACommandLine, AWorkingDir, ExitCode);
end;

function TForm1.ExecuteAndCaptureOutputWithExitCode(const ACommandLine, AWorkingDir: string; out AExitCode: Cardinal): string;
var
  SA: TSecurityAttributes;
  ReadPipe: THandle;
  WritePipe: THandle;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Buffer: array[0..4095] of Byte;
  BytesRead: DWORD;
  CmdLine: string;
  MutableCmdLine: string;
  OutStream: TMemoryStream;
  Data: TBytes;
begin
  Result := '';
  AExitCode := Cardinal(-1);
  ReadPipe := 0;
  WritePipe := 0;

  ZeroMemory(@SA, SizeOf(SA));
  SA.nLength := SizeOf(SA);
  SA.bInheritHandle := True;
  SA.lpSecurityDescriptor := nil;

  if not CreatePipe(ReadPipe, WritePipe, @SA, 0) then
    Exit;
  try
    SetHandleInformation(ReadPipe, HANDLE_FLAG_INHERIT, 0);

    ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
    ZeroMemory(@ProcessInfo, SizeOf(ProcessInfo));
    StartupInfo.cb := SizeOf(StartupInfo);
    StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    StartupInfo.wShowWindow := SW_HIDE;
    StartupInfo.hStdOutput := WritePipe;
    StartupInfo.hStdError := WritePipe;
    StartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);

    CmdLine := ACommandLine;
    MutableCmdLine := CmdLine;
    UniqueString(MutableCmdLine);
    if not CreateProcess(nil, PChar(MutableCmdLine), nil, nil, True, CREATE_NO_WINDOW, nil,
      PChar(AWorkingDir), StartupInfo, ProcessInfo) then
      Exit;
    try
      CloseHandle(WritePipe);
      WritePipe := 0;

      OutStream := TMemoryStream.Create;
      try
        repeat
          BytesRead := 0;
          if not ReadFile(ReadPipe, Buffer, SizeOf(Buffer), BytesRead, nil) then
            Break;
          if BytesRead = 0 then
            Break;
          OutStream.WriteBuffer(Buffer, BytesRead);
        until False;

        WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
        GetExitCodeProcess(ProcessInfo.hProcess, AExitCode);

        if OutStream.Size > 0 then
        begin
          SetLength(Data, OutStream.Size);
          OutStream.Position := 0;
          OutStream.ReadBuffer(Data[0], OutStream.Size);
          Result := TEncoding.Default.GetString(Data);
        end;
      finally
        OutStream.Free;
      end;
    finally
      CloseHandle(ProcessInfo.hThread);
      CloseHandle(ProcessInfo.hProcess);
    end;
  finally
    if ReadPipe <> 0 then
      CloseHandle(ReadPipe);
    if WritePipe <> 0 then
      CloseHandle(WritePipe);
  end;
end;

function TForm1.GetWindowsCertificateAliases: TStringList;
var
  Output: string;
  Lines: TStringList;
  I: Integer;
  AliasLine: string;
  P: Integer;
begin
  Result := TStringList.Create;
  Output := ExecuteAndCaptureOutput(
    Format('"%s" -kst WINDOWS-MY -lk -q', [GetJSignPdfCliPath]),
    GetAppDir
  );

  Lines := TStringList.Create;
  try
    Lines.Text := Output;
    for I := 0 to Lines.Count - 1 do
    begin
      AliasLine := Trim(Lines[I]);
      if AliasLine = '' then
        Continue;
      if StartsText('INFORMA', AliasLine) or StartsText('usage:', AliasLine) then
        Continue;

      P := Pos('=', AliasLine);
      if P > 0 then
        AliasLine := Trim(Copy(AliasLine, P + 1, MaxInt));

      if (AliasLine <> '') and (Result.IndexOf(AliasLine) < 0) then
        Result.Add(AliasLine);
    end;
  finally
    Lines.Free;
  end;
end;

//function TForm1.ExtractDigits(const AValue: string): string;
//var
//  I: Integer;
//begin
//  Result := '';
//  for I := 1 to Length(AValue) do
//    if CharInSet(AValue[I], ['0'..'9']) then
//      Result := Result + AValue[I];
//end;

//function TForm1.GetCertificateValidityByDocument: TStringList;
//var
//  Cmd: string;
//  Output: string;
//  Lines: TStringList;
//  I: Integer;
//  Parts: TArray<string>;
//  Doc, Status, ExpDate: string;
//begin
//  Result := TStringList.Create;
//  Result.NameValueSeparator := '=';
//
//  Cmd :=
//    'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ' +
//    '"Get-ChildItem Cert:\CurrentUser\My | ForEach-Object {' +
//    ' $doc='''' ;' +
//    ' if ($_.Subject -match ''(\d{14}|\d{11})'') { $doc=$matches[1] } ;' +
//    ' $status = if ($_.NotAfter -lt (Get-Date)) { ''VENCIDO'' } else { ''VALIDO'' } ;' +
//    ' ''{0};{1};{2}'' -f $doc,$status,$_.NotAfter.ToString(''yyyy-MM-dd'') }"';
//
//  Output := ExecuteAndCaptureOutput(Cmd, GetAppDir);
//
//  Lines := TStringList.Create;
//  try
//    Lines.Text := Output;
//    for I := 0 to Lines.Count - 1 do
//    begin
//      if Trim(Lines[I]) = '' then
//        Continue;
//      Parts := Lines[I].Split([';']);
//      if Length(Parts) < 3 then
//        Continue;
//
//      Doc := Trim(Parts[0]);
//      Status := Trim(Parts[1]);
//      ExpDate := Trim(Parts[2]);
//      if Doc = '' then
//        Continue;
//
//      Result.Values[Doc] := Status + '|' + ExpDate;
//    end;
//  finally
//    Lines.Free;
//  end;
//end;

procedure TForm1.ExportReportToPdf(const AOutputPdfPath: string);
var
  PdfExport: TfrxPDFExport;
begin
  frxRelClientes.LoadFromFile(GetReportPath);
  ApplySignatureStampVariablesToReport;
  frxRelClientes.PrepareReport(True);

  PdfExport := TfrxPDFExport.Create(nil);
  try
    PdfExport.ShowDialog := False;
    PdfExport.OpenAfterExport := False;
    PdfExport.FileName := AOutputPdfPath;
    PdfExport.OverwritePrompt := False;
    frxRelClientes.Export(PdfExport);
  finally
    PdfExport.Free;
  end;
end;

procedure TForm1.GerarPDF(out AArquivoPDF: string);
begin
  AArquivoPDF := GetAppDir + BuildUnsignedPdfName;
  ExportReportToPdf(AArquivoPDF);
end;

procedure TForm1.SetReportVariable(const AName, AValue: string);
begin
  frxRelClientes.Variables[AName] := QuotedStr(AValue);
end;

procedure TForm1.PrepareSignatureStampVariables(const ASelectedAlias: string);
var
  P: Integer;
  SignerName: string;
  SignerDoc: string;
  ValidationId: string;
  G: TGUID;
begin
  P := LastDelimiter(':', ASelectedAlias);
  if P > 0 then
  begin
    SignerName := Trim(Copy(ASelectedAlias, 1, P - 1));
    SignerDoc := Trim(Copy(ASelectedAlias, P + 1, MaxInt));
  end
  else
  begin
    SignerName := Trim(ASelectedAlias);
    SignerDoc := 'Nao informado';
  end;

  CreateGUID(G);
  ValidationId := StringReplace(GUIDToString(G), '{', '', [rfReplaceAll]);
  ValidationId := StringReplace(ValidationId, '}', '', [rfReplaceAll]);

  FStampAssinadoPor := SignerName;
  FStampCpfCnpj := SignerDoc;
  FStampDataHora := FormatDateTime('dd/mm/yyyy hh:nn:ss', Now);
  FStampAlgoritmo := 'SHA256';
  FStampIdValidacao := ValidationId;
  FStampUrlValidacao := 'https://validar.iti.gov.br/';
end;

procedure TForm1.ApplySignatureStampVariablesToReport;
begin
  SetReportVariable('AssinadoPor', FStampAssinadoPor);
  SetReportVariable('CpfCnpjAssinante', FStampCpfCnpj);
  SetReportVariable('DataHoraAssinatura', FStampDataHora);
  SetReportVariable('AlgoritmoAssinatura', FStampAlgoritmo);
  SetReportVariable('IdValidacao', FStampIdValidacao);
  SetReportVariable('UrlValidacao', FStampUrlValidacao);
end;

procedure TForm1.OpenFileInDefaultViewer(const AFilePath: string);
begin
  ShellExecute(Handle, 'open', PChar(AFilePath), nil, nil, SW_SHOWNORMAL);
end;

procedure TForm1.WriteDiagnosticsLog(const ALogFileName: string);
var
  Log: TStringList;
  ExitCode: Cardinal;
  Cmd: string;
  RawOutput: string;
  Aliases: TStringList;
  I: Integer;
  SignedDir: string;
  InputPdf: string;
begin
  SignedDir := GetSignedOutputDir;
  ForceDirectories(SignedDir);

  Log := TStringList.Create;
  Aliases := nil;
  try
    Log.Add('=== DIAGNOSTICO JSignPdf ===');
    Log.Add('DataHora: ' + DateTimeToStr(Now));
    Log.Add('AppDir: ' + GetAppDir);
    Log.Add('CurrentDir: ' + GetCurrentDir);
    Log.Add('JSignPdfPath: ' + GetJSignPdfCliPath);
    Log.Add('JSignPdfExists: ' + BoolToStr(FileExists(GetJSignPdfCliPath), True));
    Log.Add('');

    Cmd := Format('"%s" -kst WINDOWS-MY -lk', [GetJSignPdfCliPath]);
    RawOutput := ExecuteAndCaptureOutputWithExitCode(Cmd, GetAppDir, ExitCode);
    Log.Add('--- LISTAGEM 1 (-lk) ---');
    Log.Add('Cmd: ' + Cmd);
    Log.Add('ExitCode: ' + IntToStr(ExitCode));
    Log.Add(RawOutput);
    Log.Add('');

    Cmd := Format('"%s" -kst WINDOWS-MY -lk -q', [GetJSignPdfCliPath]);
    RawOutput := ExecuteAndCaptureOutputWithExitCode(Cmd, GetAppDir, ExitCode);
    Log.Add('--- LISTAGEM 2 (-lk -q) ---');
    Log.Add('Cmd: ' + Cmd);
    Log.Add('ExitCode: ' + IntToStr(ExitCode));
    Log.Add(RawOutput);
    Log.Add('');

    Aliases := GetWindowsCertificateAliases;
    Log.Add('--- PARSE FINAL DE ALIASES ---');
    Log.Add('QtdAliases: ' + IntToStr(Aliases.Count));
    for I := 0 to Aliases.Count - 1 do
      Log.Add(Format('Alias[%d]=%s', [I, Aliases[I]]));
    Log.Add('');

    if Aliases.Count > 0 then
    begin
      InputPdf := SignedDir + BuildUnsignedPdfName;
      ExportReportToPdf(InputPdf);
      Cmd := Format(
        '"%s" -kst WINDOWS-MY -ki 0 -ha SHA256 -d "%s" -os "_diag_assinado" "%s"',
        [GetJSignPdfCliPath, ExcludeTrailingPathDelimiter(SignedDir), InputPdf]
      );
      RawOutput := ExecuteAndCaptureOutputWithExitCode(Cmd, GetAppDir, ExitCode);
      Log.Add('--- TESTE ASSINATURA POR INDICE (-ki 0) ---');
      Log.Add('Cmd: ' + Cmd);
      Log.Add('ExitCode: ' + IntToStr(ExitCode));
      Log.Add(RawOutput);
      Log.Add('ArquivoEsperado: ' + ChangeFileExt(InputPdf, '') + '_diag_assinado.pdf');
    end;
  finally
    if Assigned(Aliases) then
      Aliases.Free;
    Log.SaveToFile(ALogFileName, TEncoding.UTF8);
    Log.Free;
  end;
end;

procedure TForm1.btnDiagnosticoClick(Sender: TObject);
var
  LogFile: string;
begin
  LogFile := BuildDiagnosticsLogName;
  WriteDiagnosticsLog(LogFile);
  MessageDlg('Diagnostico concluido. Arquivo gerado:' + sLineBreak + LogFile, mtInformation, [mbOK], 0);
  OpenFileInDefaultViewer(LogFile);
end;

procedure TForm1.btnAssinarPdfClick(Sender: TObject);
var
  LAssinador: IAssinarPDF;
  LCertificado: TAssinarPDFCertificado;
  LArquivoPDF: string;
  LResultado: TAssinarPDFResultado;
begin
  LAssinador := TAssinarPDF.New;
  LAssinador.SelecionarCertificado;
  LCertificado := LAssinador.GetCertificadoSelecionado;
  if not LCertificado.Selecionado then
  begin
    MessageDlg('Assinatura cancelada pelo usuario.', mtWarning, [mbOK], 0);
    Exit;
  end;

  PrepareSignatureStampVariables(LCertificado.Alias);
  GerarPDF(LArquivoPDF);

  LResultado := LAssinador
    .SetArquivo(LArquivoPDF)
    .Executar;

  if not LResultado.Sucesso then
  begin
    MessageDlg(LResultado.Mensagem, mtWarning, [mbOK], 0);
    Exit;
  end;

  OpenFileInDefaultViewer(LResultado.ArquivoAssinado);
  MessageDlg('PDF assinado com sucesso:' + sLineBreak + LResultado.ArquivoAssinado, mtInformation, [mbOK], 0);
end;

procedure TForm1.PopularMemTable;
const
  Heroes: array[0..14] of string = (
    'Superman', 'Batman', 'Mulher Maravilha', 'Flash', 'Aquaman',
    'Homem Aranha', 'Homem de Ferro', 'Capitao America', 'Thor', 'Hulk',
    'Viuva Negra', 'Doutor Estranho', 'Pantera Negra', 'Wolverine', 'Tempestade'
  );
  Sobrenomes: array[0..11] of string = (
    'Silva', 'Souza', 'Oliveira', 'Pereira', 'Costa', 'Rodrigues',
    'Almeida', 'Nascimento', 'Lima', 'Araujo', 'Fernandes', 'Gomes'
  );
var
  I: Integer;
  NomeCompleto: string;
  EmailBase: string;
begin
  Randomize;

  if not mtDados.Active then
  begin
    mtDados.FieldDefs.Clear;
    mtDados.FieldDefs.Add('ID', ftInteger);
    mtDados.FieldDefs.Add('Nome', ftString, 80);
    mtDados.FieldDefs.Add('Telefone', ftString, 20);
    mtDados.FieldDefs.Add('Email', ftString, 120);
    mtDados.CreateDataSet;
  end
  else
    mtDados.EmptyDataSet;

  for I := 1 to 30 do
  begin
    NomeCompleto := Heroes[Random(Length(Heroes))] + ' ' + Sobrenomes[Random(Length(Sobrenomes))];
    EmailBase := LowerCase(StringReplace(NomeCompleto, ' ', '.', [rfReplaceAll]));

    mtDados.Append;
    mtDados.FieldByName('ID').AsInteger := I;
    mtDados.FieldByName('Nome').AsString := NomeCompleto;
    mtDados.FieldByName('Telefone').AsString := Format('(65) 9%.4d-%.4d', [Random(10000), Random(10000)]);
    mtDados.FieldByName('Email').AsString := EmailBase + IntToStr(I) + '@aula.com';
    mtDados.Post;
  end;
end;

end.
