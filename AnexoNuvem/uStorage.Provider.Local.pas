unit uStorage.Provider.Local;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  uStorage.ProviderIntf, uAnexo.Types;

type
  TLocalStorageProvider = class(TInterfacedObject, IStorageProvider)
  private
    function GetBaseFolder(const AContext: TAnexoContext): string;
  public
    function UploadFiles(const AContext: TAnexoContext; const AOnProgress: TAnexoProgressProc;
      const AOnTransfer: TAnexoTransferProc = nil): TUploadBatchResult;
    procedure DownloadFile(const AContext: TAnexoContext; const ARemotePath, ALocalFilePath: string);
    procedure DeleteFile(const AContext: TAnexoContext; const ARemotePath: string);
  end;

implementation

function TLocalStorageProvider.GetBaseFolder(const AContext: TAnexoContext): string;
var
  LRoot: string;
begin
  if Trim(AContext.Credentials.Bucket) <> '' then
    LRoot := AContext.Credentials.Bucket
  else
    LRoot := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'AnexoNuvemLocal';

  Result := TPath.Combine(LRoot, AContext.TenantId);
  Result := TPath.Combine(Result, AContext.UserId);
end;

function TLocalStorageProvider.UploadFiles(const AContext: TAnexoContext;
  const AOnProgress: TAnexoProgressProc; const AOnTransfer: TAnexoTransferProc): TUploadBatchResult;
var
  LTargetFolder: string;
  LSourceFile: string;
  LTargetFile: string;
  LResultItem: TUploadItemResult;
  I: Integer;
begin
  Result := TUploadBatchResult.Create;

  LTargetFolder := GetBaseFolder(AContext);
  ForceDirectories(LTargetFolder);

  for I := 0 to High(AContext.Arquivos) do
  begin
    LSourceFile := AContext.Arquivos[I];
    LTargetFile := TPath.Combine(LTargetFolder, TPath.GetFileName(LSourceFile));

    LResultItem.FileName := TPath.GetFileName(LSourceFile);
    LResultItem.RemotePath := LTargetFile;
    LResultItem.Success := False;
    LResultItem.MessageText := '';

    try
      TFile.Copy(LSourceFile, LTargetFile, True);
      LResultItem.Success := True;
      LResultItem.MessageText := 'Upload local concluido.';
    except
      on E: Exception do
      begin
        LResultItem.Success := False;
        LResultItem.MessageText := E.Message;
      end;
    end;

    Result.Add(LResultItem);
    if Assigned(AOnProgress) then
      AOnProgress(LResultItem, I + 1, Length(AContext.Arquivos));
  end;
end;

procedure TLocalStorageProvider.DownloadFile(const AContext: TAnexoContext; const ARemotePath, ALocalFilePath: string);
begin
  if not TFile.Exists(ARemotePath) then
    raise Exception.Create('Arquivo remoto nao encontrado: ' + ARemotePath);
  ForceDirectories(ExtractFilePath(ALocalFilePath));
  TFile.Copy(ARemotePath, ALocalFilePath, True);
end;

procedure TLocalStorageProvider.DeleteFile(const AContext: TAnexoContext; const ARemotePath: string);
begin
  if TFile.Exists(ARemotePath) then
    TFile.Delete(ARemotePath);
end;

end.

