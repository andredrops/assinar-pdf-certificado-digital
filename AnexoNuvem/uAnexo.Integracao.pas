unit uAnexo.Integracao;

interface

uses
  Vcl.StdCtrls;

type
  TAnexoIntegracao = (aiAwsS3, aiGoogleWorkspace, aiGoogleDrive, aiSupabase);

  TAnexoIntegracaoInfo = record
  public
    class function ToDisplayName(const AIntegracao: TAnexoIntegracao): string; static;
    class function FromDisplayName(const AText: string): TAnexoIntegracao; static;
    class function All: TArray<TAnexoIntegracao>; static;
  end;

  TAnexoIntegracaoComboBinder = class
  public
    class procedure Fill(ACombo: TComboBox); static;
    class procedure SetSelected(ACombo: TComboBox; const AIntegracao: TAnexoIntegracao); static;
    class function GetSelected(ACombo: TComboBox): TAnexoIntegracao; static;
  end;

implementation

uses
  System.SysUtils;

{ TAnexoIntegracaoInfo }

class function TAnexoIntegracaoInfo.All: TArray<TAnexoIntegracao>;
begin
  Result := TArray<TAnexoIntegracao>.Create(
    aiAwsS3,
    aiGoogleWorkspace,
    aiGoogleDrive,
    aiSupabase
  );
end;

class function TAnexoIntegracaoInfo.FromDisplayName(
  const AText: string): TAnexoIntegracao;
var
  LItem: TAnexoIntegracao;
begin
  for LItem in All do
    if SameText(ToDisplayName(LItem), Trim(AText)) then
      Exit(LItem);
  Result := aiAwsS3;
end;

class function TAnexoIntegracaoInfo.ToDisplayName(
  const AIntegracao: TAnexoIntegracao): string;
begin
  case AIntegracao of
    aiAwsS3:
      Result := 'AWS S3';
    aiGoogleWorkspace:
      Result := 'Google Workspace';
    aiGoogleDrive:
      Result := 'Google Drive';
    aiSupabase:
      Result := 'Supabase';
  else
    Result := 'Desconhecido';
  end;
end;

{ TAnexoIntegracaoComboBinder }

class procedure TAnexoIntegracaoComboBinder.Fill(ACombo: TComboBox);
var
  LItem: TAnexoIntegracao;
begin
  if ACombo = nil then
    Exit;
  ACombo.Items.BeginUpdate;
  try
    ACombo.Items.Clear;
    for LItem in TAnexoIntegracaoInfo.All do
      ACombo.Items.AddObject(TAnexoIntegracaoInfo.ToDisplayName(LItem), TObject(Ord(LItem)));
  finally
    ACombo.Items.EndUpdate;
  end;
end;

class function TAnexoIntegracaoComboBinder.GetSelected(
  ACombo: TComboBox): TAnexoIntegracao;
begin
  if (ACombo = nil) or (ACombo.ItemIndex < 0) then
    Exit(aiAwsS3);
  Result := TAnexoIntegracao(NativeInt(ACombo.Items.Objects[ACombo.ItemIndex]));
end;

class procedure TAnexoIntegracaoComboBinder.SetSelected(ACombo: TComboBox;
  const AIntegracao: TAnexoIntegracao);
var
  I: Integer;
begin
  if ACombo = nil then
    Exit;
  for I := 0 to ACombo.Items.Count - 1 do
    if NativeInt(ACombo.Items.Objects[I]) = Ord(AIntegracao) then
    begin
      ACombo.ItemIndex := I;
      Exit;
    end;
  if ACombo.Items.Count > 0 then
    ACombo.ItemIndex := 0
  else
    ACombo.ItemIndex := -1;
end;

end.

