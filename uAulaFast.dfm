object fView: TfView
  Left = 0
  Top = 0
  Caption = 'Assinatura e Anexo Nuvem'
  ClientHeight = 620
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
  object pcPrincipal: TPageControl
    Left = 0
    Top = 0
    Width = 645
    Height = 620
    ActivePage = tsAnexoNuvem
    Align = alClient
    TabOrder = 0
    object tsAssinatura: TTabSheet
      Caption = 'Assinatura'
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
      object lblDescricao: TLabel
        Left = 216
        Top = 176
        Width = 50
        Height = 13
        Caption = 'Descricao:'
      end
      object lblAlias: TLabel
        Left = 216
        Top = 200
        Width = 26
        Height = 13
        Caption = 'Alias:'
      end
      object lblIndice: TLabel
        Left = 216
        Top = 224
        Width = 33
        Height = 13
        Caption = 'Indice:'
      end
      object lblNome: TLabel
        Left = 216
        Top = 248
        Width = 31
        Height = 13
        Caption = 'Nome:'
      end
      object lblDocumento: TLabel
        Left = 216
        Top = 272
        Width = 58
        Height = 13
        Caption = 'Documento:'
      end
      object lblValidoAte: TLabel
        Left = 216
        Top = 296
        Width = 52
        Height = 13
        Caption = 'Valido Ate:'
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
      object btnCarregarCertificados: TButton
        Left = 216
        Top = 320
        Width = 200
        Height = 41
        Caption = 'Carregar Certificados'
        TabOrder = 3
        OnClick = btnCarregarCertificadosClick
      end
      object btnSelecionarCertificado: TButton
        Left = 422
        Top = 320
        Width = 215
        Height = 41
        Caption = 'Selecionar Certificado'
        TabOrder = 4
        OnClick = btnSelecionarCertificadoClick
      end
      object cbCertificados: TComboBox
        Left = 216
        Top = 146
        Width = 421
        Height = 21
        Style = csDropDownList
        TabOrder = 5
      end
      object edtDescricao: TEdit
        Left = 290
        Top = 173
        Width = 347
        Height = 21
        TabStop = False
        ReadOnly = True
        TabOrder = 6
      end
      object edtAlias: TEdit
        Left = 290
        Top = 197
        Width = 347
        Height = 21
        TabStop = False
        ReadOnly = True
        TabOrder = 7
      end
      object edtIndice: TEdit
        Left = 290
        Top = 221
        Width = 347
        Height = 21
        TabStop = False
        ReadOnly = True
        TabOrder = 8
      end
      object edtNome: TEdit
        Left = 290
        Top = 245
        Width = 347
        Height = 21
        TabStop = False
        ReadOnly = True
        TabOrder = 9
      end
      object edtDocumento: TEdit
        Left = 290
        Top = 269
        Width = 347
        Height = 21
        TabStop = False
        ReadOnly = True
        TabOrder = 10
      end
      object edtValidoAte: TEdit
        Left = 290
        Top = 293
        Width = 347
        Height = 21
        TabStop = False
        ReadOnly = True
        TabOrder = 11
      end
      object DBGrid1: TDBGrid
        Left = 0
        Top = 376
        Width = 637
        Height = 216
        Align = alBottom
        DataSource = dsDados
        TabOrder = 12
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
        TabOrder = 13
      end
    end
    object tsAnexoNuvem: TTabSheet
      Caption = 'Anexo Nuvem'
      ImageIndex = 1
      DesignSize = (
        637
        592)
      object btnAnexoAnexar: TButton
        Left = 16
        Top = 16
        Width = 137
        Height = 33
        Caption = 'Anexar'
        TabOrder = 0
        OnClick = btnAnexoAnexarClick
      end
      object btnAnexoConfiguracoes: TButton
        Left = 490
        Top = 16
        Width = 137
        Height = 33
        Caption = 'Configuracoes'
        TabOrder = 1
        OnClick = btnAnexoConfiguracoesClick
      end
      object gridAnexo: TDBGrid
        Left = 16
        Top = 64
        Width = 611
        Height = 480
        Anchors = [akLeft, akTop, akRight, akBottom]
        DataSource = dsAnexo
        TabOrder = 2
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -11
        TitleFont.Name = 'Tahoma'
        TitleFont.Style = []
      end
      object btnAnexoVisualizar: TButton
        Left = 16
        Top = 550
        Width = 137
        Height = 33
        Anchors = [akLeft, akBottom]
        Caption = 'Visualizar'
        TabOrder = 3
        OnClick = btnAnexoVisualizarClick
      end
      object btnAnexoApagar: TButton
        Left = 159
        Top = 550
        Width = 137
        Height = 33
        Anchors = [akLeft, akBottom]
        Caption = 'Apagar'
        TabOrder = 4
        OnClick = btnAnexoApagarClick
      end
    end
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
  object dsAnexo: TDataSource
    DataSet = mtAnexo
    Left = 472
    Top = 168
  end
  object mtAnexo: TFDMemTable
    Active = True
    FieldDefs = <
      item
        Name = 'ID'
        DataType = ftInteger
      end
      item
        Name = 'Descricao'
        DataType = ftString
        Size = 180
      end
      item
        Name = 'Extensao'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'Tamanho'
        DataType = ftLargeint
      end
      item
        Name = 'Chave'
        DataType = ftString
        Size = 512
      end
      item
        Name = 'NomeArquivo'
        DataType = ftString
        Size = 255
      end>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 520
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
