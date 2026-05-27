unit uStorage.ProviderIntf;

interface

uses
  uAnexo.Types;

type
  TAnexoProgressProc = reference to procedure(const AItem: TUploadItemResult; ACurrent, ATotal: Integer);
  TAnexoTransferProc = reference to procedure(const AFileName: string; ABytesSent, ABytesTotal: Int64);

  IStorageProvider = interface
    ['{D109C84D-2C7C-4E0C-BC87-B4C57C32D4DD}']
    function UploadFiles(const AContext: TAnexoContext; const AOnProgress: TAnexoProgressProc;
      const AOnTransfer: TAnexoTransferProc): TUploadBatchResult;
    procedure DownloadFile(const AContext: TAnexoContext; const ARemotePath, ALocalFilePath: string);
    procedure DeleteFile(const AContext: TAnexoContext; const ARemotePath: string);
  end;

implementation

end.

