program TesteBackup;

uses
  Forms,
  uFrmPrincipal in '..\Telas\uFrmPrincipal.pas' {FrmPrincipal},
  uBancoDados in '..\Classes\uBancoDados.pas',
  uZip in '..\Classes\uZip.pas',
  uAuthGoogle in '..\Classes\uAuthGoogle.pas',
  uLkJSON in '..\Classes\uLkJSON.pas',
  uGoogleDrive in '..\Classes\uGoogleDrive.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmPrincipal, FrmPrincipal);
  Application.Run;
end.
