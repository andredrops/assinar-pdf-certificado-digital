unit fUploadProgress;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  uAnexo.Types;

type
  TfrmUploadProgress = class(TForm)
    lblTitulo: TLabel;
    lblStatus: TLabel;
    pbTotal: TProgressBar;
    lstArquivos: TListBox;
  public
    procedure Init(const AArquivos: TArray<string>);
    procedure UpdateProgress(const AItem: TUploadItemResult; ACurrent, ATotal: Integer);
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils;

procedure TfrmUploadProgress.Init(const AArquivos: TArray<string>);
var
  LFile: string;
begin
  BorderStyle := bsNone;
  Position := poMainFormCenter;
  lstArquivos.Items.Clear;
  for LFile in AArquivos do
    lstArquivos.Items.Add(TPath.GetFileName(LFile) + ' - aguardando...');

  pbTotal.Min := 0;
  pbTotal.Max := Length(AArquivos);
  pbTotal.Position := 0;
  lblStatus.Caption := 'Iniciando upload...';
end;

procedure TfrmUploadProgress.UpdateProgress(const AItem: TUploadItemResult; ACurrent,
  ATotal: Integer);
var
  I: Integer;
  LStatus: string;
begin
  pbTotal.Max := ATotal;
  pbTotal.Position := ACurrent;

  if AItem.Success then
    LStatus := 'ok'
  else
    LStatus := 'erro: ' + AItem.MessageText;

  for I := 0 to lstArquivos.Count - 1 do
  begin
    if Pos(AItem.FileName, lstArquivos.Items[I]) = 1 then
    begin
      lstArquivos.Items[I] := AItem.FileName + ' - ' + LStatus;
      Break;
    end;
  end;

  lblStatus.Caption := Format('Processados %d de %d', [ACurrent, ATotal]);
  Update;
end;

end.


