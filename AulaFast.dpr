program AulaFast;

uses
  Vcl.Forms,
  uAulaFast in 'uAulaFast.pas' {fView},
  uAssinarPDF in 'AssinarPDF\uAssinarPDF.pas',
  uPdfSignOverlay in 'AssinarPDF\uPdfSignOverlay.pas',
  uAnexo.Types in 'AnexoNuvem\uAnexo.Types.pas',
  fAnexoConfig in 'AnexoNuvem\fAnexoConfig.pas' {fAnexoConfig},
  uAnexo.Integracao in 'AnexoNuvem\uAnexo.Integracao.pas',
  uAnexo in 'AnexoNuvem\uAnexo.pas',
  uAnexo.Settings in 'AnexoNuvem\uAnexo.Settings.pas',
  uAnexo.ConfigService in 'AnexoNuvem\uAnexo.ConfigService.pas',
  uStorage.Provider.Factory in 'AnexoNuvem\uStorage.Provider.Factory.pas',
  uStorage.Provider.AwsS3 in 'AnexoNuvem\uStorage.Provider.AwsS3.pas',
  uStorage.Provider.Google in 'AnexoNuvem\uStorage.Provider.Google.pas',
  uStorage.Provider.Local in 'AnexoNuvem\uStorage.Provider.Local.pas',
  uStorage.Provider.Supabase in 'AnexoNuvem\uStorage.Provider.Supabase.pas',
  uStorage.ProviderIntf in 'AnexoNuvem\uStorage.ProviderIntf.pas',
  fAnexoProgress in 'AnexoNuvem\fAnexoProgress.pas' {fAnexoProgress},
  fUploadProgress in 'AnexoNuvem\fUploadProgress.pas' {frmUploadProgress},
  uMensagem in 'AnexoNuvem\uMensagem.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfView, fView);
  Application.Run;
end.
