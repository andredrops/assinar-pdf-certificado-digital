unit uAnexo.Types;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, uAnexo.Integracao;

type
  TUploadItemResult = record
    FileName: string;
    RemotePath: string;
    FileSize: Int64;
    Success: Boolean;
    MessageText: string;
  end;

  TUploadBatchResult = class
  private
    FItems: TList<TUploadItemResult>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AItem: TUploadItemResult);
    property Items: TList<TUploadItemResult> read FItems;
  end;

  TAnexoCredentials = class
  public
    SupabaseUrl: string;
    SupabaseAnonKey: string;
    SupabaseAccessToken: string;
    Bucket: string;
    AwsEndpoint: string;
    AwsRegion: string;
    AwsBucket: string;
    AwsAccessKey: string;
    AwsSecretKey: string;
    GoogleClientId: string;
    GoogleClientSecret: string;
    GoogleFolderId: string;
    GoogleRefreshToken: string;
  end;

  TAnexoContext = class
  public
    Integracao: TAnexoIntegracao;
    TenantId: string;
    UserId: string;
    Credentials: TAnexoCredentials;
    Arquivos: TArray<string>;
    constructor Create;
    destructor Destroy; override;
    procedure Assign(const ASource: TAnexoContext);
    procedure Validate;
  end;

implementation

{ TUploadBatchResult }

constructor TUploadBatchResult.Create;
begin
  inherited Create;
  FItems := TList<TUploadItemResult>.Create;
end;

destructor TUploadBatchResult.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TUploadBatchResult.Add(const AItem: TUploadItemResult);
begin
  FItems.Add(AItem);
end;

{ TAnexoContext }

constructor TAnexoContext.Create;
begin
  inherited Create;
  Credentials := TAnexoCredentials.Create;
end;

destructor TAnexoContext.Destroy;
begin
  Credentials.Free;
  inherited;
end;

procedure TAnexoContext.Validate;
begin
  if Length(Arquivos) = 0 then
    raise Exception.Create('Nenhum arquivo foi selecionado.');

  if Trim(TenantId) = '' then
    raise Exception.Create('TenantId obrigatorio.');

  if Trim(UserId) = '' then
    raise Exception.Create('UserId obrigatorio.');

  case Integracao of
    aiSupabase:
      begin
        if Trim(Credentials.SupabaseUrl) = '' then
          raise Exception.Create('SupabaseUrl obrigatorio.');
        if Trim(Credentials.SupabaseAnonKey) = '' then
          raise Exception.Create('SupabaseAnonKey obrigatorio.');
        if Trim(Credentials.SupabaseAccessToken) = '' then
          raise Exception.Create('SupabaseAccessToken obrigatorio.');
        if Trim(Credentials.Bucket) = '' then
          raise Exception.Create('Bucket obrigatorio.');
      end;
    aiAwsS3:
      begin
        if Trim(Credentials.AwsEndpoint) = '' then
          raise Exception.Create('AwsEndpoint obrigatorio.');
        if Trim(Credentials.AwsBucket) = '' then
          raise Exception.Create('AwsBucket obrigatorio.');
      end;
    aiGoogleDrive, aiGoogleWorkspace:
      begin
        if Trim(Credentials.GoogleClientId) = '' then
          raise Exception.Create('GoogleClientId obrigatorio.');
        if Trim(Credentials.GoogleClientSecret) = '' then
          raise Exception.Create('GoogleClientSecret obrigatorio.');
        if Trim(Credentials.GoogleFolderId) = '' then
          raise Exception.Create('GoogleFolderId obrigatorio.');
        if Trim(Credentials.GoogleRefreshToken) = '' then
          raise Exception.Create('GoogleRefreshToken obrigatorio.');
      end;
  end;
end;

procedure TAnexoContext.Assign(const ASource: TAnexoContext);
begin
  if ASource = nil then
    Exit;

  Integracao := ASource.Integracao;
  TenantId := ASource.TenantId;
  UserId := ASource.UserId;
  Credentials.SupabaseUrl := ASource.Credentials.SupabaseUrl;
  Credentials.SupabaseAnonKey := ASource.Credentials.SupabaseAnonKey;
  Credentials.SupabaseAccessToken := ASource.Credentials.SupabaseAccessToken;
  Credentials.Bucket := ASource.Credentials.Bucket;
  Credentials.AwsEndpoint := ASource.Credentials.AwsEndpoint;
  Credentials.AwsRegion := ASource.Credentials.AwsRegion;
  Credentials.AwsBucket := ASource.Credentials.AwsBucket;
  Credentials.AwsAccessKey := ASource.Credentials.AwsAccessKey;
  Credentials.AwsSecretKey := ASource.Credentials.AwsSecretKey;
  Credentials.GoogleClientId := ASource.Credentials.GoogleClientId;
  Credentials.GoogleClientSecret := ASource.Credentials.GoogleClientSecret;
  Credentials.GoogleFolderId := ASource.Credentials.GoogleFolderId;
  Credentials.GoogleRefreshToken := ASource.Credentials.GoogleRefreshToken;
  Arquivos := Copy(ASource.Arquivos);
end;

end.

