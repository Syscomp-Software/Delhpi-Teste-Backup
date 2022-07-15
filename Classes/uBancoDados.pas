unit uBancoDados;

interface

uses
  Generics.Collections, SysUtils,
  Classes;

type
  TTipoExecucao = (TBackup, TRestore);

  TQuandoFalharEvento = procedure(AMensagem: String) of object;
  TQuandoIniciarEvento = procedure(ATipoExecucao: TTipoExecucao) of object;
  TQuandoTerminarEvento = procedure(ATipoExecucao: TTipoExecucao;
    AMensagem: String) of object;
  TQuandoSubstituirEvento = function(AMensagem: String): Boolean of object;

  TBancoDados = class
  private
    FDiretorioCompletoArquivo,
    FUsuario,
    FSenha,
    FDiretorioBackup,
    FDiretorioRestore,
    FDiretorioFerramentas,
    FDiretorioLog: String;
    FQuandoFalhar: TQuandoFalharEvento;
    FQuandoTerminar: TQuandoTerminarEvento;
    FQuandoIniciar: TQuandoIniciarEvento;
    FFuncaoSubstituir: TQuandoSubstituirEvento;
    FTipoExecucao: TTipoExecucao;
    FExecutando: Boolean;
    FComando: String;

    type
      TThreadComando = class(TThread)
        private
          FComando: String;
          FFuncaoFalha: TProc<String>;
          FFuncaoSucesso: TProc;
        public
          procedure Execute; override;
          constructor Create(AComando: String;
            AFuncaoFalha: TQuandoFalharEvento; AFuncaoSucesso: TProc);
      end;

    const
      EXTENSAO_EXECUTAVEL = '.exe';
      EXTENSAO_LOG = '.log';
      EXTENSAO_BACKUP = '.FBK';
      EXTENSAO_RESTORE = '.FDB';

      NOME_FERRAMENTA_BACKUP = 'gbak';

      PARAMETROS_PADRAO = '"%s" "%s" -user %s -pas %s -y "%s"';
      PARAMETROS_BACKUP = Concat('-b ', PARAMETROS_PADRAO);
      PARAMETROS_RESTORE = Concat('-rep ', PARAMETROS_PADRAO);

      COMANDO_BACKUP = Concat('\', NOME_FERRAMENTA_BACKUP, EXTENSAO_EXECUTAVEL, '" ', PARAMETROS_BACKUP);
      COMANDO_RESTORE = Concat('\', NOME_FERRAMENTA_BACKUP, EXTENSAO_EXECUTAVEL, '" ', PARAMETROS_RESTORE);

      NOME_BACKUP = 'Backup';
      NOME_RESTORE = 'Restore';

      DIRETORIO_FERRAMENTAS = '%s\Ferramentas';
      DIRETORIO_LOG = '%s\Log';
      DIRETORIO_BACKUP = Concat('%s\', NOME_BACKUP);
      DIRETORIO_RESTORE = Concat('%s\', NOME_RESTORE);

    procedure ExecutaFuncaoFalha(AMensagem: String);
    procedure ExecutaFuncaoIniciar(ATipoExecucao: TTipoExecucao);
    procedure ExecutaFuncaoTerminar(ATipoExecucao: TTipoExecucao;
      ADiretorioArquivoCompleto: String);
    procedure CriaDiretorio(const ADiretorio: String);
    procedure DeletaArquivo(const ADiretorioCompleto: String);
    procedure Executar;

    function ExecutaFuncaoSubstituir(AMensagem: String): Boolean;
    function Validar: Boolean;
    function BuscaComandoPorTipo: String;
    function PreparaComando(const AComando, ANomeArquivo: String): String;
    function BuscaDiretorioExecucaoPorTipo: String;
    function BuscaDiretorioLogPorTipo: String;
    function BuscaExtensaoExecucaoPorTipo: String;
    function ExisteArquivoExecucao(const ANomeArquivo: String): Boolean;
    function MontaNomeArquivo: String;
    function MontaDiretorioLogcompleto(const ANomeArquivo: String): String;
    function MontaDiretorioArquivoExecucaoPorTipo(const ANomeArquivo: String): String;
    function ValidaLog(const ADiretorioLogCompleto: String): Boolean;
    function BuscaNomeExecutar: String;
  public
    constructor Create(const AUsuario, ASenha: String; ADiretorioGravar: String = '');

    property DiretorioCompletoArquivo: String read FDiretorioCompletoArquivo write FDiretorioCompletoArquivo;
    property QuandoFalhar: TQuandoFalharEvento read FQuandoFalhar write FQuandoFalhar;
    property QuandoIniciar: TQuandoIniciarEvento read FQuandoIniciar write FQuandoIniciar;
    property QuandoTerminar: TQuandoTerminarEvento read FQuandoTerminar write FQuandoTerminar;
    property QuandoSubstituir: TQuandoSubstituirEvento read FFuncaoSubstituir write FFuncaoSubstituir;
    property NomeProcessoExecutar: String read BuscaNomeExecutar;
    property EmExecucao: Boolean read FExecutando;
    property Comando: String read FComando;

    procedure Backup;
    procedure Restore;
  end;

implementation

uses
  StrUtils, Windows,
  TypInfo;

{ uBancoDados }

constructor TBancoDados.Create(const AUsuario, ASenha: String;
  ADiretorioGravar: String);
var
  LDiretorioAtual: String;
begin
  inherited Create;

  ADiretorioGravar := Trim(ADiretorioGravar);

  // quando houver diretório personalizado
  if (ADiretorioGravar <> EmptyStr) then
    LDiretorioAtual := IfThen(Copy(ADiretorioGravar, Length(ADiretorioGravar), 1) = '\', Copy(ADiretorioGravar, 1, Length(ADiretorioGravar) -1), ADiretorioGravar)
  else
    LDiretorioAtual := ExtractFileDir(ParamStr(0));

  FUsuario := AUsuario;
  FSenha := ASenha;

  FDiretorioFerramentas := Format(DIRETORIO_FERRAMENTAS, [LDiretorioAtual]);
  FDiretorioLog := Format(DIRETORIO_LOG, [LDiretorioAtual]);

  FDiretorioBackup := Format(DIRETORIO_BACKUP, [LDiretorioAtual]);
  FDiretorioRestore := Format(DIRETORIO_RESTORE, [LDiretorioAtual]);
end;

procedure TBancoDados.ExecutaFuncaoFalha(AMensagem: String);
begin
  if (Assigned(FQuandoFalhar)) then
    FQuandoFalhar(AMensagem);

  FExecutando := False;
end;

procedure TBancoDados.ExecutaFuncaoIniciar(ATipoExecucao: TTipoExecucao);
begin
  if (Assigned(FQuandoIniciar)) then
    FQuandoIniciar(ATipoExecucao);

  FExecutando := True;
end;

procedure TBancoDados.ExecutaFuncaoTerminar(ATipoExecucao: TTipoExecucao;
  ADiretorioArquivoCompleto: String);
begin
  if (Assigned(FQuandoTerminar)) then
    FQuandoTerminar(ATipoExecucao, ADiretorioArquivoCompleto);

  FExecutando := False;
end;

function TBancoDados.ExecutaFuncaoSubstituir(AMensagem: String): Boolean;
begin
  Result := True;

  if (Assigned(FFuncaoSubstituir)) then
    Result := FFuncaoSubstituir(AMensagem);
end;

function TBancoDados.Validar: Boolean;
begin
  Result := False;

  if not(DirectoryExists(FDiretorioFerramentas)) then
  begin
    ExecutaFuncaoFalha('Diretório das ferramentas não existe!');
    Exit;
  end;

  if not(FileExists(Concat(FDiretorioFerramentas, '\', NOME_FERRAMENTA_BACKUP, EXTENSAO_EXECUTAVEL))) then
  begin
    ExecutaFuncaoFalha('Ferramenta de backup não existe!');
    Exit;
  end;

  if not(FileExists(Concat(FDiretorioFerramentas, '\fbclient.dll'))) then
  begin
    ExecutaFuncaoFalha('fbclient.dll não existe');
    Exit;
  end;

  if not(FileExists(FDiretorioCompletoArquivo)) then
  begin
    ExecutaFuncaoFalha(Concat('Banco de dados: ', FDiretorioCompletoArquivo, ' não existe!'));
    Exit;
  end;

  if ((FTipoExecucao = TTipoExecucao.TBackup) and (UpperCase(ExtractFileExt(FDiretorioCompletoArquivo)) <> EXTENSAO_RESTORE)) then
  begin
    ExecutaFuncaoFalha(Concat(FDiretorioCompletoArquivo, ' não é um arquivo válido para backup!'));
    Exit;
  end;

  if ((FTipoExecucao = TTipoExecucao.TRestore) and (UpperCase(ExtractFileExt(FDiretorioCompletoArquivo)) <> EXTENSAO_BACKUP)) then
  begin
    ExecutaFuncaoFalha(Concat(FDiretorioCompletoArquivo, ' não é um arquivo válido para restore!'));
    Exit;
  end;

  if (FUsuario = '') then
  begin
    ExecutaFuncaoFalha('Necessário informar um usuário');
    Exit;
  end;

  if (FSenha = '') then
  begin
    ExecutaFuncaoFalha('Necessário informar uma senha');
    Exit;
  end;

  Result := True;
end;

function TBancoDados.BuscaDiretorioExecucaoPorTipo: String;
begin
  Result := IfThen(FTipoExecucao = TTipoExecucao.TBackup, FDiretorioBackup, FDiretorioRestore);
end;

function TBancoDados.BuscaDiretorioLogPorTipo: String;
begin
  Result := IfThen(FTipoExecucao = TTipoExecucao.TBackup, NOME_BACKUP, NOME_RESTORE);
end;

function TBancoDados.BuscaExtensaoExecucaoPorTipo: String;
begin
  Result := IfThen(FTipoExecucao = TTipoExecucao.TBackup, EXTENSAO_BACKUP, EXTENSAO_RESTORE);
end;

function TBancoDados.BuscaComandoPorTipo: String;
begin
  Result := IfThen(FTipoExecucao = TTipoExecucao.TBackup, Concat('"', FDiretorioFerramentas, COMANDO_BACKUP), Concat('"', FDiretorioFerramentas, COMANDO_RESTORE));
end;

function TBancoDados.PreparaComando(const AComando, ANomeArquivo: String): String;
begin
  Result := Format(AComando, [FDiretorioCompletoArquivo, MontaDiretorioArquivoExecucaoPorTipo(ANomeArquivo), FUsuario, FSenha, MontaDiretorioLogcompleto(ANomeArquivo)]);
end;

procedure TBancoDados.CriaDiretorio(const ADiretorio: String);
begin
  if not(DirectoryExists(ADiretorio)) then
    ForceDirectories(ADiretorio);
end;

procedure TBancoDados.DeletaArquivo(const ADiretorioCompleto: String);
begin
  if not(FileExists(ADiretorioCompleto)) then
    Exit;

  DeleteFile(PWideChar(ADiretorioCompleto));
end;

function TBancoDados.ExisteArquivoExecucao(const ANomeArquivo: String): Boolean;
begin
  Result := FileExists(Concat(BuscaDiretorioExecucaoPorTipo, '\', ANomeArquivo, BuscaExtensaoExecucaoPorTipo));
end;

function TBancoDados.MontaNomeArquivo: String;
begin
  Result := ChangeFileExt(ExtractFileName(FDiretorioCompletoArquivo), '');
end;

function TBancoDados.MontaDiretorioLogcompleto(const ANomeArquivo: String): String;
var
  LDiretorio: String;
begin
  LDiretorio := Concat(FDiretorioLog, '\', BuscaDiretorioLogPorTipo, '\');

  CriaDiretorio(LDiretorio);

  Result := Concat(LDiretorio, ANomeArquivo, EXTENSAO_LOG);
end;

function TBancoDados.MontaDiretorioArquivoExecucaoPorTipo(const ANomeArquivo: String): String;
begin
  Result := Concat(BuscaDiretorioExecucaoPorTipo, '\', ANomeArquivo, BuscaExtensaoExecucaoPorTipo);
end;

function TBancoDados.ValidaLog(const ADiretorioLogCompleto: String): Boolean;
var
  LArquivoLog: TStringStream;
begin
  Result := True;

  // não gerou log
  if not(FileExists(ADiretorioLogCompleto)) then
    Exit;

  LArquivoLog := TStringStream.Create('', TEncoding.Default);
  try
    LArquivoLog.LoadFromFile(ADiretorioLogCompleto);

    if (Trim(LArquivoLog.DataString) <> '') then
    begin
      Result := False;
      Exit;
    end;
  finally
    LArquivoLog.Free;
  end;
end;

function TBancoDados.BuscaNomeExecutar: String;
begin
  Result := Copy(GetEnumName(TypeInfo(TTipoExecucao), Ord(FTipoExecucao)), 2);
end;

procedure TBancoDados.Executar();
var
  LNomeArquivo: String;
begin
  try
    if not(Validar) then
      Exit;

    CriaDiretorio(BuscaDiretorioExecucaoPorTipo);

    LNomeArquivo := MontaNomeArquivo;

    // se existir arquivo, pergunta se deseja substituir
    if (ExisteArquivoExecucao(LNomeArquivo)) then
    begin
      if (ExecutaFuncaoSubstituir(Concat(LNomeArquivo, BuscaExtensaoExecucaoPorTipo))) then
        DeletaArquivo(Concat(BuscaDiretorioExecucaoPorTipo, '\', LNomeArquivo, BuscaExtensaoExecucaoPorTipo))
      else
      begin
        ExecutaFuncaoFalha('Operação cancelada!');
        Exit;
      end;
    end;

    ExecutaFuncaoIniciar(FTipoExecucao);

    // cria comando
    FComando := PreparaComando(BuscaComandoPorTipo, LNomeArquivo);

    // executa comando
    TThreadComando.Create(FComando, ExecutaFuncaoFalha,
    procedure
    begin
      if not(ValidaLog(MontaDiretorioLogcompleto(LNomeArquivo))) then
      begin
        ExecutaFuncaoFalha(Format('%s executado com falha!#13Verifique.', [IfThen(FTipoExecucao = TTipoExecucao.TBackup, NOME_BACKUP, NOME_RESTORE)]));
        Exit;
      end;

      DeletaArquivo(MontaDiretorioLogcompleto(LNomeArquivo));

      ExecutaFuncaoTerminar(FTipoExecucao, MontaDiretorioArquivoExecucaoPorTipo(LNomeArquivo));
    end).Start;
  except on E: Exception do
    ExecutaFuncaoFalha(Concat('Oops, tivemos um problema#13', E.Message));
  end;
end;

procedure TBancoDados.Backup;
begin
  FTipoExecucao := TTipoExecucao.TBackup;
  Executar();
end;

procedure TBancoDados.Restore;
begin
  FTipoExecucao := TTipoExecucao.TRestore;
  Executar();
end;

{ TBancoDados.TThreadExecuta }

constructor TBancoDados.TThreadComando.Create(
  AComando: String; AFuncaoFalha: TQuandoFalharEvento; AFuncaoSucesso: TProc);
begin
  inherited Create(True);

  FreeOnTerminate := True;

  FComando := AComando;
  FFuncaoFalha := AFuncaoFalha;
  FFuncaoSucesso := AFuncaoSucesso;
end;

procedure TBancoDados.TThreadComando.Execute;
var
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
begin
  inherited;

  LStartupInfo := Default(TStartupInfo);
  LStartupInfo.cb := Sizeof(StartupInfo);
  LStartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  LStartupInfo.wShowWindow := SW_HIDE;

  try
    if not(CreateProcess(nil, PChar(FComando), nil, nil, False,
      CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, nil, LStartupInfo, LProcessInfo)) then
    begin
      TThread.Synchronize(nil,
      procedure
      begin
        FFuncaoFalha('Falha ao executar comando!');
        Exit;
      end);
    end;

    // aguarda execução
    WaitForSingleObject(LProcessInfo.hProcess, INFINITE);

    TThread.Synchronize(nil,
    procedure
    begin
      FFuncaoSucesso;
    end);
  finally
    CloseHandle(LProcessInfo.hProcess);
    CloseHandle(LProcessInfo.hThread);
  end;
end;

end.
