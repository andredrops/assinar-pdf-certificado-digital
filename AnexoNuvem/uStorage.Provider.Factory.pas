unit uStorage.Provider.Factory;

interface

uses
  System.SysUtils,
  uAnexo.Types, uStorage.ProviderIntf, uAnexo.Integracao;

type
  TStorageProviderFactory = class
  public
    class function CreateProvider(AIntegracao: TAnexoIntegracao): IStorageProvider; static;
  end;

implementation

uses
  uStorage.Provider.Supabase, uStorage.Provider.AwsS3, uStorage.Provider.Google;

class function TStorageProviderFactory.CreateProvider(
  AIntegracao: TAnexoIntegracao): IStorageProvider;
begin
  case AIntegracao of
    aiSupabase:
      Result := TSupabaseStorageProvider.Create;
    aiAwsS3:
      Result := TAwsS3StorageProvider.Create;
    aiGoogleDrive, aiGoogleWorkspace:
      Result := TGoogleStorageProvider.Create;
  else
    raise Exception.Create('Integracao nao suportada.');
  end;
end;

end.

