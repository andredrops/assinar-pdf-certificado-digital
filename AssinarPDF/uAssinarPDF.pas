unit uAssinarPDF;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, Vcl.StdCtrls, Vcl.Dialogs,
  System.StrUtils, System.UITypes;

type
  TAssinarPDFCertificado = record
    Selecionado: Boolean;
    Alias: string;
    Nome: string;
    Documento: string;
    Indice: Integer;
  end;

  TAssinarPDFResultado = record
    Sucesso: Boolean;
    Mensagem: string;
    CodigoSaida: Cardinal;
    ArquivoOriginal: string;
    ArquivoAssinado: string;
    CertificadoAlias: string;
    CertificadoIndice: Integer;
  end;

  IAssinarPDF = interface
    ['{0A7C1360-0EA5-44B9-8DDF-8C89A8B2DA9C}']
    function SetArquivo(const AArquivo: string): IAssinarPDF;
    function SetPastaSaida(const APastaSaida: string): IAssinarPDF;
    function SetJSignPath(const AJSignPath: string): IAssinarPDF;
    function SetSufixoArquivo(const ASufixo: string): IAssinarPDF;
    function SelecionarCertificado: IAssinarPDF;
    function GetCertificadoSelecionado: TAssinarPDFCertificado;
    function Executar: TAssinarPDFResultado;
  end;

  TAssinarPDF = class(TInterfacedObject, IAssinarPDF)
  private
    FArquivo: string;
    FPastaSaida: string;
    FJSignPath: string;
    FSufixoArquivo: string;
    FCertificado: TAssinarPDFCertificado;
    function GetExeDir: string;
    function GetPastaSaidaEfetiva: string;
    function GetJSignPathEfetivo: string;
    function BuildSignedFileName: string;
    function ExecuteAndCaptureOutputWithExitCode(const ACommandLine, AWorkingDir: string; out AExitCode: Cardinal): string;
    function GetWindowsCertificateAliases: TStringList;
    function ExtractDigits(const AValue: string): string;
    function GetCertificateValidityByDocument: TStringList;
    function SelectCertificateAlias(const AAliases: TStrings; out ASelectedAlias: string; out ASelectedIndex: Integer): Boolean;
    function RunProcessAndWait(const ACommandLine, AWorkingDir: string; out AExitCode: Cardinal): Boolean;
  public
    class function New: IAssinarPDF;
    constructor Create;
    function SetArquivo(const AArquivo: string): IAssinarPDF;
    function SetPastaSaida(const APastaSaida: string): IAssinarPDF;
    function SetJSignPath(const AJSignPath: string): IAssinarPDF;
    function SetSufixoArquivo(const ASufixo: string): IAssinarPDF;
    function SelecionarCertificado: IAssinarPDF;
    function GetCertificadoSelecionado: TAssinarPDFCertificado;
    function Executar: TAssinarPDFResultado;
  end;

implementation

uses
  Vcl.Controls;
{ TAssinarPDF }

constructor TAssinarPDF.Create;
begin
  inherited Create;
  FSufixoArquivo := '_assinado';
  FillChar(FCertificado, SizeOf(FCertificado), 0);
  FCertificado.Indice := -1;
end;

class function TAssinarPDF.New: IAssinarPDF;
begin
  Result := TAssinarPDF.Create;
end;

function TAssinarPDF.SetArquivo(const AArquivo: string): IAssinarPDF;
begin
  FArquivo := AArquivo;
  Result := Self;
end;

function TAssinarPDF.SetJSignPath(const AJSignPath: string): IAssinarPDF;
begin
  FJSignPath := AJSignPath;
  Result := Self;
end;

function TAssinarPDF.SetPastaSaida(const APastaSaida: string): IAssinarPDF;
begin
  FPastaSaida := APastaSaida;
  Result := Self;
end;

function TAssinarPDF.SetSufixoArquivo(const ASufixo: string): IAssinarPDF;
begin
  FSufixoArquivo := ASufixo;
  Result := Self;
end;

function TAssinarPDF.GetCertificadoSelecionado: TAssinarPDFCertificado;
begin
  Result := FCertificado;
end;

function TAssinarPDF.SelecionarCertificado: IAssinarPDF;
var
  LAliases: TStringList;
  LAlias: string;
  LAliasIndex: Integer;
  LP: Integer;
begin
  Result := Self;
  FCertificado.Selecionado := False;
  FCertificado.Indice := -1;
  FCertificado.Alias := '';
  FCertificado.Nome := '';
  FCertificado.Documento := '';

  LAliases := GetWindowsCertificateAliases;
  try
    if LAliases.Count = 0 then
      Exit;

    if not SelectCertificateAlias(LAliases, LAlias, LAliasIndex) then
      Exit;

    FCertificado.Selecionado := True;
    FCertificado.Alias := LAlias;
    FCertificado.Indice := LAliasIndex;
    LP := LastDelimiter(':', LAlias);
    if LP > 0 then
    begin
      FCertificado.Nome := Trim(Copy(LAlias, 1, LP - 1));
      FCertificado.Documento := ExtractDigits(Copy(LAlias, LP + 1, MaxInt));
    end
    else
    begin
      FCertificado.Nome := LAlias;
      FCertificado.Documento := '';
    end;
  finally
    LAliases.Free;
  end;
end;

function TAssinarPDF.GetExeDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

function TAssinarPDF.GetPastaSaidaEfetiva: string;
begin
  if Trim(FPastaSaida) <> '' then
    Result := IncludeTrailingPathDelimiter(FPastaSaida)
  else
    Result := IncludeTrailingPathDelimiter(GetExeDir + 'PDFAssinados');
end;

function TAssinarPDF.GetJSignPathEfetivo: string;
begin
  if Trim(FJSignPath) <> '' then
    Exit(FJSignPath);

  Result := GetExeDir + 'AssinarPDF\BIN\JSignPdf\JSignPdfC.exe';
  if not FileExists(Result) then
    Result := 'C:\Tools\JSignPdf\app\JSignPdf\JSignPdfC.exe';
end;

function TAssinarPDF.BuildSignedFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(GetPastaSaidaEfetiva) +
    ChangeFileExt(ExtractFileName(FArquivo), '') + FSufixoArquivo + '.pdf';
end;

function TAssinarPDF.RunProcessAndWait(const ACommandLine, AWorkingDir: string; out AExitCode: Cardinal): Boolean;
var
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LCmdLine: string;
begin
  Result := False;
  AExitCode := Cardinal(-1);
  ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
  ZeroMemory(@LProcessInfo, SizeOf(LProcessInfo));
  LStartupInfo.cb := SizeOf(LStartupInfo);
  LStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  LStartupInfo.wShowWindow := SW_HIDE;

  LCmdLine := ACommandLine;
  if CreateProcess(nil, PChar(LCmdLine), nil, nil, False, CREATE_NO_WINDOW, nil, PChar(AWorkingDir), LStartupInfo, LProcessInfo) then
  begin
    try
      WaitForSingleObject(LProcessInfo.hProcess, INFINITE);
      GetExitCodeProcess(LProcessInfo.hProcess, AExitCode);
      Result := True;
    finally
      CloseHandle(LProcessInfo.hThread);
      CloseHandle(LProcessInfo.hProcess);
    end;
  end;
end;

function TAssinarPDF.ExecuteAndCaptureOutputWithExitCode(const ACommandLine, AWorkingDir: string; out AExitCode: Cardinal): string;
var
  LSA: TSecurityAttributes;
  LReadPipe: THandle;
  LWritePipe: THandle;
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LBuffer: array[0..4095] of Byte;
  LBytesRead: DWORD;
  LCmdLine: string;
  LMutableCmdLine: string;
  LOutStream: TMemoryStream;
  LData: TBytes;
begin
  Result := '';
  AExitCode := Cardinal(-1);
  LReadPipe := 0;
  LWritePipe := 0;

  ZeroMemory(@LSA, SizeOf(LSA));
  LSA.nLength := SizeOf(LSA);
  LSA.bInheritHandle := True;
  LSA.lpSecurityDescriptor := nil;

  if not CreatePipe(LReadPipe, LWritePipe, @LSA, 0) then
    Exit;
  try
    SetHandleInformation(LReadPipe, HANDLE_FLAG_INHERIT, 0);

    ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
    ZeroMemory(@LProcessInfo, SizeOf(LProcessInfo));
    LStartupInfo.cb := SizeOf(LStartupInfo);
    LStartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    LStartupInfo.wShowWindow := SW_HIDE;
    LStartupInfo.hStdOutput := LWritePipe;
    LStartupInfo.hStdError := LWritePipe;
    LStartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);

    LCmdLine := ACommandLine;
    LMutableCmdLine := LCmdLine;
    UniqueString(LMutableCmdLine);
    if not CreateProcess(nil, PChar(LMutableCmdLine), nil, nil, True, CREATE_NO_WINDOW, nil,
      PChar(AWorkingDir), LStartupInfo, LProcessInfo) then
      Exit;
    try
      CloseHandle(LWritePipe);
      LWritePipe := 0;

      LOutStream := TMemoryStream.Create;
      try
        repeat
          LBytesRead := 0;
          if not ReadFile(LReadPipe, LBuffer, SizeOf(LBuffer), LBytesRead, nil) then
            Break;
          if LBytesRead = 0 then
            Break;
          LOutStream.WriteBuffer(LBuffer, LBytesRead);
        until False;

        WaitForSingleObject(LProcessInfo.hProcess, INFINITE);
        GetExitCodeProcess(LProcessInfo.hProcess, AExitCode);

        if LOutStream.Size > 0 then
        begin
          SetLength(LData, LOutStream.Size);
          LOutStream.Position := 0;
          LOutStream.ReadBuffer(LData[0], LOutStream.Size);
          Result := TEncoding.Default.GetString(LData);
        end;
      finally
        LOutStream.Free;
      end;
    finally
      CloseHandle(LProcessInfo.hThread);
      CloseHandle(LProcessInfo.hProcess);
    end;
  finally
    if LReadPipe <> 0 then
      CloseHandle(LReadPipe);
    if LWritePipe <> 0 then
      CloseHandle(LWritePipe);
  end;
end;

function TAssinarPDF.GetWindowsCertificateAliases: TStringList;
var
  LOutput: string;
  LLines: TStringList;
  LI: Integer;
  LAliasLine: string;
  LP: Integer;
  LExitCode: Cardinal;
begin
  Result := TStringList.Create;
  LOutput := ExecuteAndCaptureOutputWithExitCode(
    Format('"%s" -kst WINDOWS-MY -lk -q', [GetJSignPathEfetivo]),
    GetExeDir,
    LExitCode
  );

  LLines := TStringList.Create;
  try
    LLines.Text := LOutput;
    for LI := 0 to LLines.Count - 1 do
    begin
      LAliasLine := Trim(LLines[LI]);
      if LAliasLine = '' then
        Continue;
      if StartsText('INFORMA', LAliasLine) or StartsText('usage:', LAliasLine) then
        Continue;

      LP := Pos('=', LAliasLine);
      if LP > 0 then
        LAliasLine := Trim(Copy(LAliasLine, LP + 1, MaxInt));

      if (LAliasLine <> '') and (Result.IndexOf(LAliasLine) < 0) then
        Result.Add(LAliasLine);
    end;
  finally
    LLines.Free;
  end;
end;

function TAssinarPDF.ExtractDigits(const AValue: string): string;
var
  LI: Integer;
begin
  Result := '';
  for LI := 1 to Length(AValue) do
    if CharInSet(AValue[LI], ['0'..'9']) then
      Result := Result + AValue[LI];
end;

function TAssinarPDF.GetCertificateValidityByDocument: TStringList;
var
  LCmd: string;
  LOutput: string;
  LLines: TStringList;
  LI: Integer;
  LParts: TArray<string>;
  LDoc, LStatus, LExpDate: string;
  LExitCode: Cardinal;
begin
  Result := TStringList.Create;
  Result.NameValueSeparator := '=';

  LCmd :=
    'powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ' +
    '"Get-ChildItem Cert:\CurrentUser\My | ForEach-Object {' +
    ' $doc='''' ;' +
    ' if ($_.Subject -match ''(\d{14}|\d{11})'') { $doc=$matches[1] } ;' +
    ' $status = if ($_.NotAfter -lt (Get-Date)) { ''VENCIDO'' } else { ''VALIDO'' } ;' +
    ' ''{0};{1};{2}'' -f $doc,$status,$_.NotAfter.ToString(''yyyy-MM-dd'') }"';

  LOutput := ExecuteAndCaptureOutputWithExitCode(LCmd, GetExeDir, LExitCode);

  LLines := TStringList.Create;
  try
    LLines.Text := LOutput;
    for LI := 0 to LLines.Count - 1 do
    begin
      if Trim(LLines[LI]) = '' then
        Continue;
      LParts := LLines[LI].Split([';']);
      if Length(LParts) < 3 then
        Continue;

      LDoc := Trim(LParts[0]);
      LStatus := Trim(LParts[1]);
      LExpDate := Trim(LParts[2]);
      if LDoc = '' then
        Continue;

      Result.Values[LDoc] := LStatus + '|' + LExpDate;
    end;
  finally
    LLines.Free;
  end;
end;

function TAssinarPDF.SelectCertificateAlias(const AAliases: TStrings; out ASelectedAlias: string; out ASelectedIndex: Integer): Boolean;
var
  LDlg: TForm;
  LCb: TComboBox;
  LBtnOk: TButton;
  LBtnCancel: TButton;
  LValidityByDoc: TStringList;
  LI, LP, LItemIndex: Integer;
  LAliasItem, LDoc, LMeta, LStatus, LExpDate, LDisplayText: string;
  LParts: TArray<string>;
begin
  Result := False;
  ASelectedAlias := '';
  ASelectedIndex := -1;
  LValidityByDoc := GetCertificateValidityByDocument;

  LDlg := TForm.Create(nil);
  try
    LDlg.Caption := 'Selecionar Certificado';
    LDlg.Position := poScreenCenter;
    LDlg.Width := 760;
    LDlg.Height := 150;
    LDlg.BorderStyle := bsDialog;

    LCb := TComboBox.Create(LDlg);
    LCb.Parent := LDlg;
    LCb.Left := 12;
    LCb.Top := 12;
    LCb.Width := LDlg.ClientWidth - 24;
    LCb.Style := csDropDownList;
    LCb.Anchors := [akLeft, akTop, akRight];
    LCb.Items.Clear;
    for LI := 0 to AAliases.Count - 1 do
    begin
      LAliasItem := AAliases[LI];
      LP := LastDelimiter(':', LAliasItem);
      if LP > 0 then
        LDoc := ExtractDigits(Copy(LAliasItem, LP + 1, MaxInt))
      else
        LDoc := '';

      LMeta := LValidityByDoc.Values[LDoc];
      LDisplayText := LAliasItem;
      if LMeta <> '' then
      begin
        LParts := LMeta.Split(['|']);
        LStatus := '';
        LExpDate := '';
        if Length(LParts) > 0 then
          LStatus := LParts[0];
        if Length(LParts) > 1 then
          LExpDate := LParts[1];

        if SameText(LStatus, 'VENCIDO') then
          LDisplayText := LDisplayText + '  (VENCIDO em ' + LExpDate + ')'
        else if LExpDate <> '' then
          LDisplayText := LDisplayText + '  (valido ate ' + LExpDate + ')';
      end;

      LCb.Items.AddObject(LDisplayText, TObject(NativeInt(LI)));
    end;
    if LCb.Items.Count > 0 then
      LCb.ItemIndex := 0;

    LBtnOk := TButton.Create(LDlg);
    LBtnOk.Parent := LDlg;
    LBtnOk.Caption := 'OK';
    LBtnOk.ModalResult := mrOk;
    LBtnOk.Default := True;
    LBtnOk.Left := LDlg.ClientWidth - 180;
    LBtnOk.Top := 56;
    LBtnOk.Width := 75;
    LBtnOk.Anchors := [akTop, akRight];

    LBtnCancel := TButton.Create(LDlg);
    LBtnCancel.Parent := LDlg;
    LBtnCancel.Caption := 'Cancelar';
    LBtnCancel.ModalResult := mrCancel;
    LBtnCancel.Cancel := True;
    LBtnCancel.Left := LDlg.ClientWidth - 95;
    LBtnCancel.Top := 56;
    LBtnCancel.Width := 75;
    LBtnCancel.Anchors := [akTop, akRight];

    if LDlg.ShowModal = mrOk then
    begin
      if LCb.ItemIndex >= 0 then
      begin
        LItemIndex := NativeInt(LCb.Items.Objects[LCb.ItemIndex]);
        ASelectedAlias := AAliases[LItemIndex];
        ASelectedIndex := LItemIndex;

        LP := LastDelimiter(':', ASelectedAlias);
        if LP > 0 then
          LDoc := ExtractDigits(Copy(ASelectedAlias, LP + 1, MaxInt))
        else
          LDoc := '';
        LMeta := LValidityByDoc.Values[LDoc];
        if LMeta <> '' then
        begin
          LParts := LMeta.Split(['|']);
          if (Length(LParts) > 0) and SameText(LParts[0], 'VENCIDO') then
          begin
            LExpDate := '';
            if Length(LParts) > 1 then
              LExpDate := LParts[1];
            MessageDlg('O certificado selecionado esta vencido' +
              IfThen(LExpDate <> '', ' (expirou em ' + LExpDate + ')', '') + '.', mtWarning, [mbOK], 0);
            Exit(False);
          end;
        end;
        Result := True;
      end;
    end;
  finally
    LValidityByDoc.Free;
    LDlg.Free;
  end;
end;

function TAssinarPDF.Executar: TAssinarPDFResultado;
var
  LCmd: string;
  LExitCode: Cardinal;
  LJSignPath: string;
  LPastaSaida: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Sucesso := False;
  Result.CodigoSaida := Cardinal(-1);
  Result.CertificadoIndice := -1;
  Result.ArquivoOriginal := FArquivo;

  if Trim(FArquivo) = '' then
  begin
    Result.Mensagem := 'Arquivo PDF nao informado.';
    Exit;
  end;

  if not FileExists(FArquivo) then
  begin
    Result.Mensagem := 'Arquivo PDF nao encontrado: ' + FArquivo;
    Exit;
  end;

  LJSignPath := GetJSignPathEfetivo;
  if not FileExists(LJSignPath) then
  begin
    Result.Mensagem := 'JSignPdfC.exe nao encontrado: ' + LJSignPath;
    Exit;
  end;

  LPastaSaida := GetPastaSaidaEfetiva;
  ForceDirectories(LPastaSaida);

  if not FCertificado.Selecionado then
    SelecionarCertificado;
  if not FCertificado.Selecionado then
  begin
    Result.Mensagem := 'Assinatura cancelada pelo usuario.';
    Exit;
  end;

  LCmd := Format(
    '"%s" -kst WINDOWS-MY -ki %d -ha SHA256 -d "%s" -os "%s" "%s"',
    [LJSignPath, FCertificado.Indice, ExcludeTrailingPathDelimiter(LPastaSaida), FSufixoArquivo, FArquivo]
  );

  if not RunProcessAndWait(LCmd, GetExeDir, LExitCode) then
  begin
    Result.Mensagem := 'Falha ao executar processo de assinatura.';
    Exit;
  end;

  Result.CodigoSaida := LExitCode;
  Result.CertificadoAlias := FCertificado.Alias;
  Result.CertificadoIndice := FCertificado.Indice;
  Result.ArquivoAssinado := BuildSignedFileName;

  if (LExitCode <> 0) or (not FileExists(Result.ArquivoAssinado)) then
  begin
    Result.Mensagem := Format('Falha na assinatura. Codigo de saida: %d', [LExitCode]);
    Exit;
  end;

  Result.Sucesso := True;
  Result.Mensagem := 'PDF assinado com sucesso.';
end;

end.
