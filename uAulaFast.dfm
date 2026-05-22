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
    Width = 421
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
    DataSet = frxDBClientes
    DataSetName = 'frxDBClientes'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick]
    PreviewOptions.Zoom = 1.000000000000000000
    PrintOptions.Printer = 'Default'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.CreateDate = 46115.352991875000000000
    ReportOptions.LastChange = 46115.362163333330000000
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
    Variables = <>
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
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Height = 30.236240000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        DataSet = frxDBClientes
        DataSetName = 'frxDBClientes'
        RowCount = 0
      end
    end
    object Page2: TfrxReportPage
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      object MasterData2: TfrxMasterData
        FillType = ftBrush
        Height = 22.677180000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        DataSet = frxDBClientes
        DataSetName = 'frxDBClientes'
        RowCount = 0
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
