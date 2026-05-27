unit uMensagem;

interface

uses
  Vcl.Forms, Vcl.StdCtrls, Vcl.ComCtrls, System.Classes;

type
  TMensagem = class;
  TMensagemClass = class of TMensagem;

  TMensagem = class
  private
    class var FForm: TForm;
    class var FLabel: TLabel;
    class var FProgress: TProgressBar;
    class var FLargura: Integer;
    class var FAltura: Integer;
    class var FThread: TThread;
    class var FStopThread: Boolean;
    class var FProgressValue: Integer;
    class procedure EnsureForm;
    class procedure StartFakeProgressThread;
    class procedure StopFakeProgressThread;
  public
    class function SetLargura(ALargura: Integer): TMensagemClass; static;
    class function SetAltura(AAltura: Integer): TMensagemClass; static;
    class procedure Execute(const ATexto: string); static;
    class procedure Atualizar; static;
    class procedure Finalizar; static;
  end;

implementation

uses
  Vcl.Controls, System.SysUtils, Winapi.Windows, Vcl.Graphics;

class procedure TMensagem.EnsureForm;
begin
  if FLargura <= 0 then
    FLargura := 280;
  if FAltura <= 0 then
    FAltura := 90;

  if Assigned(FForm) then
    Exit;

  FForm := TForm.Create(nil);
  FForm.BorderStyle := bsNone;
  FForm.Position := poScreenCenter;
  FForm.FormStyle := fsStayOnTop;
  FForm.Width := FLargura;
  FForm.Height := FAltura;
  FForm.Color := clBlack;
  FForm.AlphaBlend := True;
  FForm.AlphaBlendValue := 210;

  FLabel := TLabel.Create(FForm);
  FLabel.Parent := FForm;
  FLabel.AutoSize := False;
  FLabel.Align := alTop;
  FLabel.Height := 56;
  FLabel.Alignment := taCenter;
  FLabel.Layout := tlCenter;
  FLabel.WordWrap := True;
  FLabel.Font.Name := 'Tahoma';
  FLabel.Font.Size := 11;
  FLabel.Font.Color := clWhite;
  FLabel.Font.Style := [fsBold];
  FLabel.Transparent := True;

  FProgress := TProgressBar.Create(FForm);
  FProgress.Parent := FForm;
  FProgress.Align := alBottom;
  FProgress.Height := 20;
  FProgress.Style := pbstNormal;
  FProgress.Min := 0;
  FProgress.Max := 100;
  FProgress.Position := 0;
end;

class function TMensagem.SetAltura(AAltura: Integer): TMensagemClass;
begin
  if AAltura > 0 then
    FAltura := AAltura;
  if Assigned(FForm) then
    FForm.Height := FAltura;
  Result := TMensagem;
end;

class function TMensagem.SetLargura(ALargura: Integer): TMensagemClass;
begin
  if ALargura > 0 then
    FLargura := ALargura;
  if Assigned(FForm) then
    FForm.Width := FLargura;
  Result := TMensagem;
end;

class procedure TMensagem.Execute(const ATexto: string);
begin
  EnsureForm;
  FForm.Width := FLargura;
  FForm.Height := FAltura;
  FLabel.Caption := ATexto;
  FProgressValue := 0;
  if Assigned(FProgress) then
    FProgress.Position := 0;
  StartFakeProgressThread;
  FForm.Show;
  FForm.Update;
  Application.ProcessMessages;
end;

class procedure TMensagem.Atualizar;
begin
  if Assigned(FForm) then
  begin
    FForm.Update;
    Application.ProcessMessages;
  end;
end;

class procedure TMensagem.Finalizar;
begin
  StopFakeProgressThread;
  if Assigned(FProgress) then
  begin
    FProgress.Position := 100;
    FForm.Update;
    Application.ProcessMessages;
  end;
  FreeAndNil(FThread);
  FreeAndNil(FProgress);
  FreeAndNil(FLabel);
  FreeAndNil(FForm);
end;

class procedure TMensagem.StartFakeProgressThread;
begin
  StopFakeProgressThread;
  FStopThread := False;

  FThread := TThread.CreateAnonymousThread(
    procedure
    var
      LStep: Integer;
      LSleep: Integer;
    begin
      while not TThread.CurrentThread.CheckTerminated and (not FStopThread) do
      begin
        LStep := 8 + Random(18);   // 8..25 (mais rapido)
        LSleep := 35 + Random(90); // 35..124ms (mais fluido)
        Inc(FProgressValue, LStep);
        if FProgressValue >= 100 then
          FProgressValue := 0;

        TThread.Queue(nil,
          procedure
          begin
            if Assigned(FProgress) and Assigned(FForm) then
              FProgress.Position := FProgressValue;
          end);

        Sleep(LSleep);
      end;
    end);
  FThread.FreeOnTerminate := False;
  FThread.Start;
end;

class procedure TMensagem.StopFakeProgressThread;
begin
  FStopThread := True;
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;
  end;
end;

end.

