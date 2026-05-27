unit uStorage.Provider.AwsS3;

interface

uses
  System.SysUtils, System.Classes, System.Net.HttpClient, System.Net.URLClient,
  System.IOUtils, System.Hash, System.DateUtils, System.NetEncoding,
  uStorage.ProviderIntf, uAnexo.Types;

type
  TAwsS3StorageProvider = class(TInterfacedObject, IStorageProvider)
  private
    function BuildFriendlyAwsError(const APrefix, ARawError: string): string;
    function NormalizeEndpoint(const AEndpoint: string): string;
    function ExtractHost(const AEndpoint: string): string;
    function UriEncodeAws(const AValue: string; AEncodeSlash: Boolean): string;
    function NormalizeFileNameForKey(const AFileName: string): string;
    function BuildRemotePath(const AContext: TAnexoContext; const AFileName: string): string;
    function BuildObjectUrl(const AContext: TAnexoContext; const ARemotePath: string): string;
    function BytesToHex(const ABytes: TBytes): string;
    function Sha256Hex(const ABytes: TBytes): string;
    function HmacSha256(const AKey: TBytes; const AData: string): TBytes;
    procedure SignRequest(const AContext: TAnexoContext; const AMethod, ACanonicalUri,
      APayloadHash: string; const AHeaders: TStrings);
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

function TAwsS3StorageProvider.BuildFriendlyAwsError(const APrefix, ARawError: string): string;
var
  LRaw: string;
  LLower: string;
  LFriendly: string;
begin
  LRaw := Trim(ARawError);
  LLower := LowerCase(LRaw);

  if (Pos('accessdenied', LLower) > 0) or
     (Pos('not authorized to perform', LLower) > 0) then
    LFriendly := 'Permissao negada no AWS S3. Verifique a policy IAM (s3:PutObject, s3:GetObject, s3:DeleteObject, s3:ListBucket).'
  else if (Pos('signaturedoesnotmatch', LLower) > 0) then
    LFriendly := 'Assinatura AWS invalida. Revise endpoint, region, access key e secret key.'
  else if (Pos('nosuchbucket', LLower) > 0) or
          (Pos('the specified bucket does not exist', LLower) > 0) then
    LFriendly := 'Bucket AWS nao encontrado. Verifique o nome do bucket e a regiao.'
  else if (Pos('invalidaccesskeyid', LLower) > 0) or
          (Pos('security token included in the request is invalid', LLower) > 0) then
    LFriendly := 'Credenciais AWS invalidas. Verifique Access Key e Secret Key.'
  else if (Pos('requesttimetooskewed', LLower) > 0) then
    LFriendly := 'Data/hora da maquina fora de sincronia. Ajuste o relogio do sistema e tente novamente.'
  else
    LFriendly := 'Falha na comunicacao com AWS S3. Revise as configuracoes e tente novamente.';

  Result := APrefix + sLineBreak + LFriendly;
  if LRaw <> '' then
    Result := Result + sLineBreak + sLineBreak + 'Mais detalhes:' + sLineBreak + LRaw;
end;

function TAwsS3StorageProvider.NormalizeEndpoint(const AEndpoint: string): string;
begin
  Result := Trim(AEndpoint);
  if Result = '' then
    Exit;
  if (Pos('http://', LowerCase(Result)) <> 1) and
     (Pos('https://', LowerCase(Result)) <> 1) then
    Result := 'https://' + Result;
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function TAwsS3StorageProvider.ExtractHost(const AEndpoint: string): string;
var
  L: string;
  P: Integer;
begin
  L := NormalizeEndpoint(AEndpoint);
  if Pos('://', L) > 0 then
    L := Copy(L, Pos('://', L) + 3, MaxInt);
  P := Pos('/', L);
  if P > 0 then
    L := Copy(L, 1, P - 1);
  Result := LowerCase(L);
end;

function TAwsS3StorageProvider.UriEncodeAws(const AValue: string; AEncodeSlash: Boolean): string;
var
  I: Integer;
  B: TBytes;
  C: Byte;
begin
  Result := '';
  B := TEncoding.UTF8.GetBytes(AValue);
  for I := 0 to High(B) do
  begin
    C := B[I];
    if ((C >= Ord('A')) and (C <= Ord('Z'))) or
       ((C >= Ord('a')) and (C <= Ord('z'))) or
       ((C >= Ord('0')) and (C <= Ord('9'))) or
       (C = Ord('-')) or (C = Ord('_')) or (C = Ord('.')) or (C = Ord('~')) then
      Result := Result + Char(C)
    else if (C = Ord('/')) and (not AEncodeSlash) then
      Result := Result + '/'
    else
      Result := Result + '%' + IntToHex(C, 2);
  end;
end;

function TAwsS3StorageProvider.NormalizeFileNameForKey(const AFileName: string): string;
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
  LRaw := ReplaceChars(LRaw, 'áàâãäÁÀÂÃÄ', 'aaaaaAAAAA');
  LRaw := ReplaceChars(LRaw, 'éèêëÉÈÊË', 'eeeeEEEE');
  LRaw := ReplaceChars(LRaw, 'íìîïÍÌÎÏ', 'iiiiIIII');
  LRaw := ReplaceChars(LRaw, 'óòôõöÓÒÔÕÖ', 'oooooOOOOO');
  LRaw := ReplaceChars(LRaw, 'úùûüÚÙÛÜ', 'uuuuUUUU');
  LRaw := ReplaceChars(LRaw, 'çÇ', 'cC');
  LRaw := StringReplace(LRaw, ' ', '_', [rfReplaceAll]);

  LOut := '';
  for C in LRaw do
    if CharInSet(C, ['a'..'z', 'A'..'Z', '0'..'9', '_', '-', '.']) then
      LOut := LOut + C;

  if Trim(LOut) = '' then
    LOut := 'arquivo';

  Result := LOut + LExt;
end;

function TAwsS3StorageProvider.BuildRemotePath(const AContext: TAnexoContext;
  const AFileName: string): string;
begin
  Result := AContext.TenantId + '/' + AContext.UserId + '/' +
    NormalizeFileNameForKey(AFileName);
end;

function TAwsS3StorageProvider.BuildObjectUrl(const AContext: TAnexoContext;
  const ARemotePath: string): string;
var
  LBase: string;
  LPath: string;
begin
  LBase := NormalizeEndpoint(AContext.Credentials.AwsEndpoint);
  LPath := '/' + AContext.Credentials.AwsBucket + '/' + UriEncodeAws(ARemotePath, False);
  Result := LBase + LPath;
end;

function TAwsS3StorageProvider.BytesToHex(const ABytes: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(ABytes) do
    Result := Result + IntToHex(ABytes[I], 2);
  Result := LowerCase(Result);
end;

function TAwsS3StorageProvider.Sha256Hex(const ABytes: TBytes): string;
var
  LHash: THashSHA2;
begin
  LHash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  LHash.Update(ABytes);
  Result := BytesToHex(LHash.HashAsBytes);
end;

function TAwsS3StorageProvider.HmacSha256(const AKey: TBytes; const AData: string): TBytes;
begin
  Result := THashSHA2.GetHMACAsBytes(TEncoding.UTF8.GetBytes(AData), AKey, THashSHA2.TSHA2Version.SHA256);
end;

procedure TAwsS3StorageProvider.SignRequest(const AContext: TAnexoContext; const AMethod,
  ACanonicalUri, APayloadHash: string; const AHeaders: TStrings);
const
  CService = 's3';
  CAlgorithm = 'AWS4-HMAC-SHA256';
var
  LRegion: string;
  LHost: string;
  LUtc: TDateTime;
  LAmzDate: string;
  LDateStamp: string;
  LCanonicalHeaders: string;
  LSignedHeaders: string;
  LCanonicalRequest: string;
  LCredentialScope: string;
  LStringToSign: string;
  LSecret: TBytes;
  LDateKey: TBytes;
  LRegionKey: TBytes;
  LServiceKey: TBytes;
  LSigningKey: TBytes;
  LSignature: string;
begin
  LRegion := Trim(AContext.Credentials.AwsRegion);
  if LRegion = '' then
    LRegion := 'sa-east-1';
  LHost := ExtractHost(AContext.Credentials.AwsEndpoint);
  LUtc := TTimeZone.Local.ToUniversalTime(Now);
  LAmzDate := FormatDateTime('yyyymmdd"T"hhnnss"Z"', LUtc);
  LDateStamp := FormatDateTime('yyyymmdd', LUtc);

  AHeaders.Values['Host'] := LHost;
  AHeaders.Values['x-amz-content-sha256'] := APayloadHash;
  AHeaders.Values['x-amz-date'] := LAmzDate;

  LCanonicalHeaders :=
    'host:' + LowerCase(LHost) + #10 +
    'x-amz-content-sha256:' + APayloadHash + #10 +
    'x-amz-date:' + LAmzDate + #10;
  LSignedHeaders := 'host;x-amz-content-sha256;x-amz-date';
  LCanonicalRequest :=
    UpperCase(AMethod) + #10 +
    ACanonicalUri + #10 +
    '' + #10 +
    LCanonicalHeaders + #10 +
    LSignedHeaders + #10 +
    APayloadHash;

  LCredentialScope := LDateStamp + '/' + LRegion + '/' + CService + '/aws4_request';
  LStringToSign :=
    CAlgorithm + #10 +
    LAmzDate + #10 +
    LCredentialScope + #10 +
    Sha256Hex(TEncoding.UTF8.GetBytes(LCanonicalRequest));

  LSecret := TEncoding.UTF8.GetBytes('AWS4' + AContext.Credentials.AwsSecretKey);
  LDateKey := HmacSha256(LSecret, LDateStamp);
  LRegionKey := HmacSha256(LDateKey, LRegion);
  LServiceKey := HmacSha256(LRegionKey, CService);
  LSigningKey := HmacSha256(LServiceKey, 'aws4_request');
  LSignature := BytesToHex(HmacSha256(LSigningKey, LStringToSign));

  AHeaders.Values['Authorization'] :=
    CAlgorithm + ' ' +
    'Credential=' + AContext.Credentials.AwsAccessKey + '/' + LCredentialScope + ', ' +
    'SignedHeaders=' + LSignedHeaders + ', ' +
    'Signature=' + LSignature;
end;

function TAwsS3StorageProvider.UploadFiles(const AContext: TAnexoContext;
  const AOnProgress: TAnexoProgressProc; const AOnTransfer: TAnexoTransferProc): TUploadBatchResult;
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LFilePath: string;
  LFileName: string;
  LRemotePath: string;
  LCanonicalUri: string;
  LPayload: TBytes;
  LPayloadHash: string;
  LHeaders: TStringList;
  LNetHeaders: TNetHeaders;
  LStream: TFileStream;
  LItem: TUploadItemResult;
  I: Integer;
begin
  Result := TUploadBatchResult.Create;
  LClient := THTTPClient.Create;
  try
    for I := 0 to High(AContext.Arquivos) do
    begin
      LFilePath := AContext.Arquivos[I];
      LFileName := TPath.GetFileName(LFilePath);
      LRemotePath := BuildRemotePath(AContext, LFileName);
      LCanonicalUri := '/' + AContext.Credentials.AwsBucket + '/' + UriEncodeAws(LRemotePath, False);
      LPayload := TFile.ReadAllBytes(LFilePath);
      LPayloadHash := Sha256Hex(LPayload);

      LHeaders := TStringList.Create;
      try
        SignRequest(AContext, 'PUT', LCanonicalUri, LPayloadHash, LHeaders);
        SetLength(LNetHeaders, 5);
        LNetHeaders[0] := TNameValuePair.Create('Host', LHeaders.Values['Host']);
        LNetHeaders[1] := TNameValuePair.Create('x-amz-content-sha256', LHeaders.Values['x-amz-content-sha256']);
        LNetHeaders[2] := TNameValuePair.Create('x-amz-date', LHeaders.Values['x-amz-date']);
        LNetHeaders[3] := TNameValuePair.Create('Authorization', LHeaders.Values['Authorization']);
        LNetHeaders[4] := TNameValuePair.Create('Content-Type', 'application/octet-stream');

        LItem.FileName := LFileName;
        LItem.RemotePath := LRemotePath;
        LItem.FileSize := Length(LPayload);
        LItem.Success := False;
        LItem.MessageText := '';

        LStream := TFileStream.Create(LFilePath, fmOpenRead or fmShareDenyWrite);
        try
          LResp := LClient.Put(BuildObjectUrl(AContext, LRemotePath), LStream, nil, LNetHeaders);
          if Assigned(AOnTransfer) then
            AOnTransfer(LFileName, LStream.Size, LStream.Size);
          if (LResp.StatusCode div 100) = 2 then
          begin
            LItem.Success := True;
            LItem.MessageText := 'Upload concluido.';
          end
          else
            LItem.MessageText := BuildFriendlyAwsError(
              Format('Falha no upload AWS. HTTP %d.', [LResp.StatusCode]),
              LResp.ContentAsString(TEncoding.UTF8));
        finally
          LStream.Free;
        end;
      finally
        LHeaders.Free;
      end;

      Result.Add(LItem);
      if Assigned(AOnProgress) then
        AOnProgress(LItem, I + 1, Length(AContext.Arquivos));
    end;
  finally
    LClient.Free;
  end;
end;

procedure TAwsS3StorageProvider.DownloadFile(const AContext: TAnexoContext;
  const ARemotePath, ALocalFilePath: string);
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LCanonicalUri: string;
  LHeaders: TStringList;
  LNetHeaders: TNetHeaders;
  LOut: TFileStream;
begin
  LCanonicalUri := '/' + AContext.Credentials.AwsBucket + '/' + UriEncodeAws(ARemotePath, False);
  LHeaders := TStringList.Create;
  try
    SignRequest(AContext, 'GET', LCanonicalUri,
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', LHeaders);

    SetLength(LNetHeaders, 4);
    LNetHeaders[0] := TNameValuePair.Create('Host', LHeaders.Values['Host']);
    LNetHeaders[1] := TNameValuePair.Create('x-amz-content-sha256', LHeaders.Values['x-amz-content-sha256']);
    LNetHeaders[2] := TNameValuePair.Create('x-amz-date', LHeaders.Values['x-amz-date']);
    LNetHeaders[3] := TNameValuePair.Create('Authorization', LHeaders.Values['Authorization']);

    LClient := THTTPClient.Create;
    try
      LResp := LClient.Get(BuildObjectUrl(AContext, ARemotePath), nil, LNetHeaders);
      if (LResp.StatusCode div 100) <> 2 then
        raise Exception.Create(BuildFriendlyAwsError(
          Format('Falha ao baixar arquivo AWS. HTTP %d.', [LResp.StatusCode]),
          LResp.ContentAsString(TEncoding.UTF8)));

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
  finally
    LHeaders.Free;
  end;
end;

procedure TAwsS3StorageProvider.DeleteFile(const AContext: TAnexoContext;
  const ARemotePath: string);
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LCanonicalUri: string;
  LHeaders: TStringList;
  LNetHeaders: TNetHeaders;
begin
  LCanonicalUri := '/' + AContext.Credentials.AwsBucket + '/' + UriEncodeAws(ARemotePath, False);
  LHeaders := TStringList.Create;
  try
    SignRequest(AContext, 'DELETE', LCanonicalUri,
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', LHeaders);

    SetLength(LNetHeaders, 4);
    LNetHeaders[0] := TNameValuePair.Create('Host', LHeaders.Values['Host']);
    LNetHeaders[1] := TNameValuePair.Create('x-amz-content-sha256', LHeaders.Values['x-amz-content-sha256']);
    LNetHeaders[2] := TNameValuePair.Create('x-amz-date', LHeaders.Values['x-amz-date']);
    LNetHeaders[3] := TNameValuePair.Create('Authorization', LHeaders.Values['Authorization']);

    LClient := THTTPClient.Create;
    try
      LResp := LClient.Delete(BuildObjectUrl(AContext, ARemotePath), nil, LNetHeaders);
      if (LResp.StatusCode div 100) <> 2 then
        raise Exception.Create(BuildFriendlyAwsError(
          Format('Falha ao apagar arquivo AWS. HTTP %d.', [LResp.StatusCode]),
          LResp.ContentAsString(TEncoding.UTF8)));
    finally
      LClient.Free;
    end;
  finally
    LHeaders.Free;
  end;
end;

end.

