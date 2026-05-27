object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Anexo Nuvem - Prototipo'
  ClientHeight = 462
  ClientWidth = 868
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object btnAnexar: TButton
    Left = 16
    Top = 25
    Width = 137
    Height = 33
    Caption = 'Anexar'
    TabOrder = 0
    OnClick = btnAnexarClick
  end
  object btnConfiguracoes: TButton
    Left = 712
    Top = 25
    Width = 137
    Height = 33
    Caption = 'Configuracoes'
    TabOrder = 1
    OnClick = btnConfiguracoesClick
  end
  object btnVisualizar: TButton
    Left = 159
    Top = 25
    Width = 137
    Height = 33
    Caption = 'Visualizar'
    TabOrder = 2
    OnClick = btnVisualizarClick
  end
  object btnApagar: TButton
    Left = 318
    Top = 25
    Width = 137
    Height = 33
    Caption = 'Apagar'
    TabOrder = 3
    OnClick = btnApagarClick
  end
  object DBGrid1: TDBGrid
    Left = 16
    Top = 64
    Width = 833
    Height = 385
    TabOrder = 4
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
end

