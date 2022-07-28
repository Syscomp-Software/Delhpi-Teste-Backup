unit uFrmPrincipal;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, cxControls, cxLookAndFeels, cxLookAndFeelPainters,
  cxContainer, cxEdit, dxSkinsCore, dxSkinBlack, dxSkinBlue, dxSkinCaramel,
  dxSkinCoffee, dxSkinDarkRoom, dxSkinDarkSide, dxSkinFoggy, dxSkinGlassOceans,
  dxSkiniMaginary, dxSkinLilian, dxSkinLiquidSky, dxSkinLondonLiquidSky,
  dxSkinMcSkin, dxSkinMoneyTwins, dxSkinOffice2007Black, dxSkinOffice2007Blue,
  dxSkinOffice2007Green, dxSkinOffice2007Pink, dxSkinOffice2007Silver,
  dxSkinPumpkin, dxSkinSeven, dxSkinSharp, dxSkinSilver, dxSkinSpringTime,
  dxSkinStardust, dxSkinSummer2008, dxSkinsDefaultPainters, dxSkinValentine,
  dxSkinXmas2008Blue, ExtCtrls, cxLabel, StdCtrls, Buttons, IdIOHandler,
  IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, IdHTTP,
  uBancoDados, uZip, uAuthGoogle, uGoogleDrive,
  GPanel, dxGDIPlusClasses,
  uCEFOAuth2Helper, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer,
  IdContext;

type
  TFrmPrincipal = class(TForm)
    FileOpenDialog: TFileOpenDialog;
    Panel2: TPanel;
    memLog: TMemo;
    GPanel1: TGPanel;
    cxLabel5: TcxLabel;
    GPanel2: TGPanel;
    Pn_SubMenu: TGPanel;
    Btn_Backup: TGPanel;
    lbTituloGoogle: TcxLabel;
    Btn_Restore: TGPanel;
    cxLabel1: TcxLabel;
    Btn_BancoDados: TGPanel;
    Image6: TImage;
    cxLabel6: TcxLabel;
    Btn_Compressao: TGPanel;
    Image1: TImage;
    cxLabel7: TcxLabel;
    Btn_Compactar: TGPanel;
    cxLabel2: TcxLabel;
    Btn_Descompactar: TGPanel;
    cxLabel3: TcxLabel;
    Btn_GoogleDrive: TGPanel;
    Image2: TImage;
    cxLabel8: TcxLabel;
    Btn_Enviar: TGPanel;
    cxLabel4: TcxLabel;
    Btn_Listar: TGPanel;
    cxLabel9: TcxLabel;
    Btn_FecharSubMenu: TGPanel;
    cxLabel10: TcxLabel;
    procedure FormShow(Sender: TObject);
    procedure Btn_BackupClick(Sender: TObject);
    procedure Btn_RestoreClick(Sender: TObject);
    procedure Btn_CompactarClick(Sender: TObject);
    procedure Btn_DescompactarClick(Sender: TObject);
    procedure AplicaRemoveEfeitoBotao(Sender: TObject);
    procedure Btn_EnviarClick(Sender: TObject);
    procedure SelecionaMenu(Sender: TObject);
    procedure Btn_FecharSubMenuClick(Sender: TObject);
    procedure Btn_ListarClick(Sender: TObject);
  private
    FBancoDados: TBancoDados;
    FZip: TZip;
    FUsuario,
    FSenha: String;
    FGoogleDrive: TGoogleDrive;
    procedure Aguardar;

    const
      InputBoxMessage = WM_USER + 200;

      GOOGLE_DRIVE_CLIENT_ID = '584267529480-pibkdgbm0bkkej9pu66cugk81kqc27b1.apps.googleusercontent.com';
      GOOGLE_DRIVE_CLIENT_SECRET = 'n3v_iZcxzriY0Dn02EwErknQ';
      GOOGLE_DRIVE_SCOPE = 'https://www.googleapis.com/auth/drive';

    procedure LimparLog;
    function SelecionaDiretorio: String;
    procedure MostraMensagem(AMensagem: String);
    procedure QuandoIniciar(ATipo: uBancoDados.TTipoExecucao);
    procedure QuandoFinalizar(ATipo: uBancoDados.TTipoExecucao;
      ADiretorioCompletoArquivo: String);
    function Substituir(AMensagem: String): Boolean;
    procedure ProgressoZip(Sender: TObject; Progress: Byte; var Abort: Boolean);
    procedure AlteraFundo(Sender: TGPanel);
    procedure AlteraCursor(Sender: TGPanel);
    function CarregaUsuario: String;
    function CarregaSenha: String;
    procedure CarregaInformacoes;
    procedure BloqueiaBotoes;
    procedure InputBoxSetPasswordChar(var Msg: TMessage); message InputBoxMessage;
    procedure EscondeSubMenu;
    procedure MostraSubMenu(AMenuSelecionado: Integer);
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

uses
  StrUtils, ShellAPI,
  uCEFApplicationCore, Generics.Collections;

{$R *.dfm}

procedure TFrmPrincipal.InputBoxSetPasswordChar(var Msg: TMessage);
var
   hInputForm,
   hEdit,
   hButton: HWND;
begin
   hInputForm := Screen.Forms[0].Handle;
   if (hInputForm <> 0) then
   begin
     hEdit := FindWindowEx(hInputForm, 0, 'TEdit', nil);
     SendMessage(hEdit, EM_SETPASSWORDCHAR, Ord('*'), 0);
   end;
end;

function TFrmPrincipal.SelecionaDiretorio: String;
begin
  if (FileOpenDialog.Execute) then
    Result := FileOpenDialog.FileName;
end;

function TFrmPrincipal.CarregaUsuario: String;
begin
  Result := InputBox('Usuário', 'Informe o usuário', '');
end;

function TFrmPrincipal.CarregaSenha: String;
begin
  PostMessage(Handle, InputBoxMessage, 0, 0);
  Result := InputBox('Senha', 'Informe a senha', '');
end;

procedure TFrmPrincipal.FormShow(Sender: TObject);
begin
  LimparLog;

  EscondeSubMenu;
end;

procedure TFrmPrincipal.Btn_BackupClick(Sender: TObject);
begin
  EscondeSubMenu;

  CarregaInformacoes;

  FBancoDados := TBancoDados.Create(FUsuario, FSenha, 'c:\syscomp\');
  FBancoDados.DiretorioCompletoArquivo := SelecionaDiretorio;
  FBancoDados.QuandoFalhar := MostraMensagem;
  FBancoDados.QuandoIniciar := QuandoIniciar;
  FBancoDados.QuandoTerminar := QuandoFinalizar;
  FBancoDados.QuandoSubstituir := Substituir;
  FBancoDados.Backup;
end;

procedure TFrmPrincipal.Btn_RestoreClick(Sender: TObject);
begin
  EscondeSubMenu;

  CarregaInformacoes;

  FBancoDados := TBancoDados.Create(FUsuario, FSenha, 'c:\syscomp\');
  FBancoDados.DiretorioCompletoArquivo := SelecionaDiretorio;
  FBancoDados.QuandoFalhar := MostraMensagem;
  FBancoDados.QuandoIniciar := QuandoIniciar;
  FBancoDados.QuandoTerminar := QuandoFinalizar;
  FBancoDados.QuandoSubstituir := Substituir;
  FBancoDados.Restore;
end;

procedure TFrmPrincipal.Btn_CompactarClick(Sender: TObject);
begin
  EscondeSubMenu;

  FZip := TZip.Create(SelecionaDiretorio);
  FZip.ProgressoArquivo := ProgressoZip;
  FZip.Compactar;
  FZip.Free;
end;

procedure TFrmPrincipal.Btn_DescompactarClick(Sender: TObject);
begin
  EscondeSubMenu;

  FZip := TZip.Create(SelecionaDiretorio);
  FZip.ProgressoArquivo := ProgressoZip;
  FZip.Descompactar;
  FZip.Free;
end;

procedure TFrmPrincipal.Btn_ListarClick(Sender: TObject);
var
  LArquivos: TList<TGoogleArquivo>;
  LArquivo: TGoogleArquivo;
begin
  EscondeSubMenu;

  if not(Assigned(FGoogleDrive)) then
  begin
    FGoogleDrive := TGoogleDrive.Create(GOOGLE_DRIVE_CLIENT_ID, GOOGLE_DRIVE_CLIENT_SECRET);
    FGoogleDrive.QuandoAguardar := Aguardar;
  end;

  LArquivos := FGoogleDrive.ListarArquivos;

  if not(Assigned(LArquivos)) then
    Exit;

  for LArquivo in LArquivos do
    memLog.Lines.Add(LArquivo.ToString);
end;

procedure TFrmPrincipal.Btn_EnviarClick(Sender: TObject);
begin
  EscondeSubMenu;

  if not(Assigned(FGoogleDrive)) then
  begin
    FGoogleDrive := TGoogleDrive.Create(GOOGLE_DRIVE_CLIENT_ID, GOOGLE_DRIVE_CLIENT_SECRET);
    FGoogleDrive.QuandoAguardar := Aguardar;
  end;

  FGoogleDrive.Enviar(SelecionaDiretorio, True);
end;

procedure TFrmPrincipal.LimparLog;
begin
  memLog.Lines.Clear;
end;

procedure TFrmPrincipal.MostraMensagem(AMensagem: String);
begin
  ShowMessage(AMensagem);
end;

procedure TFrmPrincipal.QuandoIniciar(ATipo: uBancoDados.TTipoExecucao);
begin
  memLog.Lines.Add(Format('Iniciando processo de %s...', [FBancoDados.NomeProcessoExecutar]));
end;

procedure TFrmPrincipal.QuandoFinalizar(ATipo: uBancoDados.TTipoExecucao;
  ADiretorioCompletoArquivo: String);
begin
  memLog.Lines.Add(Format('Processo finalizado de %s!', [FBancoDados.NomeProcessoExecutar]));
  memLog.Lines.Add(Concat('Arquivo: ', ADiretorioCompletoArquivo));

  FBancoDados.Free;
end;

function TFrmPrincipal.Substituir(AMensagem: String): Boolean;
var
  LMensagemCompleta: String;
begin
  LMensagemCompleta := Concat('Deseja substituir?',#13, AMensagem);

  Result := MessageDlg(LMensagemCompleta, TMsgDlgType.mtConfirmation, [mbYes, mbNo], 0) <> mrNone;

  memLog.Lines.Add(Concat(LMensagemCompleta, ' : ', IfThen(Result, 'Sim', 'Não')));
end;

procedure TFrmPrincipal.ProgressoZip(Sender: TObject; Progress: Byte; var Abort: Boolean);
begin
  memLog.Lines.Add(Chr(Progress));
end;

procedure TFrmPrincipal.Aguardar;
begin
  Application.ProcessMessages;
end;

procedure TFrmPrincipal.CarregaInformacoes;
begin
  if (FUsuario <> '') and (FSenha <> '') then
  begin
    if (MessageDlg('Deseja utilizar o usuário e senha anterior?', TMsgDlgType.mtConfirmation, [mbYes, mbNo], 0) <> mrNone) then
      Exit;
  end;

  FUsuario := CarregaUsuario;
  FSenha := CarregaSenha;
end;

procedure TFrmPrincipal.AplicaRemoveEfeitoBotao(Sender: TObject);
begin
  // aplica ou remove efeito de foco
  if (Sender is TGPanel) then
  begin
    AlteraFundo((Sender as TGPanel));
    AlteraCursor((Sender as TGPanel));
  end
  else if (Sender is TImage) then
  begin
    with (Sender as TImage) do
    begin
      AlteraFundo(((Sender as TImage).Parent as TGPanel));
      AlteraCursor(((Sender as TImage).Parent as TGPanel));
    end;
  end;
end;

procedure TFrmPrincipal.AlteraFundo(Sender: TGPanel);
begin
  if (Sender.BevelOuter = TBevelCut.bvRaised) then
  begin
    Sender.BevelOuter := TBevelCut.bvNone;
    Sender.Color := $00FFD9AA;
    Sender.Color_1 := $00FFD39D;
  end
  else
  begin
    Sender.BevelOuter := TBevelCut.bvRaised;
    Sender.Color := clWhite;
    Sender.Color_1 := clWhite;
  end;
end;

procedure TFrmPrincipal.AlteraCursor(Sender: TGPanel);
begin
  if ((Sender as TGPanel).BevelOuter = TBevelCut.bvRaised) then
    Screen.Cursor := crHandPoint
  else
    Screen.Cursor := crDefault;
end;

procedure TFrmPrincipal.BloqueiaBotoes;
begin
  Btn_Backup.Enabled := (Assigned(FBancoDados) and not(FBancoDados.EmExecucao)) or (Assigned(FZip) and not(FZip.EmExecucao));
  Btn_Restore.Enabled := Btn_Backup.Enabled;
  Btn_Compactar.Enabled := Btn_Backup.Enabled;
  Btn_Descompactar.Enabled := Btn_Backup.Enabled;
  Btn_Enviar.Enabled := Btn_Backup.Enabled;
end;

procedure TFrmPrincipal.Btn_FecharSubMenuClick(Sender: TObject);
begin
  EscondeSubMenu;
end;

procedure TFrmPrincipal.EscondeSubMenu;
var
  I: Integer;
begin
  Pn_SubMenu.Width := 0;

  for I := 0 to Pn_SubMenu.ControlCount - 1 do
  begin
    if (Pn_SubMenu.Controls[I] is TGPanel) and (Pn_SubMenu.Controls[I].Tag >= 0) then
      Pn_SubMenu.Controls[I].Visible := False;
  end;
end;

procedure TFrmPrincipal.MostraSubMenu(AMenuSelecionado: Integer);
var
  I: Integer;
begin
  Pn_SubMenu.Width := 145;

  for I := 0 to Pn_SubMenu.ControlCount - 1 do
  begin
    if (Pn_SubMenu.Controls[I] is TGPanel) and (Pn_SubMenu.Controls[I].Tag >= 0) then
      Pn_SubMenu.Controls[I].Visible := (Pn_SubMenu.Controls[I].Tag = AMenuSelecionado);
  end;
end;

procedure TFrmPrincipal.SelecionaMenu(Sender: TObject);
begin
  if not(Sender is TGPanel) then
    Exit;

  MostraSubMenu((Sender as TGPanel).Tag);
end;

end.
