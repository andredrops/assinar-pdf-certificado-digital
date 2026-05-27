object frmUploadProgress: TfrmUploadProgress
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Upload de anexos'
  ClientHeight = 300
  ClientWidth = 520
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblTitulo: TLabel
    Left = 16
    Top = 12
    Width = 112
    Height = 19
    Caption = 'Upload de arquivos'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object lblStatus: TLabel
    Left = 16
    Top = 44
    Width = 86
    Height = 13
    Caption = 'Aguardando...'
  end
  object pbTotal: TProgressBar
    Left = 16
    Top = 64
    Width = 489
    Height = 17
    TabOrder = 0
  end
  object lstArquivos: TListBox
    Left = 16
    Top = 96
    Width = 489
    Height = 188
    ItemHeight = 13
    TabOrder = 1
  end
end


