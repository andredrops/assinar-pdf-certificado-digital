object fAnexoConfig: TfAnexoConfig
  Left = 0
  Top = 0
  Caption = 'Configuracoes de Anexo'
  ClientHeight = 600
  ClientWidth = 820
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblProvider: TLabel
    Left = 24
    Top = 16
    Width = 49
    Height = 13
    Caption = 'Integracao'
  end
  object lblTenant: TLabel
    Left = 24
    Top = 56
    Width = 46
    Height = 13
    Caption = 'Tenant ID'
  end
  object lblUserId: TLabel
    Left = 416
    Top = 56
    Width = 39
    Height = 13
    Caption = 'User ID'
  end
  object cbProvider: TComboBox
    Left = 24
    Top = 32
    Width = 361
    Height = 21
    Style = csDropDownList
    TabOrder = 0
    OnChange = cbProviderChange
  end
  object edtTenant: TEdit
    Left = 24
    Top = 72
    Width = 361
    Height = 21
    TabOrder = 1
  end
  object edtUserId: TEdit
    Left = 416
    Top = 72
    Width = 377
    Height = 21
    TabOrder = 2
  end
  object pcIntegracoes: TPageControl
    Left = 24
    Top = 112
    Width = 769
    Height = 425
    ActivePage = tsSupabase
    TabOrder = 3
    object tsSupabase: TTabSheet
      Caption = 'Supabase'
      object lblSupabaseUrl: TLabel
        Left = 16
        Top = 24
        Width = 64
        Height = 13
        Caption = 'Supabase Url'
      end
      object lblSupabaseAnonKey: TLabel
        Left = 16
        Top = 72
        Width = 47
        Height = 13
        Caption = 'Anon Key'
      end
      object lblSupabaseEmail: TLabel
        Left = 16
        Top = 120
        Width = 23
        Height = 13
        Caption = 'Login'
      end
      object lblSupabasePassword: TLabel
        Left = 384
        Top = 120
        Width = 30
        Height = 13
        Caption = 'Senha'
      end
      object lblSupabaseBucket: TLabel
        Left = 16
        Top = 168
        Width = 33
        Height = 13
        Caption = 'Bucket'
      end
      object lblSupabaseMaxSize: TLabel
        Left = 384
        Top = 168
        Width = 82
        Height = 13
        Caption = 'Limite arquivo MB'
      end
      object edtSupabaseUrl: TEdit
        Left = 16
        Top = 40
        Width = 721
        Height = 21
        TabOrder = 0
      end
      object edtSupabaseAnonKey: TEdit
        Left = 16
        Top = 88
        Width = 721
        Height = 21
        TabOrder = 1
      end
      object edtSupabaseEmail: TEdit
        Left = 16
        Top = 136
        Width = 353
        Height = 21
        TabOrder = 2
      end
      object edtSupabasePassword: TEdit
        Left = 384
        Top = 136
        Width = 353
        Height = 21
        PasswordChar = '*'
        TabOrder = 3
      end
      object edtSupabaseBucket: TEdit
        Left = 16
        Top = 184
        Width = 353
        Height = 21
        TabOrder = 4
      end
      object edtSupabaseMaxSize: TEdit
        Left = 384
        Top = 184
        Width = 121
        Height = 21
        TabOrder = 5
      end
    end
    object tsAws: TTabSheet
      Caption = 'AWS'
      ImageIndex = 1
      object lblAwsEndpoint: TLabel
        Left = 16
        Top = 24
        Width = 44
        Height = 13
        Caption = 'Endpoint'
      end
      object lblAwsRegion: TLabel
        Left = 16
        Top = 72
        Width = 35
        Height = 13
        Caption = 'Region'
      end
      object lblAwsBucket: TLabel
        Left = 384
        Top = 72
        Width = 33
        Height = 13
        Caption = 'Bucket'
      end
      object lblAwsAccessKey: TLabel
        Left = 16
        Top = 120
        Width = 54
        Height = 13
        Caption = 'Access Key'
      end
      object lblAwsSecret: TLabel
        Left = 16
        Top = 168
        Width = 51
        Height = 13
        Caption = 'Secret Key'
      end
      object lblAwsMaxSize: TLabel
        Left = 16
        Top = 216
        Width = 82
        Height = 13
        Caption = 'Limite arquivo MB'
      end
      object edtAwsEndpoint: TEdit
        Left = 16
        Top = 40
        Width = 721
        Height = 21
        TabOrder = 0
      end
      object edtAwsRegion: TEdit
        Left = 16
        Top = 88
        Width = 337
        Height = 21
        TabOrder = 1
      end
      object edtAwsBucket: TEdit
        Left = 384
        Top = 88
        Width = 353
        Height = 21
        TabOrder = 2
      end
      object edtAwsAccessKey: TEdit
        Left = 16
        Top = 136
        Width = 721
        Height = 21
        TabOrder = 3
      end
      object edtAwsSecret: TEdit
        Left = 16
        Top = 184
        Width = 721
        Height = 21
        PasswordChar = '*'
        TabOrder = 4
      end
      object edtAwsMaxSize: TEdit
        Left = 16
        Top = 232
        Width = 121
        Height = 21
        TabOrder = 5
      end
      object btnAwsTestar: TButton
        Left = 152
        Top = 230
        Width = 75
        Height = 25
        Caption = 'Testar'
        TabOrder = 6
        OnClick = btnAwsTestarClick
      end
      object btnAwsCopiarPolicy: TButton
        Left = 240
        Top = 230
        Width = 129
        Height = 25
        Caption = 'Copiar Policy IAM'
        TabOrder = 7
        OnClick = btnAwsCopiarPolicyClick
      end
      object memAwsInstrucoes: TMemo
        Left = 16
        Top = 264
        Width = 721
        Height = 133
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 8
      end
    end
    object tsGoogle: TTabSheet
      Caption = 'Google'
      ImageIndex = 2
      object lblGoogleProjectId: TLabel
        Left = 16
        Top = 24
        Width = 41
        Height = 13
        Caption = 'Client ID'
      end
      object lblGoogleClientSecret: TLabel
        Left = 400
        Top = 24
        Width = 65
        Height = 13
        Caption = 'Client Secret'
      end
      object lblGoogleBucket: TLabel
        Left = 16
        Top = 72
        Width = 43
        Height = 13
        Caption = 'Folder ID'
      end
      object lblGoogleCredentials: TLabel
        Left = 16
        Top = 120
        Width = 71
        Height = 13
        Caption = 'Refresh Token'
      end
      object lblGoogleMaxSize: TLabel
        Left = 16
        Top = 360
        Width = 82
        Height = 13
        Caption = 'Limite arquivo MB'
      end
      object edtGoogleProjectId: TEdit
        Left = 16
        Top = 40
        Width = 353
        Height = 21
        TabOrder = 0
      end
      object edtGoogleClientSecret: TEdit
        Left = 400
        Top = 40
        Width = 337
        Height = 21
        PasswordChar = '*'
        TabOrder = 1
      end
      object edtGoogleBucket: TEdit
        Left = 16
        Top = 88
        Width = 721
        Height = 21
        TabOrder = 2
      end
      object memGoogleCredentials: TMemo
        Left = 16
        Top = 136
        Width = 721
        Height = 209
        ScrollBars = ssVertical
        TabOrder = 3
      end
      object edtGoogleMaxSize: TEdit
        Left = 16
        Top = 376
        Width = 121
        Height = 21
        TabOrder = 4
      end
      object btnGoogleConectar: TButton
        Left = 152
        Top = 374
        Width = 121
        Height = 25
        Caption = 'Conectar Google'
        TabOrder = 5
        OnClick = btnGoogleConectarClick
      end
      object btnGoogleColarUrl: TButton
        Left = 280
        Top = 374
        Width = 145
        Height = 25
        Caption = 'Colar URL OAuth'
        TabOrder = 6
        OnClick = btnGoogleColarUrlClick
      end
      object btnGoogleTestar: TButton
        Left = 432
        Top = 374
        Width = 75
        Height = 25
        Caption = 'Testar'
        TabOrder = 7
        OnClick = btnGoogleTestarClick
      end
    end
  end
  object btnSalvar: TButton
    Left = 637
    Top = 551
    Width = 75
    Height = 25
    Caption = 'Salvar'
    TabOrder = 4
    OnClick = btnSalvarClick
  end
  object btnCancelar: TButton
    Left = 718
    Top = 551
    Width = 75
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 5
    OnClick = btnCancelarClick
  end
end

