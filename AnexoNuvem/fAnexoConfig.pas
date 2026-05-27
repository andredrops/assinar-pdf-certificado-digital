unit fAnexoConfig;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Winapi.ShellAPI, System.NetEncoding, System.Net.HttpClient, System.Net.URLClient,
  System.JSON, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.Clipbrd, uAnexo.Settings, uAnexo.Integracao;

type
  TfAnexoConfig = class(TForm)
    lblTenant: TLabel;
    edtTenant: TEdit;
    lblUserId: TLabel;
    edtUserId: TEdit;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    pcIntegracoes: TPageControl;
    tsSupabase: TTabSheet;
    tsAws: TTabSheet;
    tsGoogle: TTabSheet;
    lblSupabaseUrl: TLabel;
    edtSupabaseUrl: TEdit;
    lblSupabaseAnonKey: TLabel;
    edtSupabaseAnonKey: TEdit;
    lblSupabaseEmail: TLabel;
    edtSupabaseEmail: TEdit;
    lblSupabasePassword: TLabel;
    edtSupabasePassword: TEdit;
    lblSupabaseBucket: TLabel;
    edtSupabaseBucket: TEdit;
    lblSupabaseMaxSize: TLabel;
    edtSupabaseMaxSize: TEdit;
    lblAwsEndpoint: TLabel;
    edtAwsEndpoint: TEdit;
    lblAwsRegion: TLabel;
    edtAwsRegion: TEdit;
    lblAwsBucket: TLabel;
    edtAwsBucket: TEdit;
    lblAwsAccessKey: TLabel;
    edtAwsAccessKey: TEdit;
    lblAwsSecret: TLabel;
    edtAwsSecret: TEdit;
    lblAwsMaxSize: TLabel;
    edtAwsMaxSize: TEdit;
    btnAwsTestar: TButton;
    memAwsInstrucoes: TMemo;
    btnAwsCopiarPolicy: TButton;
    lblGoogleProjectId: TLabel;
    edtGoogleProjectId: TEdit;
    lblGoogleBucket: TLabel;
    edtGoogleBucket: TEdit;
    lblGoogleCredentials: TLabel;
    memGoogleCredentials: TMemo;
    lblGoogleClientSecret: TLabel;
    edtGoogleClientSecret: TEdit;
    btnGoogleConectar: TButton;
    btnGoogleTestar: TButton;
    btnGoogleColarUrl: TButton;
    lblGoogleMaxSize: TLabel;
    edtGoogleMaxSize: TEdit;
    btnSalvar: TButton;
    btnCancelar: TButton;
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnGoogleConectarClick(Sender: TObject);
    procedure btnGoogleTestarClick(Sender: TObject);
    procedure btnGoogleColarUrlClick(Sender: TObject);
    procedure btnAwsTestarClick(Sender: TObject);
    procedure btnAwsCopiarPolicyClick(Sender: TObject);
  private
    FSettings: TAnexoSettings;
    function BuildAwsPolicyJson(const ABucketName: string): string;
    function BuildGoogleAuthUrl: string;
    function ExtractQueryParam(const AUrl, AParam: string): string;
    function ExchangeGoogleAuthCodeForRefreshToken(const AAuthCode: string): string;
    procedure ProcessGoogleRedirectUrl(const ARedirectUrl: string);
    procedure LoadToUi;
    procedure SaveFromUi;
    procedure HideIntegrationTabs;
    procedure ShowSelectedIntegrationTab;
  public
  end;

function ShowAnexoConfig: Boolean;

implementation

{$R *.dfm}

uses
  uAnexo.ConfigService, uStorage.Provider.Factory, uStorage.ProviderIntf, uAnexo.Types;

function ShowAnexoConfig: Boolean;
var
  LForm: TfAnexoConfig;
begin
  LForm := TfAnexoConfig.Create(nil);
  try
    Result := LForm.ShowModal = mrOk;
  finally
    LForm.Free;
  end;
end;

procedure TfAnexoConfig.btnAwsCopiarPolicyClick(Sender: TObject);
var
  LBucket: string;
begin
  LBucket := Trim(edtAwsBucket.Text);
  if LBucket = '' then
    raise Exception.Create('Informe o bucket antes de copiar a policy IAM.');

  Clipboard.AsText := BuildAwsPolicyJson(LBucket);
  ShowMessage('Policy IAM copiada para a area de transferencia.');
end;

function TfAnexoConfig.BuildAwsPolicyJson(const ABucketName: string): string;
begin
  Result :=
    '{' + sLineBreak +
    '  "Version": "2012-10-17",' + sLineBreak +
    '  "Statement": [' + sLineBreak +
    '    {' + sLineBreak +
    '      "Sid": "ListBucket",' + sLineBreak +
    '      "Effect": "Allow",' + sLineBreak +
    '      "Action": ["s3:ListBucket"],' + sLineBreak +
    '      "Resource": ["arn:aws:s3:::' + ABucketName + '"]' + sLineBreak +
    '    },' + sLineBreak +
    '    {' + sLineBreak +
    '      "Sid": "ObjectRW",' + sLineBreak +
    '      "Effect": "Allow",' + sLineBreak +
    '      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],' + sLineBreak +
    '      "Resource": ["arn:aws:s3:::' + ABucketName + '/*"]' + sLineBreak +
    '    }' + sLineBreak +
    '  ]' + sLineBreak +
    '}';
end;

procedure TfAnexoConfig.btnCancelarClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfAnexoConfig.btnGoogleConectarClick(Sender: TObject);
var
  LAuthUrl: string;
  LRedirectUrl: string;
begin
  if Trim(edtGoogleProjectId.Text) = '' then
    raise Exception.Create('Informe o Client ID antes de conectar.');
  if Trim(edtGoogleClientSecret.Text) = '' then
    raise Exception.Create('Informe o Client Secret antes de conectar.');

  LAuthUrl := BuildGoogleAuthUrl;
  ShellExecute(0, 'open', PChar(LAuthUrl), nil, nil, SW_SHOWNORMAL);

  LRedirectUrl := '';
  if not InputQuery('Conectar Google',
    'Cole aqui a URL final exibida no navegador apos autorizar:', LRedirectUrl) then
    Exit;

  ProcessGoogleRedirectUrl(LRedirectUrl);
end;

procedure TfAnexoConfig.btnAwsTestarClick(Sender: TObject);
var
  LSettings: TAnexoSettings;
  LContext: TAnexoContext;
  LProvider: IStorageProvider;
  LTempFile: string;
  LResult: TUploadBatchResult;
  LItem: TUploadItemResult;
  LContent: TStringList;
  LOk: Boolean;
begin
  SaveFromUi;

  LSettings := TAnexoSettings.Create;
  try
    LSettings.Assign(FSettings);
    LSettings.FIntegracao := aiAwsS3;

    LContext := TAnexoContext.Create;
    try
      LContext.Integracao := aiAwsS3;
      LContext.TenantId := Trim(LSettings.FTenantId);
      LContext.UserId := Trim(LSettings.FUserId);
      LContext.Credentials.AwsEndpoint := Trim(LSettings.FAwsEndpoint);
      LContext.Credentials.AwsRegion := Trim(LSettings.FAwsRegion);
      LContext.Credentials.AwsBucket := Trim(LSettings.FAwsBucket);
      LContext.Credentials.AwsAccessKey := Trim(LSettings.FAwsAccessKey);
      LContext.Credentials.AwsSecretKey := Trim(LSettings.FAwsSecretKey);

      LTempFile := TPath.Combine(TPath.GetTempPath,
        Format('anexo_teste_aws_%s.txt', [FormatDateTime('yyyymmdd_hhnnss', Now)]));
      LContent := TStringList.Create;
      try
        LContent.Text := 'Teste de conectividade AWS S3 - ' + DateTimeToStr(Now);
        LContent.SaveToFile(LTempFile, TEncoding.UTF8);
      finally
        LContent.Free;
      end;

      SetLength(LContext.Arquivos, 1);
      LContext.Arquivos[0] := LTempFile;

      LProvider := TStorageProviderFactory.CreateProvider(aiAwsS3);
      LResult := LProvider.UploadFiles(LContext, nil, nil);
      try
        LOk := (LResult.Items.Count > 0) and LResult.Items[0].Success;
        if not LOk then
        begin
          if LResult.Items.Count > 0 then
            raise Exception.Create('Falha no teste AWS: ' + LResult.Items[0].MessageText)
          else
            raise Exception.Create('Falha no teste AWS: retorno vazio.');
        end;

        LItem := LResult.Items[0];
        if Trim(LItem.RemotePath) <> '' then
          LProvider.DeleteFile(LContext, LItem.RemotePath);
      finally
        LResult.Free;
      end;

      if TFile.Exists(LTempFile) then
        TFile.Delete(LTempFile);

      ShowMessage('Teste concluido com sucesso. Upload e exclusao validados no AWS S3.');
    finally
      LContext.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TfAnexoConfig.btnGoogleTestarClick(Sender: TObject);
var
  LSettings: TAnexoSettings;
  LContext: TAnexoContext;
  LProvider: IStorageProvider;
  LTempFile: string;
  LResult: TUploadBatchResult;
  LItem: TUploadItemResult;
  LContent: TStringList;
  LOk: Boolean;
begin
  SaveFromUi;

  LSettings := TAnexoSettings.Create;
  try
    LSettings.Assign(FSettings);
    LSettings.FIntegracao := aiGoogleDrive;

    LContext := TAnexoContext.Create;
    try
      LContext.Integracao := aiGoogleDrive;
      LContext.TenantId := Trim(LSettings.FTenantId);
      LContext.UserId := Trim(LSettings.FUserId);
      LContext.Credentials.GoogleClientId := Trim(LSettings.FGoogleClientId);
      LContext.Credentials.GoogleClientSecret := Trim(LSettings.FGoogleClientSecret);
      LContext.Credentials.GoogleFolderId := Trim(LSettings.FGoogleFolderId);
      LContext.Credentials.GoogleRefreshToken := Trim(LSettings.FGoogleRefreshToken);

      LTempFile := TPath.Combine(TPath.GetTempPath,
        Format('anexo_teste_google_%s.txt', [FormatDateTime('yyyymmdd_hhnnss', Now)]));
      LContent := TStringList.Create;
      try
        LContent.Text := 'Teste de conectividade Google Drive - ' + DateTimeToStr(Now);
        LContent.SaveToFile(LTempFile, TEncoding.UTF8);
      finally
        LContent.Free;
      end;

      SetLength(LContext.Arquivos, 1);
      LContext.Arquivos[0] := LTempFile;

      LProvider := TStorageProviderFactory.CreateProvider(aiGoogleDrive);
      LResult := LProvider.UploadFiles(LContext, nil, nil);
      try
        LOk := (LResult.Items.Count > 0) and LResult.Items[0].Success;
        if not LOk then
        begin
          if LResult.Items.Count > 0 then
            raise Exception.Create('Falha no teste Google: ' + LResult.Items[0].MessageText)
          else
            raise Exception.Create('Falha no teste Google: retorno vazio.');
        end;

        LItem := LResult.Items[0];
        if Trim(LItem.RemotePath) <> '' then
          LProvider.DeleteFile(LContext, LItem.RemotePath);
      finally
        LResult.Free;
      end;

      if TFile.Exists(LTempFile) then
        TFile.Delete(LTempFile);

      ShowMessage('Teste concluido com sucesso. Upload e exclusao validados no Google Drive.');
    finally
      LContext.Free;
    end;
  finally
    LSettings.Free;
  end;
end;

procedure TfAnexoConfig.btnGoogleColarUrlClick(Sender: TObject);
var
  LRedirectUrl: string;
begin
  LRedirectUrl := '';
  if not InputQuery('Gerar Refresh Token',
    'Cole a URL final com "code=" para gerar o refresh token:', LRedirectUrl) then
    Exit;
  ProcessGoogleRedirectUrl(LRedirectUrl);
end;

procedure TfAnexoConfig.btnSalvarClick(Sender: TObject);
begin
  SaveFromUi;
  TAnexoConfigService.SaveSettings(FSettings);
  ModalResult := mrOk;
end;

function TfAnexoConfig.BuildGoogleAuthUrl: string;
const
  CRedirectUri = 'http://localhost';
  CScope = 'https://www.googleapis.com/auth/drive.file';
begin
  Result := 'https://accounts.google.com/o/oauth2/v2/auth?' +
    'client_id=' + TNetEncoding.URL.Encode(Trim(edtGoogleProjectId.Text)) +
    '&redirect_uri=' + TNetEncoding.URL.Encode(CRedirectUri) +
    '&response_type=code' +
    '&scope=' + TNetEncoding.URL.Encode(CScope) +
    '&access_type=offline' +
    '&prompt=consent';
end;

procedure TfAnexoConfig.cbProviderChange(Sender: TObject);
begin
  ShowSelectedIntegrationTab;
end;

function TfAnexoConfig.ExtractQueryParam(const AUrl, AParam: string): string;
var
  LQuery: string;
  LParts: TArray<string>;
  LItem: string;
  LName: string;
  LValue: string;
  P: Integer;
begin
  Result := '';
  LQuery := AUrl;
  P := Pos('?', LQuery);
  if P > 0 then
    LQuery := Copy(LQuery, P + 1, MaxInt);
  P := Pos('#', LQuery);
  if P > 0 then
    LQuery := Copy(LQuery, 1, P - 1);

  LParts := LQuery.Split(['&']);
  for LItem in LParts do
  begin
    P := Pos('=', LItem);
    if P <= 0 then
      Continue;
    LName := Copy(LItem, 1, P - 1);
    LValue := Copy(LItem, P + 1, MaxInt);
    if SameText(LName, AParam) then
    begin
      Result := TNetEncoding.URL.Decode(LValue);
      Exit;
    end;
  end;
end;

function TfAnexoConfig.ExchangeGoogleAuthCodeForRefreshToken(const AAuthCode: string): string;
const
  CRedirectUri = 'http://localhost';
var
  LClient: THTTPClient;
  LResp: IHTTPResponse;
  LBody: TStringStream;
  LBodyText: string;
  LJson: TJSONObject;
  LValue: TJSONValue;
begin
  LBodyText :=
    'code=' + TNetEncoding.URL.Encode(AAuthCode) + '&' +
    'client_id=' + TNetEncoding.URL.Encode(Trim(edtGoogleProjectId.Text)) + '&' +
    'client_secret=' + TNetEncoding.URL.Encode(Trim(edtGoogleClientSecret.Text)) + '&' +
    'redirect_uri=' + TNetEncoding.URL.Encode(CRedirectUri) + '&' +
    'grant_type=authorization_code';

  LClient := THTTPClient.Create;
  try
    LBody := TStringStream.Create(LBodyText, TEncoding.UTF8);
    try
      LResp := LClient.Post('https://oauth2.googleapis.com/token', LBody, nil,
        [TNameValuePair.Create('Content-Type', 'application/x-www-form-urlencoded')]);
    finally
      LBody.Free;
    end;

    if (LResp.StatusCode div 100) <> 2 then
      raise Exception.CreateFmt('Falha ao trocar code por refresh_token. HTTP %d: %s',
        [LResp.StatusCode, LResp.ContentAsString(TEncoding.UTF8)]);

    LJson := TJSONObject.ParseJSONValue(LResp.ContentAsString(TEncoding.UTF8)) as TJSONObject;
    try
      if LJson = nil then
        raise Exception.Create('Resposta invalida do Google OAuth.');
      LValue := LJson.GetValue('refresh_token');
      if LValue = nil then
        raise Exception.Create('refresh_token nao retornado. Tente autorizar novamente com prompt=consent.');
      Result := LValue.Value;
    finally
      LJson.Free;
    end;
  finally
    LClient.Free;
  end;
end;

procedure TfAnexoConfig.ProcessGoogleRedirectUrl(const ARedirectUrl: string);
var
  LCode: string;
  LRefreshToken: string;
begin
  LCode := ExtractQueryParam(ARedirectUrl, 'code');
  if Trim(LCode) = '' then
    raise Exception.Create('Nao foi possivel encontrar o parametro "code" na URL informada.');

  LRefreshToken := ExchangeGoogleAuthCodeForRefreshToken(LCode);
  memGoogleCredentials.Lines.Text := LRefreshToken;
  ShowMessage('Refresh Token gerado e preenchido com sucesso.');
end;

procedure TfAnexoConfig.FormShow(Sender: TObject);
begin
  TAnexoIntegracaoComboBinder.Fill(cbProvider);

  FSettings := TAnexoConfigService.LoadSettings;
  LoadToUi;
  HideIntegrationTabs;
  ShowSelectedIntegrationTab;
end;

procedure TfAnexoConfig.FormDestroy(Sender: TObject);
begin
  FSettings.Free;
end;

procedure TfAnexoConfig.LoadToUi;
begin
  TAnexoIntegracaoComboBinder.SetSelected(cbProvider, FSettings.FIntegracao);
  edtTenant.Text := FSettings.FTenantId;
  edtUserId.Text := FSettings.FUserId;

  edtSupabaseUrl.Text := FSettings.FSupabaseUrl;
  edtSupabaseAnonKey.Text := FSettings.FSupabaseAnonKey;
  edtSupabaseEmail.Text := FSettings.FSupabaseEmail;
  edtSupabasePassword.Text := FSettings.FSupabasePassword;
  edtSupabaseBucket.Text := FSettings.FSupabaseBucket;
  edtSupabaseMaxSize.Text := IntToStr(FSettings.FSupabaseMaxFileSizeMB);

  edtAwsEndpoint.Text := FSettings.FAwsEndpoint;
  edtAwsRegion.Text := FSettings.FAwsRegion;
  edtAwsBucket.Text := FSettings.FAwsBucket;
  edtAwsAccessKey.Text := FSettings.FAwsAccessKey;
  edtAwsSecret.Text := FSettings.FAwsSecretKey;
  edtAwsMaxSize.Text := IntToStr(FSettings.FAwsMaxFileSizeMB);
  memAwsInstrucoes.Lines.Text :=
    'Passos rapidos para permissao IAM:' + sLineBreak +
    '1. IAM > Usuarios > anex-nuvem-iam' + sLineBreak +
    '2. Adicionar permissoes > Criar politica inline' + sLineBreak +
    '3. Aba JSON > colar policy copiada > salvar' + sLineBreak +
    '4. Testar novamente no botao Testar AWS' + sLineBreak + sLineBreak +
    'Observacao:' + sLineBreak +
    '- A policy muda apenas no nome do bucket.' + sLineBreak +
    '- O botao "Copiar Policy IAM" usa o bucket informado neste formulario.';

  edtGoogleProjectId.Text := FSettings.FGoogleClientId;
  edtGoogleClientSecret.Text := FSettings.FGoogleClientSecret;
  edtGoogleBucket.Text := FSettings.FGoogleFolderId;
  memGoogleCredentials.Lines.Text := FSettings.FGoogleRefreshToken;
  edtGoogleMaxSize.Text := IntToStr(FSettings.FGoogleMaxFileSizeMB);
end;

procedure TfAnexoConfig.SaveFromUi;
begin
  FSettings.FIntegracao := TAnexoIntegracaoComboBinder.GetSelected(cbProvider);
  FSettings.FTenantId := Trim(edtTenant.Text);
  FSettings.FUserId := Trim(edtUserId.Text);

  FSettings.FSupabaseUrl := Trim(edtSupabaseUrl.Text);
  FSettings.FSupabaseAnonKey := Trim(edtSupabaseAnonKey.Text);
  FSettings.FSupabaseEmail := Trim(edtSupabaseEmail.Text);
  FSettings.FSupabasePassword := Trim(edtSupabasePassword.Text);
  FSettings.FSupabaseBucket := Trim(edtSupabaseBucket.Text);
  FSettings.FSupabaseMaxFileSizeMB := StrToIntDef(Trim(edtSupabaseMaxSize.Text), 50);

  FSettings.FAwsEndpoint := Trim(edtAwsEndpoint.Text);
  FSettings.FAwsRegion := Trim(edtAwsRegion.Text);
  FSettings.FAwsBucket := Trim(edtAwsBucket.Text);
  FSettings.FAwsAccessKey := Trim(edtAwsAccessKey.Text);
  FSettings.FAwsSecretKey := Trim(edtAwsSecret.Text);
  FSettings.FAwsMaxFileSizeMB := StrToIntDef(Trim(edtAwsMaxSize.Text), 50);

  FSettings.FGoogleClientId := Trim(edtGoogleProjectId.Text);
  FSettings.FGoogleClientSecret := Trim(edtGoogleClientSecret.Text);
  FSettings.FGoogleFolderId := Trim(edtGoogleBucket.Text);
  FSettings.FGoogleRefreshToken := Trim(memGoogleCredentials.Lines.Text);
  FSettings.FGoogleMaxFileSizeMB := StrToIntDef(Trim(edtGoogleMaxSize.Text), 50);
end;

procedure TfAnexoConfig.HideIntegrationTabs;
begin
  tsSupabase.TabVisible := False;
  tsAws.TabVisible := False;
  tsGoogle.TabVisible := False;
end;

procedure TfAnexoConfig.ShowSelectedIntegrationTab;
begin
  HideIntegrationTabs;

  case TAnexoIntegracaoComboBinder.GetSelected(cbProvider) of
    aiSupabase:
      begin
        tsSupabase.TabVisible := True;
        pcIntegracoes.ActivePage := tsSupabase;
      end;
    aiAwsS3:
      begin
        tsAws.TabVisible := True;
        pcIntegracoes.ActivePage := tsAws;
      end;
    aiGoogleDrive, aiGoogleWorkspace:
      begin
        tsGoogle.TabVisible := True;
        pcIntegracoes.ActivePage := tsGoogle;
      end;
  else
    tsSupabase.TabVisible := True;
    pcIntegracoes.ActivePage := tsSupabase;
  end;
end;

end.

