unit uAnexo;

interface

uses
  uAnexo.Settings, uAnexo.Types;

type
  TAnexo = class
  private
    class function GetFileSizeSafe(const AFilePath: string): Int64; static;
    class function NormalizeSupabaseBaseUrl(const AUrl: string): string; static;
    class function CreateSupabaseAccessToken(const ASettings: TAnexoSettings): string; static;
    class function BuildContext(const ASettings: TAnexoSettings): TAnexoContext; static;
    class function BuildFriendlySupabaseError(const APrefix, ARawError: string;
      AMaxFileSizeMB: Integer = 0): string; static;
    class function GetPreviewFolder: string; static;
    class procedure CleanupPreviewFolder; static;
  public
    class function Execute: TUploadBatchResult; static;
    class procedure Configurar; static;
    class procedure Visualizar(const AChave, ANomeArquivo: string); static;
    class procedure Apagar(const AChave: string); static;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.Classes, System.JSON,
  System.Net.HttpClient, System.Net.URLClient, System.IOUtils, Vcl.Dialogs, Vcl.Forms,
  uAnexo.ConfigService, fAnexoConfig, fAnexoProgress, uStorage.Provider.Factory,
  uStorage.ProviderIntf, System.Types, uMensagem, uAnexo.Integracao;

class procedure TAnexo.Configurar;
begin
  ShowAnexoConfig;
end;

class function TAnexo.Execute: TUploadBatchResult;
var
  LSettings: TAnexoSettings;
  LContext: TAnexoContext;
  LDialog: TOpenDialog;
  LFiles: TArray<string>;
  LSingleFile: TArray<string>;
  LProvider: IStorageProvider;
  LProgress: TfAnexoProgress;
  LSummaryErrors: TStringList;
  LQueueItem: TAnexoQueueItem;
  LAccessToken: string;
  LResult: TUploadBatchResult;
  LItem: TUploadItemResult;
  LRawError: string;
  LMaxFileSizeMB: Integer;
  LMaxFileSizeBytes: Int64;
  LFileSize: Int64;
  LValidationMessage: string;
  LValidationAction: string;
  LNeedRetry: Boolean;
  LRetryRequested: Boolean;
  LTotalToProcess: Integer;
  LProcessed: Integer;
  LUploadDone: Boolean;
  LUploadError: string;
  LUploadResult: TUploadBatchResult;
  I: Integer;
begin
  Result := TUploadBatchResult.Create;

  LSettings := TAnexoConfigService.LoadSettings;
  try
    if LSettings.FIntegracao = aiSupabase then
      LAccessToken := CreateSupabaseAccessToken(LSettings)
    else
      LAccessToken := '';

    LDialog := TOpenDialog.Create(nil);
    try
      LDialog.Options := LDialog.Options + [ofAllowMultiSelect, ofFileMustExist];
      if not LDialog.Execute then
        Exit;
      SetLength(LFiles, LDialog.Files.Count);
      for I := 0 to LDialog.Files.Count - 1 do
        LFiles[I] := LDialog.Files[I];
    finally
      LDialog.Free;
    end;

    LContext := BuildContext(LSettings);
    try
      LContext.Credentials.SupabaseAccessToken := LAccessToken;
      LProvider := TStorageProviderFactory.CreateProvider(LContext.Integracao);

      LProgress := TfAnexoProgress.Create(nil);
      LSummaryErrors := TStringList.Create;
      try
        LProgress.Setup(LFiles);
        case LSettings.FIntegracao of
          aiSupabase: LMaxFileSizeMB := LSettings.FSupabaseMaxFileSizeMB;
          aiAwsS3: LMaxFileSizeMB := LSettings.FAwsMaxFileSizeMB;
          aiGoogleDrive, aiGoogleWorkspace: LMaxFileSizeMB := LSettings.FGoogleMaxFileSizeMB;
        else
          LMaxFileSizeMB := 0;
        end;
        LMaxFileSizeBytes := Int64(LMaxFileSizeMB) * 1024 * 1024;

        if LMaxFileSizeBytes > 0 then
        begin
          for I := 0 to High(LFiles) do
          begin
            if not TFile.Exists(LFiles[I]) then
              Continue;
            LFileSize := GetFileSizeSafe(LFiles[I]);
            if LFileSize > LMaxFileSizeBytes then
            begin
              LValidationMessage := Format('Arquivo com tamanho acima do limite configurado (%d MB).', [LMaxFileSizeMB]);
              LValidationAction := Format('Tamanho maior que limite de %d MB permitido.', [LMaxFileSizeMB]);
              LProgress.MarkValidationErrorByPath(LFiles[I], LValidationMessage, LValidationAction);
              LProgress.AppendErrorDetails(ExtractFileName(LFiles[I]),
                Format('{"status":"validation","error":"max_file_size","max_mb":%d,"file_size":%d}',
                [LMaxFileSizeMB, LFileSize]));
            end;
          end;
        end;

        LProgress.Show;
        LProgress.Update;
        Application.ProcessMessages;

        LNeedRetry := True;
        while LNeedRetry and LProgress.Visible do
        begin
          LSummaryErrors.Clear;
          LTotalToProcess := LProgress.CountPendingItems;
          LProcessed := 0;
          LProgress.BeginProcessing;
          try

            while LProgress.Visible do
            begin
              LQueueItem := LProgress.NextPendingItem;
              if LQueueItem = nil then
                Break;

              TMensagem.SetAltura(90).SetLargura(320).Execute('Enviando Arquivo...');
              LProgress.MarkUploading(LQueueItem);
              SetLength(LSingleFile, 1);
              LSingleFile[0] := LQueueItem.FFilePath;
              LContext.Arquivos := LSingleFile;

              LUploadDone := False;
              LUploadError := '';
              LUploadResult := nil;
              TThread.CreateAnonymousThread(
                procedure
                begin
                  try
                    LUploadResult := LProvider.UploadFiles(LContext, nil, nil);
                  except
                    on E: Exception do
                      LUploadError := E.Message;
                  end;
                  LUploadDone := True;
                end).Start;

              while not LUploadDone do
              begin
                TMensagem.Atualizar;
                Application.ProcessMessages;
                Sleep(25);
              end;

              if LUploadError <> '' then
                raise Exception.Create(LUploadError);

              LResult := LUploadResult;
              try
                if LResult.Items.Count > 0 then
                begin
                  LItem := LResult.Items[0];
                  if LItem.Success then
                  begin
                    LProgress.MarkResult(LQueueItem, True, 'Upload concluido.');
                    Result.Add(LItem);
                  end
                  else
                  begin
                    LRawError := LItem.MessageText;
                    LItem.MessageText := BuildFriendlySupabaseError('Falha no upload do arquivo.',
                      LItem.MessageText, LSettings.FSupabaseMaxFileSizeMB);
                    LProgress.MarkResult(LQueueItem, False, LItem.MessageText);
                    LProgress.AppendErrorDetails(LQueueItem.FFileName, LRawError);
                    LSummaryErrors.Add('- ' + LQueueItem.FFileName + ':' + sLineBreak + LItem.MessageText);
                  end;
                end;
              finally
                LResult.Free;
              end;
              TMensagem.Finalizar;

              Inc(LProcessed);
              if LTotalToProcess > 0 then
                LProgress.SetOverallProgress(Round((LProcessed * 100) / LTotalToProcess), '');

              Application.ProcessMessages;
            end;
          finally
            LProgress.EndProcessing;
          end;

          LProgress.btnCancelarPendentes.Enabled := False;
          LProgress.btnTentarNovamente.Enabled := LProgress.HasRetryableItems;
          LProgress.btnFechar.Enabled := True;

          if LSummaryErrors.Count = 0 then
            LProgress.lblResumo.Caption := Format('Upload concluido. %d arquivo(s) enviado(s).', [Result.Items.Count])
          else
            LProgress.lblResumo.Caption := 'Upload finalizado com erros. Revise a lista.';

          LRetryRequested := False;
          while LProgress.Visible do
          begin
            Application.ProcessMessages;
            if LProgress.ConsumeRetryRequested then
            begin
              LRetryRequested := True;
              Break;
            end;
          end;

          if LRetryRequested then
          begin
            LProgress.PrepareRetryFailedItems;
            LProgress.btnCancelarPendentes.Enabled := True;
            LProgress.btnTentarNovamente.Enabled := False;
            LProgress.btnFechar.Enabled := False;
          end;

          LNeedRetry := LRetryRequested;
        end;
      finally
        TMensagem.Finalizar;
        LSummaryErrors.Free;
        LProgress.Free;
      end;
    finally
      LContext.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

class function TAnexo.GetFileSizeSafe(const AFilePath: string): Int64;
var
  LStream: TFileStream;
begin
  Result := 0;
  if not TFile.Exists(AFilePath) then
    Exit;
  LStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyNone);
  try
    Result := LStream.Size;
  finally
    LStream.Free;
  end;
end;

class procedure TAnexo.Visualizar(const AChave, ANomeArquivo: string);
var
  LSettings: TAnexoSettings;
  LContext: TAnexoContext;
  LProvider: IStorageProvider;
  LToken: string;
  LPreviewFolder: string;
  LLocalFile: string;
begin
  if Trim(AChave) = '' then
    Exit;

  LSettings := TAnexoConfigService.LoadSettings;
  try
    if LSettings.FIntegracao = aiSupabase then
      LToken := CreateSupabaseAccessToken(LSettings)
    else
      LToken := '';

    CleanupPreviewFolder;
    LPreviewFolder := GetPreviewFolder;
    ForceDirectories(LPreviewFolder);
    LLocalFile := TPath.Combine(LPreviewFolder, ANomeArquivo);

    LContext := BuildContext(LSettings);
    try
      LContext.Credentials.SupabaseAccessToken := LToken;
      LProvider := TStorageProviderFactory.CreateProvider(LContext.Integracao);
      LProvider.DownloadFile(LContext, AChave, LLocalFile);
    finally
      LContext.Free;
    end;

    ShellExecute(0, 'open', PChar(LLocalFile), nil, nil, SW_SHOWNORMAL);
  finally
    LSettings.Free;
  end;
end;

class procedure TAnexo.Apagar(const AChave: string);
var
  LSettings: TAnexoSettings;
  LContext: TAnexoContext;
  LProvider: IStorageProvider;
  LToken: string;
begin
  if Trim(AChave) = '' then
    Exit;

  LSettings := TAnexoConfigService.LoadSettings;
  try
    if LSettings.FIntegracao = aiSupabase then
      LToken := CreateSupabaseAccessToken(LSettings)
    else
      LToken := '';

    LContext := BuildContext(LSettings);
    try
      LContext.Credentials.SupabaseAccessToken := LToken;
      LProvider := TStorageProviderFactory.CreateProvider(LContext.Integracao);
      LProvider.DeleteFile(LContext, AChave);
    finally
      LContext.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

class function TAnexo.BuildContext(const ASettings: TAnexoSettings): TAnexoContext;
begin
  Result := TAnexoContext.Create;
  Result.Integracao := ASettings.FIntegracao;
  Result.TenantId := ASettings.FTenantId;
  Result.UserId := ASettings.FUserId;
  Result.Credentials.SupabaseUrl := NormalizeSupabaseBaseUrl(ASettings.FSupabaseUrl);
  Result.Credentials.SupabaseAnonKey := ASettings.FSupabaseAnonKey;
  Result.Credentials.Bucket := ASettings.FSupabaseBucket;
  Result.Credentials.AwsEndpoint := ASettings.FAwsEndpoint;
  Result.Credentials.AwsRegion := ASettings.FAwsRegion;
  Result.Credentials.AwsBucket := ASettings.FAwsBucket;
  Result.Credentials.AwsAccessKey := ASettings.FAwsAccessKey;
  Result.Credentials.AwsSecretKey := ASettings.FAwsSecretKey;
  Result.Credentials.GoogleClientId := ASettings.FGoogleClientId;
  Result.Credentials.GoogleClientSecret := ASettings.FGoogleClientSecret;
  Result.Credentials.GoogleFolderId := ASettings.FGoogleFolderId;
  Result.Credentials.GoogleRefreshToken := ASettings.FGoogleRefreshToken;
  SetLength(Result.Arquivos, 1);
  Result.Arquivos[0] := 'dummy';
end;

class function TAnexo.NormalizeSupabaseBaseUrl(const AUrl: string): string;
var
  LUrl: string;
begin
  LUrl := Trim(AUrl);
  LUrl := StringReplace(LUrl, '/rest/v1/', '', [rfIgnoreCase]);
  LUrl := StringReplace(LUrl, '/rest/v1', '', [rfIgnoreCase]);
  while (LUrl <> '') and (LUrl[Length(LUrl)] = '/') do
    Delete(LUrl, Length(LUrl), 1);
  Result := LUrl;
end;

class function TAnexo.CreateSupabaseAccessToken(const ASettings: TAnexoSettings): string;
var
  LClient: THTTPClient;
  LHeaders: TNetHeaders;
  LResp: IHTTPResponse;
  LJsonBody: string;
  LBodyStream: TStringStream;
  LJsonResp: TJSONObject;
  LTokenValue: TJSONValue;
  LUrl: string;
begin
  if Trim(ASettings.FSupabaseEmail) = '' then
    raise Exception.Create('Login Supabase obrigatorio em Configuracoes.');
  if Trim(ASettings.FSupabasePassword) = '' then
    raise Exception.Create('Senha Supabase obrigatoria em Configuracoes.');
  if Trim(ASettings.FSupabaseAnonKey) = '' then
    raise Exception.Create('Anon key obrigatoria em Configuracoes.');

  LUrl := NormalizeSupabaseBaseUrl(ASettings.FSupabaseUrl);
  LClient := THTTPClient.Create;
  try
    SetLength(LHeaders, 2);
    LHeaders[0] := TNameValuePair.Create('apikey', ASettings.FSupabaseAnonKey);
    LHeaders[1] := TNameValuePair.Create('Content-Type', 'application/json');
    LJsonBody := Format('{"email":"%s","password":"%s"}',
      [StringReplace(ASettings.FSupabaseEmail, '"', '\"', [rfReplaceAll]),
       StringReplace(ASettings.FSupabasePassword, '"', '\"', [rfReplaceAll])]);
    LBodyStream := TStringStream.Create(LJsonBody, TEncoding.UTF8);
    try
      LResp := LClient.Post(LUrl + '/auth/v1/token?grant_type=password', LBodyStream, nil, LHeaders);
    finally
      LBodyStream.Free;
    end;

    if (LResp.StatusCode div 100) <> 2 then
      raise Exception.Create(BuildFriendlySupabaseError(
        Format('Falha no login Supabase. HTTP %d.', [LResp.StatusCode]),
        LResp.ContentAsString(TEncoding.UTF8)));

    LJsonResp := TJSONObject.ParseJSONValue(LResp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
    try
      LTokenValue := LJsonResp.GetValue('access_token');
      if LTokenValue = nil then
        raise Exception.Create('access_token nao retornado pelo Supabase.');
      Result := LTokenValue.Value;
    finally
      LJsonResp.Free;
    end;
  finally
    LClient.Free;
  end;
end;

class function TAnexo.BuildFriendlySupabaseError(const APrefix, ARawError: string;
  AMaxFileSizeMB: Integer): string;
var
  LRaw: string;
  LLower: string;
  LFriendly: string;
begin
  LRaw := Trim(ARawError);
  LLower := LowerCase(LRaw);
  if Pos('bucket not found', LLower) > 0 then
    LFriendly := 'Bucket nao encontrado! Verifique se o nome esta exatamente igual ao criado na nuvem.'
  else if (Pos('"statuscode":"413"', LLower) > 0) or
          (Pos('payload too large', LLower) > 0) or
          (Pos('maximum allowed size', LLower) > 0) then
  begin
    LFriendly := 'Tamanho maximo excedido.';
    if AMaxFileSizeMB > 0 then
      LFriendly := LFriendly + ' Limite configurado: ' + IntToStr(AMaxFileSizeMB) + ' MB.';
  end
  else if (Pos('"statuscode":"409"', LLower) > 0) or (Pos('already exists', LLower) > 0) or
    (Pos('duplicate', LLower) > 0) or (Pos('resource already exists', LLower) > 0) then
    LFriendly := 'Arquivo ja anexado. Apague o arquivo existente para enviar novamente.'
  else if (Pos('"statuscode":"403"', LLower) > 0) and
    (Pos('new row violates row-level security policy', LLower) > 0) then
    LFriendly := 'Permissao insuficiente para criar/sobrescrever arquivo neste bucket. Verifique as policies (INSERT/SELECT/UPDATE/DELETE).'
  else
    LFriendly := 'Falha na comunicacao com a nuvem. Revise as configuracoes e tente novamente.';
  Result := APrefix + sLineBreak + LFriendly;
  if LRaw <> '' then
    Result := Result + sLineBreak + sLineBreak + 'Mais detalhes:' + sLineBreak + LRaw;
end;

class function TAnexo.GetPreviewFolder: string;
begin
  Result := IncludeTrailingPathDelimiter(TPath.GetTempPath) + 'AnexoNuvel\preview';
end;

class procedure TAnexo.CleanupPreviewFolder;
var
  LFolder: string;
  LFiles: TStringDynArray;
  LFile: string;
begin
  LFolder := GetPreviewFolder;
  if not TDirectory.Exists(LFolder) then
    Exit;
  LFiles := TDirectory.GetFiles(LFolder);
  for LFile in LFiles do
  begin
    try
      TFile.Delete(LFile);
    except
      // ignora arquivo em uso
    end;
  end;
end;

end.

