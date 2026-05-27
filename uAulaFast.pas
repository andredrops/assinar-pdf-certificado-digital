unit uAulaFast;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.DBGrids, Vcl.StdCtrls, Data.DB,
  FireDAC.Comp.Client, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Comp.DataSet, Vcl.Grids, frxClass, frxDBSet, System.IOUtils,
  System.UITypes, uPdfSignOverlay, uAssinarPDF, Vcl.ComCtrls, uAnexo.Types;

type
  TfView = class(TForm)
    pcPrincipal: TPageControl;
    tsAssinatura: TTabSheet;
    tsAnexoNuvem: TTabSheet;
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
    btnCarregarCertificados: TButton;
    btnSelecionarCertificado: TButton;
    cbCertificados: TComboBox;
    edtDescricao: TEdit;
    edtAlias: TEdit;
    edtIndice: TEdit;
    edtNome: TEdit;
    edtDocumento: TEdit;
    edtValidoAte: TEdit;
    lblDescricao: TLabel;
    lblAlias: TLabel;
    lblIndice: TLabel;
    lblNome: TLabel;
    lblDocumento: TLabel;
    lblValidoAte: TLabel;
    btnAnexoAnexar: TButton;
    btnAnexoConfiguracoes: TButton;
    btnAnexoVisualizar: TButton;
    btnAnexoApagar: TButton;
    gridAnexo: TDBGrid;
    dsAnexo: TDataSource;
    mtAnexo: TFDMemTable;
    procedure FormShow(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure btnAssinarPdfClick(Sender: TObject);
    procedure btnDiagnosticoClick(Sender: TObject);
    procedure btnCarregarCertificadosClick(Sender: TObject);
    procedure btnSelecionarCertificadoClick(Sender: TObject);
    procedure btnAnexoAnexarClick(Sender: TObject);
    procedure btnAnexoConfiguracoesClick(Sender: TObject);
    procedure btnAnexoVisualizarClick(Sender: TObject);
    procedure btnAnexoApagarClick(Sender: TObject);
  private
    FStampAssinadoPor: string;
    FStampCpfCnpj: string;
    FStampDataHora: string;
    FStampAlgoritmo: string;
    FStampIdValidacao: string;
    FStampUrlValidacao: string;
    FPopupAssinatura: TObject;
    FAnexoNextId: Integer;
    FListaCertificados: TArray<TAssinarPDFCertificadoInfo>;
    FCertificadoAssinatura: TAssinarPDFCertificadoInfo;
    procedure PopularMemTable;
    procedure AddUploadRowsAnexo(const AResult: TUploadBatchResult);
    function HasAnexoSelection: Boolean;
    procedure LimparEditsCertificado;
    procedure PreencherEditsCertificado(const AInfo: TAssinarPDFCertificadoInfo);
    function BuildCertificadoInfoFromEdits: TAssinarPDFCertificadoInfo;
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
    procedure ValidateGeneratedPdf(const AFilePath: string);
    function ExecutarAssinaturaViaPopup(const ASetStatus: TPdfSignStatusProc): Boolean;
    function FindFastReportPreviewForm: TCustomForm;
    procedure AbrirPreviewComBotaoAssinar;
    function BuildDiagnosticsLogName: string;
    procedure WriteDiagnosticsLog(const ALogFileName: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fView: TfView;

implementation

{$R *.dfm}

uses
 frxDesgn, frxExportPDF, System.StrUtils, Winapi.ShellAPI, uAnexo;

const
  C_JSignPdfCliRelativePath = '.\AssinarPDF\BIN\JSignPdfC.exe';

procedure TfView.FormShow(Sender: TObject);
begin
  PopularMemTable;
  FAnexoNextId := 1;
  mtAnexo.Close;
  mtAnexo.Open;
  LimparEditsCertificado;
end;

procedure TfView.LimparEditsCertificado;
begin
  edtDescricao.Text := '';
  edtAlias.Text := '';
  edtIndice.Text := '';
  edtNome.Text := '';
  edtDocumento.Text := '';
  edtValidoAte.Text := '';
end;

procedure TfView.PreencherEditsCertificado(const AInfo: TAssinarPDFCertificadoInfo);
begin
  edtDescricao.Text := AInfo.Descricao;
  edtAlias.Text := AInfo.AliasCompleto;
  edtIndice.Text := IntToStr(AInfo.Indice);
  edtNome.Text := AInfo.NomeTitular;
  edtDocumento.Text := AInfo.Documento;
  if AInfo.ValidoAte > 0 then
    edtValidoAte.Text := FormatDateTime('dd/mm/yyyy', AInfo.ValidoAte)
  else
    edtValidoAte.Text := '';
end;

function TfView.BuildCertificadoInfoFromEdits: TAssinarPDFCertificadoInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Indice := StrToIntDef(Trim(edtIndice.Text), -1);
  Result.Descricao := Trim(edtDescricao.Text);
  Result.AliasCompleto := Trim(edtAlias.Text);
  Result.NomeTitular := Trim(edtNome.Text);
  Result.Documento := Trim(edtDocumento.Text);
  Result.ValidoAte := 0;
  if Trim(edtValidoAte.Text) <> '' then
    Result.ValidoAte := StrToDateDef(edtValidoAte.Text, 0);
end;

procedure TfView.btnImprimirClick(Sender: TObject);
begin
  frxRelClientes.LoadFromFile(GetReportPath);


  if IsDebuggerPresent then
	  frxRelClientes.DesignReport
  else
	  frxRelClientes.ShowReport;
end;

function TfView.GetAppDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function TfView.GetReportPath: string;
var
  LPath1: string;
  LPath2: string;
begin
  LPath1 := ExpandFileName(GetAppDir + 'RelClientes.fr3');
  LPath2 := ExpandFileName(GetAppDir + '..\..\RelClientes.fr3');

  if FileExists(LPath1) then
    Exit(LPath1);
  if FileExists(LPath2) then
    Exit(LPath2);

  Result := LPath1;
end;

function TfView.GetSignedOutputDir: string;
begin
  Result := IncludeTrailingPathDelimiter(GetAppDir + 'AssinarPDF\PDFAssinados');
end;

function TfView.GetJSignPdfCliPath: string;
begin
  Result := ExpandFileName(GetAppDir + C_JSignPdfCliRelativePath);
end;

function TfView.BuildUnsignedPdfName: string;
begin
  Result := Format('RelClientes_%s.pdf', [FormatDateTime('yyyymmdd_hhnnss', Now)]);
end;

function TfView.BuildDiagnosticsLogName: string;
begin
  Result := GetSignedOutputDir + Format('diagnostico_jsignpdf_%s.log',
    [FormatDateTime('yyyymmdd_hhnnss', Now)]);
end;

function TfView.ExecuteAndCaptureOutput(const ACommandLine, AWorkingDir: string): string;
var
  ExitCode: Cardinal;
begin
  Result := ExecuteAndCaptureOutputWithExitCode(ACommandLine, AWorkingDir, ExitCode);
end;

function TfView.ExecuteAndCaptureOutputWithExitCode(const ACommandLine, AWorkingDir: string; out AExitCode: Cardinal): string;
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

function TfView.GetWindowsCertificateAliases: TStringList;
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

procedure TfView.ExportReportToPdf(const AOutputPdfPath: string);
var
  LPdfExport: TfrxPDFExport;
  LPrepared: Boolean;
begin
  if not FileExists(GetReportPath) then
    raise Exception.Create('Arquivo de relatorio nao encontrado em: ' + GetReportPath);

  frxRelClientes.LoadFromFile(GetReportPath);
  ApplySignatureStampVariablesToReport;
  LPrepared := frxRelClientes.PrepareReport(True);
  if not LPrepared then
    raise Exception.Create('Falha ao preparar o relatorio para exportacao PDF.');

  LPdfExport := TfrxPDFExport.Create(nil);
  try
    LPdfExport.ShowDialog := False;
    LPdfExport.OpenAfterExport := False;
    LPdfExport.FileName := AOutputPdfPath;
    LPdfExport.OverwritePrompt := False;
    frxRelClientes.Export(LPdfExport);
  finally
    LPdfExport.Free;
  end;

  ValidateGeneratedPdf(AOutputPdfPath);
end;

procedure TfView.GerarPDF(out AArquivoPDF: string);
begin
  ForceDirectories(GetSignedOutputDir);
  AArquivoPDF := IncludeTrailingPathDelimiter(GetSignedOutputDir) + BuildUnsignedPdfName;
  ExportReportToPdf(AArquivoPDF);
end;

procedure TfView.ValidateGeneratedPdf(const AFilePath: string);
var
  LContent: string;
  LFileStream: TFileStream;
  LFileSize: Int64;
begin
  if not FileExists(AFilePath) then
    raise Exception.Create('PDF nao foi gerado: ' + AFilePath);

  LFileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
  try
    LFileSize := LFileStream.Size;
  finally
    LFileStream.Free;
  end;

  if LFileSize < 1024 then
  begin
    LContent := TFile.ReadAllText(AFilePath, TEncoding.ANSI);
    if Pos('/Count 0', LContent) > 0 then
      raise Exception.Create('PDF gerado sem paginas (/Count 0). Verifique o FR3, dataset e variaveis de relatorio.');
  end;
end;

procedure TfView.SetReportVariable(const AName, AValue: string);
begin
  frxRelClientes.Variables[AName] := QuotedStr(AValue);
end;

procedure TfView.PrepareSignatureStampVariables(const ASelectedAlias: string);
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

procedure TfView.ApplySignatureStampVariablesToReport;
begin
  SetReportVariable('AssinadoPor', FStampAssinadoPor);
  SetReportVariable('CpfCnpjAssinante', FStampCpfCnpj);
  SetReportVariable('DataHoraAssinatura', FStampDataHora);
  SetReportVariable('AlgoritmoAssinatura', FStampAlgoritmo);
  SetReportVariable('IdValidacao', FStampIdValidacao);
  SetReportVariable('UrlValidacao', FStampUrlValidacao);
end;

procedure TfView.OpenFileInDefaultViewer(const AFilePath: string);
begin
  ShellExecute(Handle, 'open', PChar(AFilePath), nil, nil, SW_SHOWNORMAL);
end;

procedure TfView.WriteDiagnosticsLog(const ALogFileName: string);
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

procedure TfView.btnDiagnosticoClick(Sender: TObject);
var
  LogFile: string;
begin
  LogFile := BuildDiagnosticsLogName;
  WriteDiagnosticsLog(LogFile);
  MessageDlg('Diagnostico concluido. Arquivo gerado:' + sLineBreak + LogFile, mtInformation, [mbOK], 0);
  OpenFileInDefaultViewer(LogFile);
end;

procedure TfView.btnCarregarCertificadosClick(Sender: TObject);
var
  LAssinador: IAssinarPDF;
  LI: Integer;
begin
  LAssinador := TAssinarPDF.New;
  FListaCertificados := LAssinador.ListarCertificadosInfo;
  cbCertificados.Items.Clear;
  for LI := 0 to High(FListaCertificados) do
    cbCertificados.Items.Add(FListaCertificados[LI].Descricao);

  if Length(FListaCertificados) = 0 then
  begin
    MessageDlg('Nenhum certificado encontrado no repositorio WINDOWS-MY.', mtWarning, [mbOK], 0);
    LimparEditsCertificado;
    Exit;
  end;

  cbCertificados.ItemIndex := 0;
  MessageDlg('Certificados carregados com sucesso.', mtInformation, [mbOK], 0);
end;

procedure TfView.btnSelecionarCertificadoClick(Sender: TObject);
var
  LIndex: Integer;
begin
  if Length(FListaCertificados) = 0 then
  begin
    MessageDlg('Carregue os certificados primeiro.', mtWarning, [mbOK], 0);
    Exit;
  end;

  LIndex := cbCertificados.ItemIndex;
  if (LIndex < 0) or (LIndex > High(FListaCertificados)) then
  begin
    MessageDlg('Selecione um certificado na lista.', mtWarning, [mbOK], 0);
    Exit;
  end;

  PreencherEditsCertificado(FListaCertificados[LIndex]);
end;

procedure TfView.AddUploadRowsAnexo(const AResult: TUploadBatchResult);
var
  LItem: TUploadItemResult;
  LDescricao: string;
  LExt: string;
begin
  if AResult = nil then
    Exit;

  for LItem in AResult.Items do
  begin
    if not LItem.Success then
      Continue;

    LDescricao := TPath.GetFileNameWithoutExtension(LItem.FileName);
    LExt := TPath.GetExtension(LItem.FileName);
    if (LExt <> '') and (LExt[1] = '.') then
      Delete(LExt, 1, 1);

    mtAnexo.Append;
    mtAnexo.FieldByName('ID').AsInteger := FAnexoNextId;
    mtAnexo.FieldByName('Descricao').AsString := LDescricao;
    mtAnexo.FieldByName('Extensao').AsString := LExt;
    mtAnexo.FieldByName('Tamanho').AsLargeInt := LItem.FileSize;
    mtAnexo.FieldByName('Chave').AsString := LItem.RemotePath;
    mtAnexo.FieldByName('NomeArquivo').AsString := LItem.FileName;
    mtAnexo.Post;
    Inc(FAnexoNextId);
  end;
end;

function TfView.HasAnexoSelection: Boolean;
begin
  Result := (mtAnexo <> nil) and mtAnexo.Active and (not mtAnexo.IsEmpty);
end;

procedure TfView.btnAnexoAnexarClick(Sender: TObject);
var
  LResult: TUploadBatchResult;
begin
  LResult := TAnexo.Execute;
  try
    AddUploadRowsAnexo(LResult);
  finally
    LResult.Free;
  end;
end;

procedure TfView.btnAnexoConfiguracoesClick(Sender: TObject);
begin
  TAnexo.Configurar;
end;

procedure TfView.btnAnexoVisualizarClick(Sender: TObject);
begin
  if not HasAnexoSelection then
    Exit;

  TAnexo.Visualizar(
    mtAnexo.FieldByName('Chave').AsString,
    mtAnexo.FieldByName('NomeArquivo').AsString
  );
end;

procedure TfView.btnAnexoApagarClick(Sender: TObject);
var
  LChave: string;
begin
  if not HasAnexoSelection then
    Exit;

  if MessageDlg('Tem certeza que deseja apagar este anexo?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  LChave := mtAnexo.FieldByName('Chave').AsString;
  TAnexo.Apagar(LChave);
  mtAnexo.Delete;
end;

procedure TfView.btnAssinarPdfClick(Sender: TObject);
begin
  try
    FCertificadoAssinatura := BuildCertificadoInfoFromEdits;
    if (FCertificadoAssinatura.Indice < 0) or (Trim(FCertificadoAssinatura.AliasCompleto) = '') then
    begin
      MessageDlg('Selecione um certificado antes de assinar.', mtWarning, [mbOK], 0);
      Exit;
    end;

    AbrirPreviewComBotaoAssinar;
  except
    on E: Exception do
      MessageDlg('Falha no fluxo de assinatura: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

function TfView.ExecutarAssinaturaViaPopup(const ASetStatus: TPdfSignStatusProc): Boolean;
var
  LAssinador: IAssinarPDF;
  LArquivoPDF: string;
  LResultado: TAssinarPDFResultado;
begin
  LAssinador := TAssinarPDF.New;
  LAssinador.SetCertificadoInfo(FCertificadoAssinatura);

  PrepareSignatureStampVariables(FCertificadoAssinatura.AliasCompleto);
  GerarPDF(LArquivoPDF);

  if Assigned(ASetStatus) then
    ASetStatus('Assinando...');

  LResultado := LAssinador
    .SetArquivo(LArquivoPDF)
    .Executar;

  if not LResultado.Sucesso then
  begin
    MessageDlg(LResultado.Mensagem, mtWarning, [mbOK], 0);
    Exit(False);
  end;

  OpenFileInDefaultViewer(LResultado.ArquivoAssinado);
  MessageDlg('PDF assinado com sucesso:' + sLineBreak + LResultado.ArquivoAssinado, mtInformation, [mbOK], 0);
  Result := True;
end;

function TfView.FindFastReportPreviewForm: TCustomForm;
var
  LI: Integer;
  LForm: TCustomForm;
begin
  Result := nil;
  for LI := Screen.FormCount - 1 downto 0 do
  begin
    LForm := Screen.Forms[LI];
    if LForm = Self then
      Continue;
    if (Pos('frxpreview', LowerCase(LForm.ClassName)) > 0) or
       SameText(LForm.Caption, 'Preview') then
      Exit(LForm);
  end;
end;

procedure TfView.AbrirPreviewComBotaoAssinar;
var
  LPreviewForm: TCustomForm;
  LOverlay: TPdfSignOverlay;
begin
  frxRelClientes.LoadFromFile(GetReportPath);
  ApplySignatureStampVariablesToReport;
  if not frxRelClientes.PrepareReport(True) then
    raise Exception.Create('Falha ao preparar o relatorio para preview.');

  frxRelClientes.PreviewOptions.Modal := False;
  frxRelClientes.ShowPreparedReport;
  Application.ProcessMessages;

  LPreviewForm := FindFastReportPreviewForm;
  if LPreviewForm = nil then
  begin
    MessageDlg('Preview aberto, mas nao foi possivel acoplar o botao flutuante de assinatura.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if Assigned(FPopupAssinatura) then
    FreeAndNil(FPopupAssinatura);

  LOverlay := TPdfSignOverlay.Create(LPreviewForm,
    function(const ASetStatus: TPdfSignStatusProc): Boolean
    begin
      Result := ExecutarAssinaturaViaPopup(ASetStatus);
    end
  );
  FPopupAssinatura := LOverlay;
  LOverlay.Show;
end;

procedure TfView.PopularMemTable;
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
