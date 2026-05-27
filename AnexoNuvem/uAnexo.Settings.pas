unit uAnexo.Settings;

interface

uses
  uAnexo.Integracao;

type
  TAnexoSettings = class
  public
    FIntegracao: TAnexoIntegracao;
    FTenantId: string;
    FUserId: string;
    FSupabaseUrl: string;
    FSupabaseAnonKey: string;
    FSupabaseEmail: string;
    FSupabasePassword: string;
    FSupabaseBucket: string;
    FSupabaseMaxFileSizeMB: Integer;
    FAwsEndpoint: string;
    FAwsRegion: string;
    FAwsBucket: string;
    FAwsAccessKey: string;
    FAwsSecretKey: string;
    FAwsMaxFileSizeMB: Integer;
    FGoogleClientId: string;
    FGoogleClientSecret: string;
    FGoogleFolderId: string;
    FGoogleRefreshToken: string;
    FGoogleMaxFileSizeMB: Integer;
    procedure Assign(const ASource: TAnexoSettings);
  end;

implementation

procedure TAnexoSettings.Assign(const ASource: TAnexoSettings);
begin
  if ASource = nil then
    Exit;

  FIntegracao := ASource.FIntegracao;
  FTenantId := ASource.FTenantId;
  FUserId := ASource.FUserId;
  FSupabaseUrl := ASource.FSupabaseUrl;
  FSupabaseAnonKey := ASource.FSupabaseAnonKey;
  FSupabaseEmail := ASource.FSupabaseEmail;
  FSupabasePassword := ASource.FSupabasePassword;
  FSupabaseBucket := ASource.FSupabaseBucket;
  FSupabaseMaxFileSizeMB := ASource.FSupabaseMaxFileSizeMB;
  FAwsEndpoint := ASource.FAwsEndpoint;
  FAwsRegion := ASource.FAwsRegion;
  FAwsBucket := ASource.FAwsBucket;
  FAwsAccessKey := ASource.FAwsAccessKey;
  FAwsSecretKey := ASource.FAwsSecretKey;
  FAwsMaxFileSizeMB := ASource.FAwsMaxFileSizeMB;
  FGoogleClientId := ASource.FGoogleClientId;
  FGoogleClientSecret := ASource.FGoogleClientSecret;
  FGoogleFolderId := ASource.FGoogleFolderId;
  FGoogleRefreshToken := ASource.FGoogleRefreshToken;
  FGoogleMaxFileSizeMB := ASource.FGoogleMaxFileSizeMB;
end;

end.

