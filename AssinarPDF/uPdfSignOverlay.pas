unit uPdfSignOverlay;

interface

uses
  System.Classes, System.SysUtils, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Controls, Vcl.Graphics;

type
  TPdfSignStatusProc = reference to procedure(const AText: string);
  TPdfSignAction = reference to function(const ASetStatus: TPdfSignStatusProc): Boolean;

  TPdfSignOverlay = class
  private
    FPreviewForm: TCustomForm;
    FOverlayForm: TForm;
    FBtnAssinar: TButton;
    FLoadingPanel: TPanel;
    FLoadingLabel: TLabel;
    FTimer: TTimer;
    FOnSign: TPdfSignAction;
    procedure SetLoadingStatus(const AText: string);
    procedure ShowLoading(const AText: string);
    procedure HideLoading;
    procedure PosicionarNoCantoDireitoInferior;
    procedure OnTimer(Sender: TObject);
    procedure OnBtnAssinarClick(Sender: TObject);
  public
    constructor Create(const APreviewForm: TCustomForm; const AOnSign: TPdfSignAction);
    destructor Destroy; override;
    procedure Show;
  end;

implementation

uses
  Winapi.Windows, Vcl.Dialogs;

{ TPdfSignOverlay }

constructor TPdfSignOverlay.Create(const APreviewForm: TCustomForm; const AOnSign: TPdfSignAction);
begin
  inherited Create;
  FPreviewForm := APreviewForm;
  FOnSign := AOnSign;

  FOverlayForm := TForm.Create(nil);
  FOverlayForm.BorderStyle := bsNone;
  FOverlayForm.FormStyle := fsStayOnTop;
  FOverlayForm.Position := poDesigned;
  FOverlayForm.Width := 240;
  FOverlayForm.Height := 80;
  FOverlayForm.Color := clBtnFace;
  FOverlayForm.Caption := '';

  FBtnAssinar := TButton.Create(FOverlayForm);
  FBtnAssinar.Parent := FOverlayForm;
  FBtnAssinar.Align := alClient;
  FBtnAssinar.Caption := 'Assinar PDF';
  FBtnAssinar.OnClick := OnBtnAssinarClick;

  FLoadingPanel := TPanel.Create(FOverlayForm);
  FLoadingPanel.Parent := FOverlayForm;
  FLoadingPanel.Visible := False;
  FLoadingPanel.BevelOuter := bvRaised;
  FLoadingPanel.Width := 240;
  FLoadingPanel.Height := 80;
  FLoadingPanel.Left := (FOverlayForm.ClientWidth - FLoadingPanel.Width) div 2;
  FLoadingPanel.Top := (FOverlayForm.ClientHeight - FLoadingPanel.Height) div 2;
  FLoadingPanel.Caption := '';

  FLoadingLabel := TLabel.Create(FLoadingPanel);
  FLoadingLabel.Parent := FLoadingPanel;
  FLoadingLabel.Align := alClient;
  FLoadingLabel.Alignment := taCenter;
  FLoadingLabel.Layout := tlCenter;
  FLoadingLabel.WordWrap := True;
  FLoadingLabel.Caption := 'Verificando certificado digital...';

  FTimer := TTimer.Create(FOverlayForm);
  FTimer.Interval := 250;
  FTimer.OnTimer := OnTimer;
end;

destructor TPdfSignOverlay.Destroy;
begin
  if Assigned(FOverlayForm) then
    FOverlayForm.Free;
  inherited;
end;

procedure TPdfSignOverlay.Show;
begin
  PosicionarNoCantoDireitoInferior;
  FOverlayForm.Show;
  FTimer.Enabled := True;
end;

procedure TPdfSignOverlay.OnBtnAssinarClick(Sender: TObject);
var
  LAssinou: Boolean;
begin
  LAssinou := False;
  FBtnAssinar.Enabled := False;
  ShowLoading('Assinar PDF');
  try
    if Assigned(FOnSign) then
      LAssinou := FOnSign(
        procedure(const AText: string)
        begin
          SetLoadingStatus(AText);
        end
      );
  finally
    HideLoading;
    FBtnAssinar.Enabled := True;
  end;

  if LAssinou then
  begin
    if Assigned(FPreviewForm) and not (csDestroying in FPreviewForm.ComponentState) then
      FPreviewForm.Close;
    FOverlayForm.Close;
  end;
end;

procedure TPdfSignOverlay.SetLoadingStatus(const AText: string);
begin
  FLoadingLabel.Caption := AText;
  FLoadingPanel.Update;
  FOverlayForm.Update;
  Application.ProcessMessages;
end;

procedure TPdfSignOverlay.ShowLoading(const AText: string);
begin
  FLoadingPanel.Left := (FOverlayForm.ClientWidth - FLoadingPanel.Width) div 2;
  FLoadingPanel.Top := (FOverlayForm.ClientHeight - FLoadingPanel.Height) div 2;
  FLoadingPanel.BringToFront;
  FLoadingPanel.Visible := True;
  SetLoadingStatus(AText);
end;

procedure TPdfSignOverlay.HideLoading;
begin
  FLoadingPanel.Visible := False;
  FOverlayForm.Update;
end;

procedure TPdfSignOverlay.OnTimer(Sender: TObject);
begin
  if (FPreviewForm = nil) or (csDestroying in FPreviewForm.ComponentState) or (not IsWindow(FPreviewForm.Handle)) then
  begin
    FOverlayForm.Close;
    Exit;
  end;

  if not FPreviewForm.Visible then
  begin
    FOverlayForm.Visible := False;
    Exit;
  end;

  if not FOverlayForm.Visible then
    FOverlayForm.Visible := True;

  PosicionarNoCantoDireitoInferior;
end;

procedure TPdfSignOverlay.PosicionarNoCantoDireitoInferior;
const
  C_Margem = 12;
begin
  if (FPreviewForm = nil) or (csDestroying in FPreviewForm.ComponentState) then
    Exit;

  FOverlayForm.Left := FPreviewForm.Left + FPreviewForm.Width - FOverlayForm.Width - C_Margem;
  FOverlayForm.Top := FPreviewForm.Top + FPreviewForm.Height - FOverlayForm.Height - C_Margem;
end;

end.
