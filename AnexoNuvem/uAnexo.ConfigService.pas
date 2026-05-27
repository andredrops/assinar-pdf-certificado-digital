unit uAnexo.ConfigService;

interface

uses
  uAnexo.Settings;

type
  TAnexoConfigService = class
  private
    class function GetConfigFileName: string; static;
  public
    class function LoadSettings: TAnexoSettings; static;
    class procedure SaveSettings(const ASettings: TAnexoSettings); static;
  end;

implementation

uses
  System.SysUtils, System.IniFiles, System.IOUtils, uAnexo.Integracao;

function LegacyProviderToIntegracao(const ALegacyProvider: Integer): TAnexoIntegracao;
begin
  case ALegacyProvider of
    0: Result := aiSupabase;    // ptSupabase (legado)
    1: Result := aiAwsS3;       // ptAwsS3 (legado)
    2: Result := aiGoogleDrive; // ptGoogleCloud (legado)
  else
    Result := aiAwsS3;
  end;
end;

class function TAnexoConfigService.GetConfigFileName: string;
var
  LLegacyIni: string;
begin
  LLegacyIni := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'AnexoNuvel.ini';
  if TFile.Exists(LLegacyIni) then
    Exit(LLegacyIni);
  Result := ChangeFileExt(ParamStr(0), '.ini');
end;

class function TAnexoConfigService.LoadSettings: TAnexoSettings;
var
  LIni: TIniFile;
  LProviderIndex: Integer;
  LProviderVersion: Integer;
begin
  Result := TAnexoSettings.Create;
  LIni := TIniFile.Create(GetConfigFileName);
  try
    LProviderVersion := LIni.ReadInteger('anexo', 'provider_type_version', 1);
    LProviderIndex := LIni.ReadInteger('anexo', 'provider_type', Ord(aiAwsS3));

    if LProviderVersion >= 2 then
    begin
      if (LProviderIndex >= Ord(Low(TAnexoIntegracao))) and
         (LProviderIndex <= Ord(High(TAnexoIntegracao))) then
        Result.FIntegracao := TAnexoIntegracao(LProviderIndex)
      else
        Result.FIntegracao := aiAwsS3;
    end
    else
      Result.FIntegracao := LegacyProviderToIntegracao(LProviderIndex);
    Result.FTenantId := LIni.ReadString('anexo', 'tenant_id', 'tenant_demo');
    Result.FUserId := LIni.ReadString('anexo', 'user_id', '00000000-0000-0000-0000-000000000001');

    Result.FSupabaseUrl := LIni.ReadString('supabase', 'url', '');
    Result.FSupabaseAnonKey := LIni.ReadString('supabase', 'anon_key', '');
    Result.FSupabaseEmail := LIni.ReadString('supabase', 'email', '');
    Result.FSupabasePassword := LIni.ReadString('supabase', 'password', '');
    Result.FSupabaseBucket := LIni.ReadString('supabase', 'bucket', 'anexos');
    Result.FSupabaseMaxFileSizeMB := LIni.ReadInteger('supabase', 'max_file_size_mb', 50);

    Result.FAwsEndpoint := LIni.ReadString('aws', 'endpoint', '');
    Result.FAwsRegion := LIni.ReadString('aws', 'region', 'sa-east-1');
    Result.FAwsBucket := LIni.ReadString('aws', 'bucket', '');
    Result.FAwsAccessKey := LIni.ReadString('aws', 'access_key', '');
    Result.FAwsSecretKey := LIni.ReadString('aws', 'secret_key', '');
    Result.FAwsMaxFileSizeMB := LIni.ReadInteger('aws', 'max_file_size_mb', 50);

    Result.FGoogleClientId := LIni.ReadString('google', 'client_id', '');
    Result.FGoogleClientSecret := LIni.ReadString('google', 'client_secret', '');
    Result.FGoogleFolderId := LIni.ReadString('google', 'folder_id', '');
    Result.FGoogleRefreshToken := LIni.ReadString('google', 'refresh_token', '');
    Result.FGoogleMaxFileSizeMB := LIni.ReadInteger('google', 'max_file_size_mb', 50);
  finally
    LIni.Free;
  end;
end;

class procedure TAnexoConfigService.SaveSettings(const ASettings: TAnexoSettings);
var
  LIni: TIniFile;
begin
  if ASettings = nil then
    Exit;

  LIni := TIniFile.Create(GetConfigFileName);
  try
    LIni.WriteInteger('anexo', 'provider_type_version', 2);
    LIni.WriteInteger('anexo', 'provider_type', Ord(ASettings.FIntegracao));
    LIni.WriteString('anexo', 'tenant_id', Trim(ASettings.FTenantId));
    LIni.WriteString('anexo', 'user_id', Trim(ASettings.FUserId));

    LIni.WriteString('supabase', 'url', Trim(ASettings.FSupabaseUrl));
    LIni.WriteString('supabase', 'anon_key', Trim(ASettings.FSupabaseAnonKey));
    LIni.WriteString('supabase', 'email', Trim(ASettings.FSupabaseEmail));
    LIni.WriteString('supabase', 'password', Trim(ASettings.FSupabasePassword));
    LIni.WriteString('supabase', 'bucket', Trim(ASettings.FSupabaseBucket));
    LIni.WriteInteger('supabase', 'max_file_size_mb', ASettings.FSupabaseMaxFileSizeMB);

    LIni.WriteString('aws', 'endpoint', Trim(ASettings.FAwsEndpoint));
    LIni.WriteString('aws', 'region', Trim(ASettings.FAwsRegion));
    LIni.WriteString('aws', 'bucket', Trim(ASettings.FAwsBucket));
    LIni.WriteString('aws', 'access_key', Trim(ASettings.FAwsAccessKey));
    LIni.WriteString('aws', 'secret_key', Trim(ASettings.FAwsSecretKey));
    LIni.WriteInteger('aws', 'max_file_size_mb', ASettings.FAwsMaxFileSizeMB);

    LIni.WriteString('google', 'client_id', Trim(ASettings.FGoogleClientId));
    LIni.WriteString('google', 'client_secret', Trim(ASettings.FGoogleClientSecret));
    LIni.WriteString('google', 'folder_id', Trim(ASettings.FGoogleFolderId));
    LIni.WriteString('google', 'refresh_token', Trim(ASettings.FGoogleRefreshToken));
    LIni.WriteInteger('google', 'max_file_size_mb', ASettings.FGoogleMaxFileSizeMB);
  finally
    LIni.Free;
  end;
end;

end.

