unit uStorage.Provider.Google;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient,
  System.JSON, System.NetEncoding, System.IOUtils,
  uStorage.ProviderIntf, uAnexo.Types;

type
  TGoogleStorageProvider = class(TInterfacedObject, IStorageProvider)
  private
    function CreateAccessToken(const AContext: TAnexoContext): string;
    function BuildMultipartBody(const AFilePath, AFolderId: string;
      out AContentType: string): TMemoryStream;
  public
    function UploadFiles(const AContext: TAnexoContext; const AOnProgress: TAnexoProgressProc;
      const AOnTransfer: TAnexoTransferProc): TUploadBatchResult;
    procedure DownloadFile(const AContext: TAnexoContext; const ARemotePath, ALocalFilePath: string);
    procedure DeleteFile(const AContext: TAnexoContext; const ARemotePath: string);
  end;

implementation

function JsonEscape(const AValue: string): string;
begin
  Result := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
end;

function GetFileSizeSafe(const AFilePath: string): Int64;
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

function TGoogleStorageProvider.CreateAccessToken(const AContext: TAnexoContext): string;
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LBody: TStringStream;
  LJson: TJSONObject;
  LTokenValue: TJSONValue;
  LBodyText: string;
begin
  LBodyText :=
    'client_id=' + TNetEncoding.URL.Encode(AContext.Credentials.GoogleClientId) + '&' +
    'client_secret=' + TNetEncoding.URL.Encode(AContext.Credentials.GoogleClientSecret) + '&' +
    'refresh_token=' + TNetEncoding.URL.Encode(AContext.Credentials.GoogleRefreshToken) + '&' +
    'grant_type=refresh_token';

  LClient := THTTPClient.Create;
  try
    LBody := TStringStream.Create(LBodyText, TEncoding.UTF8);
    try
      LResp := LClient.Post('https://oauth2.googleapis.com/token', LBody, nil,
        [TNameValuePair.Create('Content-Type', 'application/x-www-form-urlencoded')]);
    finally
      LBody.Free;
    end;

    if (LResp.StatusCode div 100) <> 2 then
      raise Exception.CreateFmt('Falha ao obter token Google. HTTP %d: %s',
        [LResp.StatusCode, LResp.ContentAsString(TEncoding.UTF8)]);

    LJson := TJSONObject.ParseJSONValue(LResp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
    try
      if LJson = nil then
        raise Exception.Create('Resposta invalida do OAuth Google.');
      LTokenValue := LJson.GetValue('access_token');
      if LTokenValue = nil then
        raise Exception.Create('access_token nao retornado pelo Google OAuth.');
      Result := LTokenValue.Value;
    finally
      LJson.Free;
    end;
  finally
    LClient.Free;
  end;
end;

function TGoogleStorageProvider.BuildMultipartBody(const AFilePath, AFolderId: string;
  out AContentType: string): TMemoryStream;
var
  LBoundary: string;
  LMetaJson: string;
  LPrefix: UTF8String;
  LSuffix: UTF8String;
  LFileStream: TFileStream;
begin
  LBoundary := 'anexo_nuvem_' + FormatDateTime('yyyymmddhhnnsszzz', Now) +
    '_' + IntToStr(Random(100000));
  AContentType := 'multipart/related; boundary=' + LBoundary;
  LMetaJson := '{"name":"' + JsonEscape(TPath.GetFileName(AFilePath)) + '","parents":["' +
    JsonEscape(AFolderId) + '"]}';

  LPrefix := UTF8String(
    '--' + LBoundary + #13#10 +
    'Content-Type: application/json; charset=UTF-8' + #13#10#13#10 +
    LMetaJson + #13#10 +
    '--' + LBoundary + #13#10 +
    'Content-Type: application/octet-stream' + #13#10#13#10);
  LSuffix := UTF8String(#13#10 + '--' + LBoundary + '--' + #13#10);

  Result := TMemoryStream.Create;
  Result.WriteBuffer(PAnsiChar(LPrefix)^, Length(LPrefix));

  LFileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
  try
    Result.CopyFrom(LFileStream, 0);
  finally
    LFileStream.Free;
  end;

  Result.WriteBuffer(PAnsiChar(LSuffix)^, Length(LSuffix));
  Result.Position := 0;
end;

function TGoogleStorageProvider.UploadFiles(const AContext: TAnexoContext;
  const AOnProgress: TAnexoProgressProc; const AOnTransfer: TAnexoTransferProc): TUploadBatchResult;
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LItem: TUploadItemResult;
  LFilePath: string;
  LContentType: string;
  LBody: TMemoryStream;
  LJsonResp: TJSONObject;
  LFileIdValue: TJSONValue;
  LAccessToken: string;
  I: Integer;
begin
  Result := TUploadBatchResult.Create;
  LAccessToken := CreateAccessToken(AContext);

  LClient := THTTPClient.Create;
  try
    for I := 0 to High(AContext.Arquivos) do
    begin
      LFilePath := AContext.Arquivos[I];

      LItem.FileName := TPath.GetFileName(LFilePath);
      LItem.RemotePath := '';
      LItem.FileSize := 0;
      LItem.Success := False;
      LItem.MessageText := '';

      LBody := nil;
      try
        LBody := BuildMultipartBody(LFilePath, AContext.Credentials.GoogleFolderId, LContentType);
        LItem.FileSize := GetFileSizeSafe(LFilePath);
        if Assigned(AOnTransfer) then
          AOnTransfer(LItem.FileName, LBody.Size, LBody.Size);

        LResp := LClient.Post(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
          LBody, nil,
          [TNameValuePair.Create('Authorization', 'Bearer ' + LAccessToken),
           TNameValuePair.Create('Content-Type', LContentType)]);

        if (LResp.StatusCode div 100) = 2 then
        begin
          LJsonResp := TJSONObject.ParseJSONValue(LResp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
          try
            if LJsonResp <> nil then
            begin
              LFileIdValue := LJsonResp.GetValue('id');
              if LFileIdValue <> nil then
                LItem.RemotePath := LFileIdValue.Value;
            end;
          finally
            LJsonResp.Free;
          end;
          LItem.Success := True;
          LItem.MessageText := 'Upload concluido.';
        end
        else
        begin
          LItem.Success := False;
          LItem.MessageText := Format('HTTP %d: %s',
            [LResp.StatusCode, LResp.ContentAsString(TEncoding.UTF8)]);
        end;
      except
        on E: Exception do
        begin
          LItem.Success := False;
          LItem.MessageText := E.Message;
        end;
      end;
      LBody.Free;

      Result.Add(LItem);
      if Assigned(AOnProgress) then
        AOnProgress(LItem, I + 1, Length(AContext.Arquivos));
    end;
  finally
    LClient.Free;
  end;
end;

procedure TGoogleStorageProvider.DownloadFile(const AContext: TAnexoContext;
  const ARemotePath, ALocalFilePath: string);
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LOut: TFileStream;
  LUrl: string;
  LAccessToken: string;
begin
  LAccessToken := CreateAccessToken(AContext);
  LUrl := 'https://www.googleapis.com/drive/v3/files/' +
    TNetEncoding.URL.Encode(ARemotePath) + '?alt=media';

  LClient := THTTPClient.Create;
  try
    LResp := LClient.Get(LUrl, nil,
      [TNameValuePair.Create('Authorization', 'Bearer ' + LAccessToken)]);
    if (LResp.StatusCode div 100) <> 2 then
      raise Exception.CreateFmt('Falha ao baixar arquivo. HTTP %d: %s',
        [LResp.StatusCode, LResp.ContentAsString(TEncoding.UTF8)]);

    ForceDirectories(ExtractFilePath(ALocalFilePath));
    LOut := TFileStream.Create(ALocalFilePath, fmCreate);
    try
      LOut.CopyFrom(LResp.ContentStream, 0);
    finally
      LOut.Free;
    end;
  finally
    LClient.Free;
  end;
end;

procedure TGoogleStorageProvider.DeleteFile(const AContext: TAnexoContext;
  const ARemotePath: string);
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LUrl: string;
  LAccessToken: string;
begin
  LAccessToken := CreateAccessToken(AContext);
  LUrl := 'https://www.googleapis.com/drive/v3/files/' +
    TNetEncoding.URL.Encode(ARemotePath);

  LClient := THTTPClient.Create;
  try
    LResp := LClient.Delete(LUrl, nil,
      [TNameValuePair.Create('Authorization', 'Bearer ' + LAccessToken)]);
    if (LResp.StatusCode div 100) <> 2 then
      raise Exception.CreateFmt('Falha ao apagar arquivo. HTTP %d: %s',
        [LResp.StatusCode, LResp.ContentAsString(TEncoding.UTF8)]);
  finally
    LClient.Free;
  end;
end;

end.

