unit fAnexoProgress;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls,
  System.Generics.Collections;

type
  TAnexoItemStatus = (isPending, isUploading, isSuccess, isError, isCanceled);

  TAnexoQueueItem = class
  public
    FFilePath: string;
    FFileName: string;
    FStatus: TAnexoItemStatus;
    FMessage: string;
    FActionText: string;
    FAllowRetry: Boolean;
    function AllowRemove: Boolean;
  end;

  TfAnexoProgress = class(TForm)
    lvArquivos: TListView;
    pbTotal: TProgressBar;
    lblResumo: TLabel;
    btnCancelarPendentes: TButton;
    btnFechar: TButton;
    btnTentarNovamente: TButton;
    memErros: TMemo;
    btnDetalhes: TButton;
    procedure btnCancelarPendentesClick(Sender: TObject);
    procedure btnDetalhesClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnTentarNovamenteClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvArquivosMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FItems: TObjectList<TAnexoQueueItem>;
    FRetryRequested: Boolean;
    FExpandedDetails: Boolean;
    FBaseHeight: Integer;
    FIsProcessing: Boolean;
    FCloseWhenIdle: Boolean;
    function GetListItem(const AQueueItem: TAnexoQueueItem): TListItem;
    function GetColumnAtX(AX: Integer): Integer;
    function StatusText(AStatus: TAnexoItemStatus): string;
    function BuildActionTextForError(const AMessage: string): string;
    function FindItemByFilePath(const AFilePath: string): TAnexoQueueItem;
    procedure UpdateDetailsVisibility;
    procedure RefreshRow(const AQueueItem: TAnexoQueueItem);
  public
    procedure Setup(const AFiles: TArray<string>);
    function NextPendingItem: TAnexoQueueItem;
    procedure MarkUploading(const AItem: TAnexoQueueItem);
    procedure MarkResult(const AItem: TAnexoQueueItem; ASuccess: Boolean; const AMessage: string);
    procedure MarkAllPendingAsCanceled;
    procedure PrepareRetryFailedItems;
    procedure UpdateSummary;
    function TotalActiveItems: Integer;
    function ConsumeRetryRequested: Boolean;
    procedure SetOverallProgress(APercent: Integer; const AInfo: string);
    procedure AppendErrorDetails(const AFileName, ARawErrorJson: string);
    procedure MarkValidationErrorByPath(const AFilePath, AMessage, AActionText: string);
    function HasRetryableItems: Boolean;
    function CountPendingItems: Integer;
    procedure BeginProcessing;
    procedure EndProcessing;
  end;

implementation

{$R *.dfm}

uses
  System.IOUtils;

function TAnexoQueueItem.AllowRemove: Boolean;
begin
  Result := FStatus = isPending;
end;

procedure TfAnexoProgress.btnCancelarPendentesClick(Sender: TObject);
begin
  MarkAllPendingAsCanceled;
end;

procedure TfAnexoProgress.btnDetalhesClick(Sender: TObject);
begin
  FExpandedDetails := not FExpandedDetails;
  UpdateDetailsVisibility;
end;

procedure TfAnexoProgress.btnFecharClick(Sender: TObject);
begin
  Close;
end;

procedure TfAnexoProgress.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
var
  LResp: Integer;
begin
  if not FIsProcessing then
    Exit;

  LResp := MessageDlg(
    'O upload ainda esta em andamento.' + sLineBreak +
    'Sim: Aguarda finalizar' + sLineBreak +
    'Nao: Cancela pendentes e fecha ao concluir o arquivo atual',
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);

  case LResp of
    mrYes:
      begin
        CanClose := False;
      end;
    mrNo:
      begin
        MarkAllPendingAsCanceled;
        FCloseWhenIdle := True;
        CanClose := False;
      end;
  else
    CanClose := False;
  end;
end;

procedure TfAnexoProgress.btnTentarNovamenteClick(Sender: TObject);
begin
  PrepareRetryFailedItems;
  FRetryRequested := True;
end;

procedure TfAnexoProgress.FormDestroy(Sender: TObject);
begin
  FItems.Free;
end;

function TfAnexoProgress.GetColumnAtX(AX: Integer): Integer;
var
  LSum: Integer;
  I: Integer;
begin
  Result := -1;
  LSum := 0;
  for I := 0 to lvArquivos.Columns.Count - 1 do
  begin
    Inc(LSum, lvArquivos.Columns[I].Width);
    if AX <= LSum then
      Exit(I);
  end;
end;

function TfAnexoProgress.GetListItem(const AQueueItem: TAnexoQueueItem): TListItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to lvArquivos.Items.Count - 1 do
    if lvArquivos.Items[I].Data = AQueueItem then
      Exit(lvArquivos.Items[I]);
end;

procedure TfAnexoProgress.lvArquivosMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  LHitItem: TListItem;
  LColumn: Integer;
  LQueueItem: TAnexoQueueItem;
begin
  LHitItem := lvArquivos.GetItemAt(X, Y);
  if LHitItem = nil then
    Exit;

  LColumn := GetColumnAtX(X);
  if LColumn <> 2 then
    Exit;

  LQueueItem := TAnexoQueueItem(LHitItem.Data);
  if (LQueueItem <> nil) and LQueueItem.AllowRemove then
  begin
    LQueueItem.FStatus := isCanceled;
    LQueueItem.FMessage := 'Removido da fila';
    RefreshRow(LQueueItem);
    UpdateSummary;
  end;
end;

procedure TfAnexoProgress.MarkAllPendingAsCanceled;
var
  LItem: TAnexoQueueItem;
begin
  for LItem in FItems do
    if LItem.FStatus = isPending then
    begin
      LItem.FStatus := isCanceled;
      LItem.FMessage := 'Cancelado pelo usuario';
      LItem.FActionText := '';
      RefreshRow(LItem);
    end;
  UpdateSummary;
end;

procedure TfAnexoProgress.PrepareRetryFailedItems;
var
  LItem: TAnexoQueueItem;
begin
  for LItem in FItems do
    if ((LItem.FStatus = isError) and LItem.FAllowRetry) or
       (LItem.FStatus = isCanceled) then
    begin
      LItem.FStatus := isPending;
      LItem.FMessage := '';
      LItem.FActionText := '';
      LItem.FAllowRetry := True;
      RefreshRow(LItem);
    end;
  UpdateSummary;
end;

procedure TfAnexoProgress.MarkResult(const AItem: TAnexoQueueItem; ASuccess: Boolean;
  const AMessage: string);
begin
  if ASuccess then
  begin
    AItem.FStatus := isSuccess;
    AItem.FActionText := 'OK';
  end
  else
  begin
    AItem.FStatus := isError;
    AItem.FActionText := BuildActionTextForError(AMessage);
  end;
  AItem.FMessage := AMessage;
  RefreshRow(AItem);
  UpdateSummary;
end;

procedure TfAnexoProgress.MarkUploading(const AItem: TAnexoQueueItem);
begin
  AItem.FStatus := isUploading;
  AItem.FMessage := 'Enviando...';
  AItem.FActionText := '';
  RefreshRow(AItem);
  UpdateSummary;
end;

function TfAnexoProgress.NextPendingItem: TAnexoQueueItem;
var
  LItem: TAnexoQueueItem;
begin
  Result := nil;
  for LItem in FItems do
    if LItem.FStatus = isPending then
      Exit(LItem);
end;

procedure TfAnexoProgress.RefreshRow(const AQueueItem: TAnexoQueueItem);
var
  LRow: TListItem;
begin
  LRow := GetListItem(AQueueItem);
  if LRow = nil then
    Exit;

  LRow.SubItems[0] := StatusText(AQueueItem.FStatus);
  if AQueueItem.AllowRemove then
    LRow.SubItems[1] := 'X'
  else
    LRow.SubItems[1] := AQueueItem.FActionText;
end;

procedure TfAnexoProgress.Setup(const AFiles: TArray<string>);
var
  LFile: string;
  LQueueItem: TAnexoQueueItem;
  LRow: TListItem;
begin
  FRetryRequested := False;
  FExpandedDetails := False;
  FIsProcessing := False;
  FCloseWhenIdle := False;
  if FBaseHeight = 0 then
    FBaseHeight := ClientHeight;
  FItems := TObjectList<TAnexoQueueItem>.Create(True);
  lvArquivos.Items.Clear;

  for LFile in AFiles do
  begin
    LQueueItem := TAnexoQueueItem.Create;
    LQueueItem.FFilePath := LFile;
    LQueueItem.FFileName := TPath.GetFileName(LFile);
    LQueueItem.FStatus := isPending;
    LQueueItem.FMessage := '';
    LQueueItem.FActionText := '';
    LQueueItem.FAllowRetry := True;
    FItems.Add(LQueueItem);

    LRow := lvArquivos.Items.Add;
    LRow.Caption := LQueueItem.FFileName;
    LRow.SubItems.Add(StatusText(LQueueItem.FStatus));
    LRow.SubItems.Add('X');
    LRow.Data := LQueueItem;
  end;

  pbTotal.Min := 0;
  pbTotal.Max := 100;
  pbTotal.Position := 0;
  memErros.Lines.Clear;
  btnDetalhes.Visible := False;
  UpdateDetailsVisibility;
  UpdateSummary;
end;

function TfAnexoProgress.FindItemByFilePath(const AFilePath: string): TAnexoQueueItem;
var
  LItem: TAnexoQueueItem;
begin
  Result := nil;
  for LItem in FItems do
    if SameText(LItem.FFilePath, AFilePath) then
      Exit(LItem);
end;

procedure TfAnexoProgress.MarkValidationErrorByPath(const AFilePath, AMessage, AActionText: string);
var
  LItem: TAnexoQueueItem;
begin
  LItem := FindItemByFilePath(AFilePath);
  if LItem = nil then
    Exit;

  LItem.FStatus := isError;
  LItem.FMessage := AMessage;
  LItem.FActionText := AActionText;
  LItem.FAllowRetry := False;
  RefreshRow(LItem);
  UpdateSummary;
end;

function TfAnexoProgress.HasRetryableItems: Boolean;
var
  LItem: TAnexoQueueItem;
begin
  Result := False;
  for LItem in FItems do
  begin
    if ((LItem.FStatus = isError) and LItem.FAllowRetry) or
       (LItem.FStatus = isCanceled) then
      Exit(True);
  end;
end;

function TfAnexoProgress.CountPendingItems: Integer;
var
  LItem: TAnexoQueueItem;
begin
  Result := 0;
  for LItem in FItems do
    if LItem.FStatus = isPending then
      Inc(Result);
end;

function TfAnexoProgress.BuildActionTextForError(const AMessage: string): string;
var
  LLower: string;
begin
  LLower := LowerCase(AMessage);
  if (Pos('"statuscode":"409"', LLower) > 0) or
     (Pos('duplicate', LLower) > 0) or
     (Pos('already exists', LLower) > 0) then
    Result := 'Esse arquivo ja foi anexado, se quiser atualizar apague e anexe novamente!'
  else if (Pos('"statuscode":"413"', LLower) > 0) or
          (Pos('payload too large', LLower) > 0) or
          (Pos('maximum allowed size', LLower) > 0) then
    Result := 'Tamanho maximo excedido. Verifique o limite de upload global e do bucket no Supabase.'
  else
    Result := 'Verifique os detalhes no erro.';
end;

function TfAnexoProgress.ConsumeRetryRequested: Boolean;
begin
  Result := FRetryRequested;
  FRetryRequested := False;
end;

function TfAnexoProgress.StatusText(AStatus: TAnexoItemStatus): string;
begin
  case AStatus of
    isPending: Result := 'Pendente';
    isUploading: Result := 'Enviando';
    isSuccess: Result := 'Concluido';
    isError: Result := 'Erro';
    isCanceled: Result := 'Cancelado';
  else
    Result := '-';
  end;
end;

function TfAnexoProgress.TotalActiveItems: Integer;
var
  LItem: TAnexoQueueItem;
begin
  Result := 0;
  for LItem in FItems do
    if LItem.FStatus <> isCanceled then
      Inc(Result);
end;

procedure TfAnexoProgress.UpdateSummary;
var
  LSuccess: Integer;
  LError: Integer;
  LPending: Integer;
  LCanceled: Integer;
  LItem: TAnexoQueueItem;
begin
  LSuccess := 0;
  LError := 0;
  LPending := 0;
  LCanceled := 0;

  for LItem in FItems do
    case LItem.FStatus of
      isPending, isUploading: Inc(LPending);
      isSuccess: Inc(LSuccess);
      isError: Inc(LError);
      isCanceled: Inc(LCanceled);
    end;

  if pbTotal.Max <> 100 then
    pbTotal.Max := 100;
  lblResumo.Caption := Format('Sucesso: %d | Erro: %d | Pendentes: %d | Cancelados: %d',
    [LSuccess, LError, LPending, LCanceled]);
end;

procedure TfAnexoProgress.SetOverallProgress(APercent: Integer; const AInfo: string);
begin
  if pbTotal.Max <> 100 then
    pbTotal.Max := 100;
  if APercent < 0 then
    APercent := 0;
  if APercent > 100 then
    APercent := 100;
  pbTotal.Position := APercent;
  if Trim(AInfo) <> '' then
    lblResumo.Caption := AInfo;
end;

procedure TfAnexoProgress.AppendErrorDetails(const AFileName, ARawErrorJson: string);
begin
  btnDetalhes.Visible := True;
  memErros.Lines.Add('Arquivo: ' + AFileName);
  memErros.Lines.Add('JSON:');
  memErros.Lines.Add(Trim(ARawErrorJson));
  memErros.Lines.Add('----------------------------------------');
  UpdateDetailsVisibility;
end;

procedure TfAnexoProgress.UpdateDetailsVisibility;
begin
  memErros.Visible := FExpandedDetails and btnDetalhes.Visible;
  if btnDetalhes.Visible then
  begin
    if FExpandedDetails then
      btnDetalhes.Caption := '- Menos detalhes'
    else
      btnDetalhes.Caption := '+ Mais detalhes';
  end;

  if memErros.Visible then
    ClientHeight := 560
  else
    ClientHeight := FBaseHeight;
end;

procedure TfAnexoProgress.BeginProcessing;
begin
  FIsProcessing := True;
  FCloseWhenIdle := False;
end;

procedure TfAnexoProgress.EndProcessing;
begin
  FIsProcessing := False;
  if FCloseWhenIdle then
    Close;
end;

end.

