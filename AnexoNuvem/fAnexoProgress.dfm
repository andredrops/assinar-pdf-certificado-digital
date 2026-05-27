object fAnexoProgress: TfAnexoProgress
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'Upload de Anexos'
  ClientHeight = 340
  ClientWidth = 760
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCloseQuery = FormCloseQuery
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblResumo: TLabel
    Left = 16
    Top = 20
    Width = 38
    Height = 13
    Caption = 'Resumo'
  end
  object pbTotal: TProgressBar
    Left = 16
    Top = 40
    Width = 729
    Height = 17
    TabOrder = 0
  end
  object lvArquivos: TListView
    Left = 16
    Top = 72
    Width = 729
    Height = 220
    Columns = <
      item
        Caption = 'Arquivo'
        Width = 320
      end
      item
        Caption = 'Status'
        Width = 100
      end
      item
        Caption = 'Acao'
        Width = 280
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnMouseDown = lvArquivosMouseDown
  end
  object btnCancelarPendentes: TButton
    Left = 359
    Top = 298
    Width = 145
    Height = 25
    Caption = 'Cancelar Pendentes'
    TabOrder = 2
    OnClick = btnCancelarPendentesClick
  end
  object btnFechar: TButton
    Left = 670
    Top = 298
    Width = 75
    Height = 25
    Caption = 'Fechar'
    TabOrder = 3
    OnClick = btnFecharClick
  end
  object btnTentarNovamente: TButton
    Left = 510
    Top = 298
    Width = 145
    Height = 25
    Caption = 'Tentar Novamente'
    TabOrder = 4
    OnClick = btnTentarNovamenteClick
  end
  object btnDetalhes: TButton
    Left = 16
    Top = 298
    Width = 137
    Height = 25
    Caption = '+ Mais detalhes'
    TabOrder = 5
    Visible = False
    OnClick = btnDetalhesClick
  end
  object memErros: TMemo
    Left = 16
    Top = 336
    Width = 729
    Height = 209
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 6
    Visible = False
    WordWrap = False
  end
end

