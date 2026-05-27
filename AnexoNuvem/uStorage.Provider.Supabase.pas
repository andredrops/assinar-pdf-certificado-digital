unit uStorage.Provider.Supabase;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient,
  System.IOUtils, System.NetEncoding,
  uStorage.ProviderIntf, uAnexo.Types;

type
  TUploadProgressStream = class(TFileStream)
  private
    FFileName: string;
    FOnTransfer: TAnexoTransferProc;
    FTotal: Int64;
    FSent: Int64;
  public
    constructor Create(const AFileName: string; AMode: Word; const AOnTransfer: TAnexoTransferProc);
    function Read(var Buffer; Count: Longint): Longint; override;
  end;

  TSupabaseStorageProvider = class(TInterfacedObject, IStorageProvider)
  private
    function NormalizeFileNameForKey(const AFileName: string): string;
    function BuildUploadUrl(const AContext: TAnexoContext; const AFileName: string): string;
    function BuildRemotePath(const AContext: TAnexoContext; const AFileName: string): string;
  public
    function UploadFiles(const AContext: TAnexoContext; const AOnProgress: TAnexoProgressProc;
      const AOnTransfer: TAnexoTransferProc): TUploadBatchResult;
    procedure DownloadFile(const AContext: TAnexoContext; const ARemotePath, ALocalFilePath: string);
    procedure DeleteFile(const AContext: TAnexoContext; const ARemotePath: string);
  end;

implementation

function ReplaceChars(const AValue, AFromChars, AToChars: string): string;
var
  I: Integer;
begin
  Result := AValue;
  for I := 1 to Length(AFromChars) do
    Result := StringReplace(Result, AFromChars[I], AToChars[I], [rfReplaceAll]);
end;

{ TUploadProgressStream }

constructor TUploadProgressStream.Create(const AFileName: string; AMode: Word;
  const AOnTransfer: TAnexoTransferProc);
begin
  inherited Create(AFileName, AMode);
  FFileName := TPath.GetFileName(AFileName);
  FOnTransfer := AOnTransfer;
  FTotal := Size;
  FSent := 0;
end;

function TUploadProgressStream.Read(var Buffer; Count: Integer): Longint;
begin
  Result := inherited Read(Buffer, Count);
  if Result > 0 then
  begin
    Inc(FSent, Result);
    if Assigned(FOnTransfer) then
      FOnTransfer(FFileName, FSent, FTotal);
  end;
end;

function TSupabaseStorageProvider.BuildRemotePath(const AContext: TAnexoContext;
  const AFileName: string): string;
var
  LSafeName: string;
begin
  LSafeName := NormalizeFileNameForKey(AFileName);
  Result := AContext.TenantId + '/' + AContext.UserId + '/' + TNetEncoding.URL.Encode(LSafeName);
end;

function TSupabaseStorageProvider.NormalizeFileNameForKey(const AFileName: string): string;
var
  LNameOnly: string;
  LExt: string;
  LRaw: string;
  LOut: string;
  C: Char;
begin
  LNameOnly := TPath.GetFileNameWithoutExtension(AFileName);
  LExt := TPath.GetExtension(AFileName);

  LRaw := LNameOnly;
  // remove acentuacao comum pt-BR
  LRaw := ReplaceChars(LRaw, 'áàâãäÁÀÂÃÄ', 'aaaaaAAAAA');
  LRaw := ReplaceChars(LRaw, 'éèêëÉÈÊË', 'eeeeEEEE');
  LRaw := ReplaceChars(LRaw, 'íìîïÍÌÎÏ', 'iiiiIIII');
  LRaw := ReplaceChars(LRaw, 'óòôõöÓÒÔÕÖ', 'oooooOOOOO');
  LRaw := ReplaceChars(LRaw, 'úùûüÚÙÛÜ', 'uuuuUUUU');
  LRaw := ReplaceChars(LRaw, 'çÇ', 'cC');
  LRaw := StringReplace(LRaw, ' ', '_', [rfReplaceAll]);

  LOut := '';
  for C in LRaw do
  begin
    if CharInSet(C, ['a'..'z', 'A'..'Z', '0'..'9', '_', '-', '.']) then
      LOut := LOut + C;
  end;

  if Trim(LOut) = '' then
    LOut := 'arquivo';

  if LExt <> '' then
    Result := LOut + LExt
  else
    Result := LOut;
end;

function TSupabaseStorageProvider.BuildUploadUrl(const AContext: TAnexoContext;
  const AFileName: string): string;
var
  LBase: string;
begin
  LBase := AContext.Credentials.SupabaseUrl;
  while (LBase <> '') and (LBase[Length(LBase)] = '/') do
    Delete(LBase, Length(LBase), 1);
  Result := LBase + '/storage/v1/object/' + AContext.Credentials.Bucket + '/' +
    BuildRemotePath(AContext, AFileName);
end;

function TSupabaseStorageProvider.UploadFiles(const AContext: TAnexoContext;
  const AOnProgress: TAnexoProgressProc; const AOnTransfer: TAnexoTransferProc): TUploadBatchResult;
var
  LClient: THTTPClient;
  LFileStream: TUploadProgressStream;
  LResp: IHTTPResponse;
  LFilePath: string;
  LFileName: string;
  LItem: TUploadItemResult;
  LHeaders: TNetHeaders;
  I: Integer;
begin
  Result := TUploadBatchResult.Create;
  LClient := THTTPClient.Create;
  try
    SetLength(LHeaders, 4);
    LHeaders[0] := TNameValuePair.Create('apikey', AContext.Credentials.SupabaseAnonKey);
    LHeaders[1] := TNameValuePair.Create('Authorization', 'Bearer ' + AContext.Credentials.SupabaseAccessToken);
    LHeaders[2] := TNameValuePair.Create('x-upsert', 'false');
    LHeaders[3] := TNameValuePair.Create('Content-Type', 'application/octet-stream');

    for I := 0 to High(AContext.Arquivos) do
    begin
      LFilePath := AContext.Arquivos[I];
      LFileName := TPath.GetFileName(LFilePath);

      LItem.FileName := LFileName;
      LItem.RemotePath := BuildRemotePath(AContext, LFileName);
      LItem.FileSize := 0;
      LItem.Success := False;
      LItem.MessageText := '';

      LFileStream := TUploadProgressStream.Create(LFilePath, fmOpenRead or fmShareDenyWrite, AOnTransfer);
      try
        LItem.FileSize := LFileStream.Size;
        LResp := LClient.Post(BuildUploadUrl(AContext, LFileName), LFileStream, nil, LHeaders);
        if (LResp.StatusCode div 100) = 2 then
        begin
          LItem.Success := True;
          LItem.MessageText := 'Upload concluido.';
        end
        else
        begin
          LItem.Success := False;
          LItem.MessageText := Format('HTTP %d: %s', [LResp.StatusCode, LResp.ContentAsString(TEncoding.UTF8)]);
        end;
      except
        on E: Exception do
        begin
          LItem.Success := False;
          LItem.MessageText := E.Message;
        end;
      end;
      LFileStream.Free;

      Result.Add(LItem);
      if Assigned(AOnProgress) then
        AOnProgress(LItem, I + 1, Length(AContext.Arquivos));
    end;
  finally
    LClient.Free;
  end;
end;

procedure TSupabaseStorageProvider.DeleteFile(const AContext: TAnexoContext;
  const ARemotePath: string);
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LHeaders: TNetHeaders;
  LBase: string;
  LUrl: string;
begin
  LClient := THTTPClient.Create;
  try
    LBase := AContext.Credentials.SupabaseUrl;
    while (LBase <> '') and (LBase[Length(LBase)] = '/') do
      Delete(LBase, Length(LBase), 1);
    LUrl := LBase + '/storage/v1/object/' + AContext.Credentials.Bucket + '/' + ARemotePath;

    SetLength(LHeaders, 2);
    LHeaders[0] := TNameValuePair.Create('apikey', AContext.Credentials.SupabaseAnonKey);
    LHeaders[1] := TNameValuePair.Create('Authorization', 'Bearer ' + AContext.Credentials.SupabaseAccessToken);
    LResp := LClient.Delete(LUrl, nil, LHeaders);

    if (LResp.StatusCode div 100) <> 2 then
      raise Exception.CreateFmt('Falha ao apagar arquivo. HTTP %d: %s',
        [LResp.StatusCode, LResp.ContentAsString(TEncoding.UTF8)]);
  finally
    LClient.Free;
  end;
end;

procedure TSupabaseStorageProvider.DownloadFile(const AContext: TAnexoContext;
  const ARemotePath, ALocalFilePath: string);
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LHeaders: TNetHeaders;
  LOut: TFileStream;
  LBase: string;
  LUrl: string;
begin
  LBase := AContext.Credentials.SupabaseUrl;
  while (LBase <> '') and (LBase[Length(LBase)] = '/') do
    Delete(LBase, Length(LBase), 1);
  LUrl := LBase + '/storage/v1/object/authenticated/' + AContext.Credentials.Bucket + '/' + ARemotePath;

  LClient := THTTPClient.Create;
  try
    SetLength(LHeaders, 2);
    LHeaders[0] := TNameValuePair.Create('apikey', AContext.Credentials.SupabaseAnonKey);
    LHeaders[1] := TNameValuePair.Create('Authorization', 'Bearer ' + AContext.Credentials.SupabaseAccessToken);
    LResp := LClient.Get(LUrl, nil, LHeaders);
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

end.

