unit fAnexoNuvem;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Data.DB,
  System.UITypes,
  Vcl.Grids, Vcl.DBGrids, FireDAC.Comp.Client, uAnexo.Types;

type
  TForm1 = class(TForm)
    btnAnexar: TButton;
    btnConfiguracoes: TButton;
    btnVisualizar: TButton;
    btnApagar: TButton;
    DBGrid1: TDBGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAnexarClick(Sender: TObject);
    procedure btnConfiguracoesClick(Sender: TObject);
    procedure btnVisualizarClick(Sender: TObject);
    procedure btnApagarClick(Sender: TObject);
  private
    FDataSource: TDataSource;
    FTable: TFDMemTable;
    FNextId: Integer;
    procedure InitGrid;
    procedure AddUploadRows(const AResult: TUploadBatchResult);
    function HasSelection: Boolean;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  uAnexo, System.IOUtils;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FNextId := 1;
  InitGrid;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FTable.Free;
  FDataSource.Free;
end;

procedure TForm1.InitGrid;
begin
  FDataSource := TDataSource.Create(Self);
  FTable := TFDMemTable.Create(Self);
  FTable.FieldDefs.Add('ID', ftInteger);
  FTable.FieldDefs.Add('Descricao', ftString, 180);
  FTable.FieldDefs.Add('Extensao', ftString, 20);
  FTable.FieldDefs.Add('Tamanho', ftLargeint);
  FTable.FieldDefs.Add('Chave', ftString, 512);
  FTable.FieldDefs.Add('NomeArquivo', ftString, 255);
  FTable.CreateDataSet;
  FTable.Open;

  FDataSource.DataSet := FTable;
  DBGrid1.DataSource := FDataSource;
end;

function TForm1.HasSelection: Boolean;
begin
  Result := (FTable <> nil) and FTable.Active and (not FTable.IsEmpty);
end;

procedure TForm1.AddUploadRows(const AResult: TUploadBatchResult);
var
  LItem: TUploadItemResult;
  LDescricao: string;
  LExt: string;
begin
  if AResult = nil then
    Exit;

  for LItem in AResult.Items do
  begin
    if not LItem.Success then
      Continue;
    LDescricao := TPath.GetFileNameWithoutExtension(LItem.FileName);
    LExt := TPath.GetExtension(LItem.FileName);
    if (LExt <> '') and (LExt[1] = '.') then
      Delete(LExt, 1, 1);

    FTable.Append;
    FTable.FieldByName('ID').AsInteger := FNextId;
    FTable.FieldByName('Descricao').AsString := LDescricao;
    FTable.FieldByName('Extensao').AsString := LExt;
    FTable.FieldByName('Tamanho').AsLargeInt := LItem.FileSize;
    FTable.FieldByName('Chave').AsString := LItem.RemotePath;
    FTable.FieldByName('NomeArquivo').AsString := LItem.FileName;
    FTable.Post;
    Inc(FNextId);
  end;
end;

procedure TForm1.btnAnexarClick(Sender: TObject);
var
  LResult: TUploadBatchResult;
begin
  LResult := TAnexo.Execute;
  try
    AddUploadRows(LResult);
  finally
    LResult.Free;
  end;
end;

procedure TForm1.btnApagarClick(Sender: TObject);
var
  LChave: string;
begin
  if not HasSelection then
    Exit;

  if MessageDlg('Tem certeza que deseja apagar este anexo?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  LChave := FTable.FieldByName('Chave').AsString;
  TAnexo.Apagar(LChave);
  FTable.Delete;
end;

procedure TForm1.btnConfiguracoesClick(Sender: TObject);
begin
  TAnexo.Configurar;
end;

procedure TForm1.btnVisualizarClick(Sender: TObject);
begin
  if not HasSelection then
    Exit;
  TAnexo.Visualizar(
    FTable.FieldByName('Chave').AsString,
    FTable.FieldByName('NomeArquivo').AsString
  );
end;

end.

