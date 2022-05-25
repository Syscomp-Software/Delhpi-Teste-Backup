object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Teste de backup'
  ClientHeight = 299
  ClientWidth = 743
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 185
    Height = 299
    Align = alLeft
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    ExplicitLeft = 32
    ExplicitTop = 96
    ExplicitHeight = 41
    object Btn_Backup: TGPanel
      Left = 0
      Top = -2
      Width = 185
      Height = 41
      Color = clWhite
      ParentBackground = False
      TabOrder = 0
      OnClick = Btn_BackupClick
      OnMouseEnter = AplicaRemoveEfeitoBotao
      OnMouseLeave = AplicaRemoveEfeitoBotao
      Color_1 = clWhite
      object Image1: TImage
        Left = 7
        Top = 6
        Width = 35
        Height = 30
      end
      object lbTituloGoogle: TcxLabel
        Left = 46
        Top = 5
        AutoSize = False
        Caption = 'Backup'
        Enabled = False
        ParentColor = False
        ParentFont = False
        Style.Color = clWhite
        Style.Font.Charset = DEFAULT_CHARSET
        Style.Font.Color = clNavy
        Style.Font.Height = -24
        Style.Font.Name = 'Arial'
        Style.Font.Style = [fsBold]
        Style.Shadow = False
        Style.TextColor = 4079166
        Style.IsFontAssigned = True
        StyleDisabled.TextColor = 4079166
        Properties.Alignment.Horz = taLeftJustify
        Properties.Alignment.Vert = taVCenter
        Transparent = True
        Height = 33
        Width = 101
        AnchorY = 22
      end
    end
  end
  object Panel2: TPanel
    Left = 185
    Top = 0
    Width = 558
    Height = 299
    Align = alClient
    Caption = 'Panel2'
    TabOrder = 1
    ExplicitLeft = 352
    ExplicitTop = 128
    ExplicitWidth = 185
    ExplicitHeight = 41
    object Panel3: TPanel
      Left = 1
      Top = 1
      Width = 556
      Height = 97
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 545
      object Label1: TLabel
        Left = 3
        Top = 3
        Width = 101
        Height = 13
        Caption = 'Selecione um arquivo'
      end
      object Label2: TLabel
        Left = 6
        Top = 44
        Width = 130
        Height = 13
        Caption = 'Usu'#225'rio do banco de dados'
      end
      object Label3: TLabel
        Left = 148
        Top = 44
        Width = 124
        Height = 13
        Caption = 'Senha do banco de dados'
      end
      object Ed_DiretorioCompleto: TEdit
        Left = 3
        Top = 19
        Width = 502
        Height = 21
        TabOrder = 0
      end
      object Btn_Selecionar: TButton
        Left = 507
        Top = 18
        Width = 35
        Height = 23
        Caption = '...'
        TabOrder = 1
        OnClick = Btn_SelecionarClick
      end
      object Ed_Usuario: TEdit
        Left = 3
        Top = 63
        Width = 133
        Height = 21
        TabOrder = 2
      end
      object Ed_Senha: TEdit
        Left = 148
        Top = 63
        Width = 133
        Height = 21
        PasswordChar = '*'
        TabOrder = 3
      end
      object Btn_Backup_: TButton
        Left = 298
        Top = 44
        Width = 75
        Height = 25
        Caption = 'Backup'
        TabOrder = 4
      end
      object Btn_Compactar: TButton
        Left = 298
        Top = 70
        Width = 75
        Height = 25
        Caption = 'Compactar'
        TabOrder = 5
        OnClick = Btn_CompactarClick
      end
      object Btn_Restore: TButton
        Left = 375
        Top = 44
        Width = 75
        Height = 25
        Caption = 'Restore'
        TabOrder = 6
        OnClick = Btn_RestoreClick
      end
      object Btn_Descompactar: TButton
        Left = 375
        Top = 70
        Width = 75
        Height = 25
        Caption = 'Descompactar'
        TabOrder = 7
        OnClick = Btn_DescompactarClick
      end
      object Btn_Enviar: TButton
        Left = 452
        Top = 44
        Width = 75
        Height = 25
        Caption = 'Enviar'
        TabOrder = 8
      end
      object Btn_Tudo: TButton
        Left = 452
        Top = 70
        Width = 75
        Height = 25
        Caption = 'Tudo'
        TabOrder = 9
      end
    end
    object memLog: TMemo
      Left = 1
      Top = 98
      Width = 556
      Height = 200
      Align = alClient
      Lines.Strings = (
        'memLog')
      TabOrder = 1
      ExplicitLeft = 0
      ExplicitTop = 97
      ExplicitWidth = 545
      ExplicitHeight = 202
    end
  end
  object FileOpenDialog: TFileOpenDialog
    DefaultExtension = '.FDB'
    FavoriteLinks = <>
    FileTypes = <>
    Options = []
    Title = 'Selecione um arquivo'
    Left = 3
    Top = 185
  end
end
