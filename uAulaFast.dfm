object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 417
  ClientWidth = 645
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 216
    Top = 8
    Width = 386
    Height = 13
    Caption = 
      'Exemplo de Carimbo de Assinatura e variaveis para adicionar ao F' +
      'R3'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object btnImprimir: TButton
    Left = 0
    Top = 0
    Width = 200
    Height = 41
    Caption = 'Imprimir'
    TabOrder = 0
    OnClick = btnImprimirClick
  end
  object btnAssinarPdf: TButton
    Left = 0
    Top = 41
    Width = 200
    Height = 41
    Caption = 'Assinar PDF'
    TabOrder = 1
    OnClick = btnAssinarPdfClick
  end
  object btnDiagnostico: TButton
    Left = 0
    Top = 82
    Width = 200
    Height = 41
    Caption = 'Diagnostico Certificados'
    TabOrder = 2
    OnClick = btnDiagnosticoClick
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 220
    Width = 645
    Height = 197
    Align = alBottom
    DataSource = dsDados
    TabOrder = 3
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
  end
  object Memo1: TMemo
    Left = 216
    Top = 27
    Width = 421
    Height = 115
    Lines.Strings = (
      'Assinado por: [AssinadoPor]'
      'CPF/CNPJ: [CpfCnpjAssinante]'
      'Data/Hora assinatura: [DataHoraAssinatura]'
      'Algoritmo: [AlgoritmoAssinatura]'
      'ID validacao: [IdValidacao]'
      'Validar em: [UrlValidacao]')
    TabOrder = 4
  end
  object dsDados: TDataSource
    DataSet = mtDados
    Left = 376
    Top = 168
  end
  object mtDados: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 280
    Top = 152
  end
  object frxRelClientes: TfrxReport
    Version = '5.3.14'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick]
    PreviewOptions.Zoom = 1.000000000000000000
    PrintOptions.Printer = 'Default'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.CreateDate = 46164.422809861100000000
    ReportOptions.LastChange = 46164.427615011580000000
    ScriptLanguage = 'PascalScript'
    ScriptText.Strings = (
      'begin'
      ''
      'end.')
    Left = 120
    Top = 144
    Datasets = <
      item
        DataSet = frxDBClientes
        DataSetName = 'frxDBClientes'
      end>
    Variables = <
      item
        Name = 'AssinadoPor'
        Value = ''
      end
      item
        Name = 'CpfCnpjAssinante'
        Value = ''
      end
      item
        Name = 'DataHoraAssinatura'
        Value = ''
      end
      item
        Name = 'AlgoritmoAssinatura'
        Value = ''
      end
      item
        Name = 'IdValidacao'
        Value = ''
      end
      item
        Name = 'UrlValidacao'
        Value = ''
      end>
    Style = <>
    object Data: TfrxDataPage
      Height = 1000.000000000000000000
      Width = 1000.000000000000000000
    end
    object Page1: TfrxReportPage
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object ReportTitle1: TfrxReportTitle
        FillType = ftBrush
        Height = 22.000000000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        object MemoTitulo: TfrxMemoView
          Width = 718.110700000000000000
          Height = 20.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -16
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Memo.UTF8W = (
            'Relatorio de Clientes')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        Height = 18.000000000000000000
        Top = 64.252010000000000000
        Width = 718.110700000000000000
        object MemoH1: TfrxMemoView
          Width = 50.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          HAlign = haCenter
          Memo.UTF8W = (
            'ID')
          ParentFont = False
        end
        object MemoH2: TfrxMemoView
          Left = 50.000000000000000000
          Width = 458.000000000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            'Nome')
          ParentFont = False
        end
        object MemoH3: TfrxMemoView
          Left = 508.000000000000000000
          Width = 210.110700000000000000
          Height = 18.000000000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            'Telefone')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 18.000000000000000000
        Top = 143.622140000000000000
        Width = 718.110700000000000000
        DataSet = frxDBClientes
        DataSetName = 'frxDBClientes'
        RowCount = 0
        object MemoNome: TfrxMemoView
          Left = 50.000000000000000000
          Width = 458.000000000000000000
          Height = 18.000000000000000000
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[frxDBClientes."Nome"]')
        end
        object MemoTel: TfrxMemoView
          Left = 508.000000000000000000
          Width = 210.110700000000000000
          Height = 18.000000000000000000
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[frxDBClientes."Telefone"]')
        end
        object Memo1: TfrxMemoView
          Width = 49.810760000000000000
          Height = 18.000000000000000000
          Frame.Typ = [ftLeft, ftRight, ftTop, ftBottom]
          Memo.UTF8W = (
            '[frxDBClientes."id"]')
        end
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        Height = 163.354360000000000000
        Top = 222.992270000000000000
        Width = 718.110700000000000000
        object MemoAssinadoPor: TfrxMemoView
          Left = 358.188930000000000000
          Top = 37.795300000000000000
          Width = 288.110700000000000000
          Height = 14.000000000000000000
          Memo.UTF8W = (
            'Assinado por: [AssinadoPor]')
        end
        object MemoCpf: TfrxMemoView
          Left = 358.188930000000000000
          Top = 51.795300000000000000
          Width = 288.110700000000000000
          Height = 14.000000000000000000
          Memo.UTF8W = (
            'CPF/CNPJ: [CpfCnpjAssinante]')
        end
        object MemoDataHora: TfrxMemoView
          Left = 358.188930000000000000
          Top = 65.795300000000000000
          Width = 288.110700000000000000
          Height = 14.000000000000000000
          Memo.UTF8W = (
            'Data/Hora assinatura: [DataHoraAssinatura]')
        end
        object MemoAlg: TfrxMemoView
          Left = 358.188930000000000000
          Top = 79.795300000000000000
          Width = 288.110700000000000000
          Height = 14.000000000000000000
          Memo.UTF8W = (
            'Algoritmo: [AlgoritmoAssinatura]')
        end
        object MemoUrl: TfrxMemoView
          Left = 358.188930000000000000
          Top = 107.795300000000000000
          Width = 288.110700000000000000
          Height = 14.000000000000000000
          Memo.UTF8W = (
            'Validar em: [UrlValidacao]')
        end
        object LineAss: TfrxLineView
          Left = 358.188930000000000000
          Top = 129.795300000000000000
          Width = 180.000000000000000000
          Color = clBlack
          Frame.Typ = [ftTop]
        end
        object MemoAssinatura: TfrxMemoView
          Left = 398.188930000000000000
          Top = 131.795300000000000000
          Width = 100.000000000000000000
          Height = 14.000000000000000000
          HAlign = haCenter
          Memo.UTF8W = (
            'Assinatura')
        end
        object MemoPagina: TfrxMemoView
          Left = 608.661410000000000000
          Top = 143.133890000000000000
          Width = 98.110700000000000000
          Height = 14.000000000000000000
          HAlign = haRight
          Memo.UTF8W = (
            'Pagina [Page#] de [TotalPages#]')
        end
      end
    end
  end
  object frxDBClientes: TfrxDBDataset
    UserName = 'frxDBClientes'
    CloseDataSource = False
    DataSet = mtDados
    BCDToCurrency = False
    Left = 208
    Top = 176
  end
end
