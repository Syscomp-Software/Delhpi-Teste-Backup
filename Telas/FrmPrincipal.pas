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
  uBancoDados, uZip, GPanel;

type
  TForm1 = class(TForm)
    FileOpenDialog: TFileOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Ed_DiretorioCompleto: TEdit;
    Btn_Selecionar: TButton;
    Ed_Usuario: TEdit;
    Ed_Senha: TEdit;
    Btn_Backup_: TButton;
    Btn_Compactar: TButton;
    Btn_Restore: TButton;
    Btn_Descompactar: TButton;
    Btn_Enviar: TButton;
    Btn_Tudo: TButton;
    memLog: TMemo;
    Btn_Backup: TGPanel;
    lbTituloGoogle: TcxLabel;
    Image1: TImage;
    procedure FormShow(Sender: TObject);
    procedure Btn_SelecionarClick(Sender: TObject);
    procedure Btn_BackupClick(Sender: TObject);
    procedure Btn_RestoreClick(Sender: TObject);
    procedure Btn_CompactarClick(Sender: TObject);
    procedure Btn_DescompactarClick(Sender: TObject);
    procedure AplicaRemoveEfeitoBotao(Sender: TObject);
  private
    FBancoDados: TBancoDados;
    FZip: TZip;

    procedure LimparLog;
    procedure MostraMensagem(AMensagem: String);
    procedure QuandoIniciar(ATipo: uBancoDados.TTipoExecucao);
    procedure QuandoFinalizar(ATipo: uBancoDados.TTipoExecucao);
    function Substituir(AMensagem: String): Boolean;
    procedure ProgressoZip(Sender: TObject; Progress: Byte; var Abort: Boolean);
    procedure AlteraFundo(Sender: TGPanel);
    procedure AlteraCursor(Sender: TGPanel);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  StrUtils;

{$R *.dfm}

procedure TForm1.Btn_BackupClick(Sender: TObject);
begin
  LimparLog;

  FBancoDados := TBancoDados.Create(Ed_DiretorioCompleto.Text, Ed_Usuario.Text, Ed_Senha.Text);
  FBancoDados.QuandoFalhar := MostraMensagem;
  FBancoDados.QuandoIniciar := QuandoIniciar;
  FBancoDados.QuandoTerminar := QuandoFinalizar;
  FBancoDados.QuandoSubstituir := Substituir;
  FBancoDados.Backup;
  FBancoDados.Free;
end;

procedure TForm1.Btn_RestoreClick(Sender: TObject);
begin
  LimparLog;

  FBancoDados := TBancoDados.Create(Ed_DiretorioCompleto.Text, Ed_Usuario.Text, Ed_Senha.Text);
  FBancoDados.QuandoFalhar := MostraMensagem;
  FBancoDados.QuandoIniciar := QuandoIniciar;
  FBancoDados.QuandoTerminar := QuandoFinalizar;
  FBancoDados.QuandoSubstituir := Substituir;
  FBancoDados.Restore;
  FBancoDados.Free;
end;

procedure TForm1.Btn_CompactarClick(Sender: TObject);
begin
  LimparLog;

  FZip := TZip.Create(Ed_DiretorioCompleto.Text);
  FZip.ProgressoArquivo := ProgressoZip;
  FZip.Compactar;
  FZip.Free;
end;

procedure TForm1.Btn_DescompactarClick(Sender: TObject);
begin
  LimparLog;

  FZip := TZip.Create(Ed_DiretorioCompleto.Text);
  FZip.ProgressoArquivo := ProgressoZip;
  FZip.Descompactar;
  FZip.Free;
end;

procedure TForm1.Btn_SelecionarClick(Sender: TObject);
begin
  FileOpenDialog.DefaultFolder := Ed_DiretorioCompleto.Text;

  if (FileOpenDialog.Execute) then
    Ed_DiretorioCompleto.Text := FileOpenDialog.FileName;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  LimparLog;

  {$IFDEF TESTE}
    Ed_DiretorioCompleto.Text := 'D:\Gdb\ACOS-22-04-06_748.FDB';
    Ed_Usuario.Text := 'SYSDBA';
    Ed_Senha.Text := 'laranja';
  {$ENDIF}
end;

procedure TForm1.LimparLog;
begin
  memLog.Lines.Clear;
end;

procedure TForm1.MostraMensagem(AMensagem: String);
begin
  ShowMessage(AMensagem);
end;

procedure TForm1.QuandoIniciar(ATipo: uBancoDados.TTipoExecucao);
begin
  memLog.Lines.Add('Iniciando processo...');
end;

procedure TForm1.QuandoFinalizar(ATipo: uBancoDados.TTipoExecucao);
begin
  memLog.Lines.Add('Processo finalizado!');
end;

function TForm1.Substituir(AMensagem: String): Boolean;
var
  LMensagemCompleta: String;
begin
  LMensagemCompleta := Concat('Deseja substituir?',#13, AMensagem);

  Result := MessageDlg(LMensagemCompleta, TMsgDlgType.mtConfirmation, [mbYes, mbNo], 0) <> mrNone;

  memLog.Lines.Add(Concat(LMensagemCompleta, ' : ', IfThen(Result, 'Sim', 'Não')));
end;

procedure TForm1.ProgressoZip(Sender: TObject; Progress: Byte; var Abort: Boolean);
begin
  memLog.Lines.Add(Chr(Progress));

  Application.ProcessMessages;
end;

procedure TForm1.AplicaRemoveEfeitoBotao(Sender: TObject);
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
      if (Name = 'imgGoogle') then
      begin
//        AlteraFundo(btBackupServidorGoogle);
//        AlteraCursor(btBackupServidorGoogle);
        Exit;
      end;

//      AlteraFundo(btBackupServidorLocal);
//      AlteraCursor(btBackupServidorLocal);
    end;
  end;
end;

procedure TForm1.AlteraFundo(Sender: TGPanel);
begin
  with Sender do
  begin
    BevelOuter := IfThen((BevelOuter = TBevelCut.bvRaised), TBevelCut.bvNone, TBevelCut.bvRaised);
    Color := IfThen((BevelOuter = TBevelCut.bvRaised), $00F9F0E6, clWhite);
    Color_1 := IfThen((BevelOuter = TBevelCut.bvRaised), $00F9F0E6, clWhite);
  end;
end;

procedure TForm1.AlteraCursor(Sender: TGPanel);
begin
  Screen.Cursor := IfThen(((Sender as TGPanel).BevelOuter = TBevelCut.bvRaised), crHandPoint, crDefault);
end;


end.
