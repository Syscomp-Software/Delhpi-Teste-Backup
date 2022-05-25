unit uAuthGoogle;

interface

uses
  IdHTTPServer, IdContext,
  IdHTTP, IdSSLOpenSSL,
  IdCustomHTTPServer, IdComponent,
  IdURI, SysUtils,
  ExtCtrls;

type
  TTipoExecucao = (TLogin, TRefresh);

  TStatus = (TInativo, TSucesso, TFalha);
  
  TQuandoResponderEvento = procedure(AStatus: TStatus; AMensagem: String) of object;
  TQuandoIniciarEvento = procedure(ATipoExecucao: TTipoExecucao) of object;
  TQuandoFinalizarEvento = procedure(ATipoExecucao: TTipoExecucao) of object;

  TOAuthGoogle = class
  private
    FEnderecoRedirecionar,
    FEndereco: String;
    FPorta: Integer;
    FUrlAutenticacao,
    FUrlToken,
    FClientID,
    FClientSecret,
    FScope,
    FAuthCode,
    FAccessToken,
    FRefreshToken,
    FTokenType,
    FError,
    FErrorDescription: String;
    FExpiresIn: Integer;
    FTemAcesso: Boolean;
    FHttpServidor: TIdHTTPServer;
    FHttpCliente: TIdHttp;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FTipoExecucao: TTipoExecucao;        
    FQuandoResponderEvento: TQuandoResponderEvento;    
    FQuandoIniciarEvento: TQuandoIniciarEvento;
    FQuandoFinalizarEvento: TQuandoFinalizarEvento;
    FStatus: TStatus;
    FCronometro: TTimer;
    const
      ENDERECO_PADRAO = '127.0.0.1';
      PORTA_PADRAO = 50000;

      GOOGLE_DISCOVERY_DOCUMENT = 'https://accounts.google.com/.well-known/openid-configuration';

      URL_AUTENTICACAO = 'https://accounts.google.com/o/oauth2/v2/auth';
      URL_TOKEN = 'https://oauth2.googleapis.com/token';
      URL_INFOMACOES_USUARIO = 'https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=%s';

      TEMPLATE_BASE_INICIO = '<!DOCTYPE html><html lang="pt-br"><head> <meta charset="utf-8"/> <meta name="viewport" content="width=device-width, initial-scale=1"> ' +
      '<style>body{margin: 0;}.fundo{background-image: url("https://firebasestorage.googleapis.com/v0/b/syscomp-772de.appspot.com/o/Logos%2F251120304_597635661663498_3092476086018446813_n_1.png?alt=media"); ' +
      'background-repeat: no-repeat; background-position: center center; width: 100%; height: 1000px; position: relative;}.overlay{position: absolute; width: 100%; height: 100%;} ' +
      '.sombra{position: absolute; width: 100%; height: 100%; background: rgb(247 247 247 / 65%);}.texto-padrao{color: rgb(55, 118, 223); text-align: center; position: absolute; left: 50%; transform: translate(-50%, -50%);} ' +
      '.t-2{top: 20%;}.t-3{top: 30%;}.t-35{top: 35%;}.check{position: absolute; left: 50%; transform: translate(-50%, -50%);}</style></head><body> <div class="fundo"> <div class="sombra"> ' +
      '</div><div class="overlay">  ';

      TEMPLATE_BASE_FIM = '</div></div></body></html> ';

      TEPLATE_ICONE_SUCESSO = '<img src="https://img.icons8.com/emoji/96/000000/check-mark-emoji.png" class="check t-2"/>';

      TEMPLATE_PADRAO_SUCESSO = Concat(TEMPLATE_BASE_INICIO, TEPLATE_ICONE_SUCESSO, '<h1 class="texto-padrao t-3">Autenticação realizada com sucesso</h1> <h4 class="texto-padrao t-35">Você pode fechar a janela!</h4>', TEMPLATE_BASE_FIM);

      TEMPLATE_PADRAO_ERRO = Concat(TEMPLATE_BASE_INICIO, '<h1 class="texto-padrao t-3">Oops, não conseguimos autenticar!</h1> <h4 class="texto-padrao t-35">Tente novamente!</h4>', TEMPLATE_BASE_FIM);

      PARAMETROS_AUTENTICAR = '%s?response_type=code&client_id=%s&redirect_uri=%s&scope=%s&%s';
      PARAMETROS_TROCA_TOKEN = 'grant_type=authorization_code&code=%s&client_id=%s&client_secret=%s&redirect_uri=%s';      
      PARAMETROS_ATUALIZACAO_TOKEN = 'grant_type=refresh_token&client_id=%s&client_secret=%s&refresh_token=%s';      

    procedure ExecutaEventoResposta(AStatus: TStatus; AMensagem: String);
    procedure ExecutaEventoIniciar;
    procedure ExecutaEventoFinalizar;
    procedure ExecutaEventoCronometro(Sender: TObject);

    procedure IniciaServidor;
    procedure FinalizaServidor;

    function BuscaUrlPadrao: String;
    function BuscaUrlAutenticacao: String;
    function BuscaUrlAutenticarCodigo: String;
    function BuscaParametrosAtualizar: String;
    function BuscaCodigoRespostaPorUrl(const AUrl: String): Boolean;
    function BuscaParametrosTrocaToken: String;

    procedure InterpretaUrl(const AUrl: String);

    function _TemToken: Boolean;
    function _TokenValido: Boolean;
    procedure _QuandoResponder(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

    procedure Autorizar;
    procedure TemAcesso;
    procedure AtualizaToken;

    procedure Inicializar;
  public
    constructor Create;
    destructor Destroy; override;

    property EnderecoRedirecionar: String read FEnderecoRedirecionar;
    property Porta: Integer read FPorta write FPorta;

    property UrlAutenticacao: String read FUrlAutenticacao write FUrlAutenticacao;
    property UrlToken: String read FUrlToken write FUrlToken;

    property ClientID: String read FClientID write FClientID;
    property ClientSecret: String read FClientSecret write FClientSecret;
    property Scope: String read FScope write FScope;

    property AccessToken: String read FAccessToken write FAccessToken;
    property RefreshToken: String read FRefreshToken write FRefreshToken;
    property ExpiresIn: Integer read FExpiresIn;
    property TokenType: String read FTokenType;

    property QuandoResponder: TQuandoResponderEvento read FQuandoResponderEvento write FQuandoResponderEvento;
    property QuandoIniciar: TQuandoIniciarEvento read FQuandoIniciarEvento write FQuandoIniciarEvento;
    property QuandoFinalizar: TQuandoFinalizarEvento read FQuandoFinalizarEvento write FQuandoFinalizarEvento;

    property UrlRedirecionar: String read FEnderecoRedirecionar;
    property UrlAutenticarCodigo: String read BuscaUrlAutenticarCodigo;

    property TemToken: Boolean read _TemToken;
    property TokenValido: Boolean read _TokenValido;

    property Status: TStatus read FStatus;

    procedure Login;
    procedure Refresh;    
  end;

implementation

uses
  ShellAPI, Windows,
  StrUtils, Classes,
  uLkJSON;

{ TOAuthGoogle }

function TOAuthGoogle.BuscaUrlPadrao: String;
begin
  Result := Concat('http://', FEndereco, ':', IntToStr(FPorta));
end;

function TOAuthGoogle.BuscaUrlAutenticacao: String;
begin
  Result := Concat(BuscaUrlPadrao, '/Autenticacao');
end;

function TOAuthGoogle.BuscaUrlAutenticarCodigo: String;
var
  LUltimoParametro: String;
begin
  LUltimoParametro := IfThen(FTemAcesso, 'access_type=offline', 'prompt=consent&access_type=offline');
    
  Result := Format(PARAMETROS_AUTENTICAR, [FUrlAutenticacao, FClientID, UrlRedirecionar, FScope, LUltimoParametro]);
end;

function TOAuthGoogle.BuscaParametrosAtualizar: String;
begin
  Result := Format(PARAMETROS_ATUALIZACAO_TOKEN, [FClientID, FClientSecret, FRefreshToken]);
end;

function TOAuthGoogle.BuscaParametrosTrocaToken: String;
begin
  Result := Format(PARAMETROS_TROCA_TOKEN, [FAuthCode, FClientID, FClientSecret, FEnderecoRedirecionar]);
end;

procedure TOAuthGoogle.InterpretaUrl(const AUrl: String);
var
  I: Integer;
  LChave,
  LValor: String;
begin
  I := Pos('=', AUrl);

  if (I < 0) then
    Exit;

  LChave := Copy(AUrl, 1, Pred(I));
  LValor := Copy(AUrl, Succ(I), Length(AUrl));

  case AnsiIndexText(LChave, ['code', 'state', 'error', 'error_description']) of
    0: FAuthCode := LValor;
//    1: FIncState := LValor;
    2: FError := LValor;
    4: FErrorDescription := LValor;
  end;
end;

function TOAuthGoogle.BuscaCodigoRespostaPorUrl(const AUrl: String): Boolean;
var
  LUrl: String;
  I: Integer;
begin
  Result := False;

  if (Length(AUrl) > 0) then
  begin
    LUrl := AUrl;

    I := Pos('&', LUrl);

    while (I > 0) do
    begin
      InterpretaUrl(Copy(LUrl, 1, Pred(I)));
      LUrl := Copy(LUrl, Succ(I), Length(LUrl));
      I := Pos('&', LUrl);
    end;

    InterpretaUrl(LUrl);

    Result := (Length(FAuthCode) > 0);
  end;
end;

constructor TOAuthGoogle.Create;
begin
  inherited Create;

  Inicializar;
end;

destructor TOAuthGoogle.Destroy;
begin
  FinalizaServidor;

  FHttpServidor.Free;
  FHttpCliente.Free;

  inherited;
end;

procedure TOAuthGoogle.ExecutaEventoResposta(AStatus: TStatus; AMensagem: String);
begin
  FStatus := AStatus;

  if not(Assigned(FQuandoResponderEvento)) then
    Exit;

  FQuandoResponderEvento(AStatus, AMensagem);
end;

procedure TOAuthGoogle.ExecutaEventoIniciar;
begin
  FStatus := TStatus.TInativo;

  if not(Assigned(FQuandoIniciarEvento)) then
    Exit;
  
  FQuandoIniciarEvento(FTipoExecucao);
end;

procedure TOAuthGoogle.ExecutaEventoFinalizar;
begin
  if not(Assigned(FQuandoFinalizarEvento)) then
    Exit;

  FQuandoFinalizarEvento(FTipoExecucao);
end;

procedure TOAuthGoogle.ExecutaEventoCronometro(Sender: TObject);
begin
  (Sender as TTimer).Enabled := False;

  ExecutaEventoResposta(TStatus.TFalha, 'Oops, tempo limite excedido!');
end;

procedure TOAuthGoogle.Inicializar;
begin
  FEndereco := ENDERECO_PADRAO;
  FPorta := PORTA_PADRAO;

  FEnderecoRedirecionar := BuscaUrlAutenticacao;

  FUrlAutenticacao := URL_AUTENTICACAO;
  FUrlToken := URL_TOKEN;
  FClientID := '';
  FClientSecret := '';
  FAuthCode := '';
  FScope := 'openid';
  FAccessToken := '';
  FRefreshToken := '';

  FTemAcesso := False;
  FStatus := TStatus.TInativo;

  FCronometro := TTimer.Create(nil);
  FCronometro.Enabled := False;
  FCronometro.Interval := 180000;
  FCronometro.OnTimer := ExecutaEventoCronometro;

  FHttpServidor := TIdHTTPServer.Create(nil);
  FHttpServidor.OnCommandGet := _QuandoResponder;

  FHttpCliente := TIdHTTP.Create(nil);
  FHttpCliente.HTTPOptions := [hoKeepOrigProtocol, hoForceEncodeParams];
  FHttpCliente.Request.Accept := 'application/json';
  FHttpCliente.Request.ContentType := 'application/x-www-form-urlencoded';

  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(FHttpCliente);  
  FHttpCliente.IOHandler := FSSL;

  LoadOpenSSLLibrary;
end;

procedure TOAuthGoogle.IniciaServidor;
begin
  if (FHttpServidor.Active) then
    FHttpServidor.Active := False;

  FHttpServidor.DefaultPort := FPorta;

  FHttpServidor.Active := True;
end;

procedure TOAuthGoogle.FinalizaServidor;
begin
  if (FHttpServidor.Active) then  
    FHttpServidor.Active := False;
end;

function TOAuthGoogle._TemToken: Boolean;
begin
  Result := (Trim(FAccessToken) <> '');
end;

function TOAuthGoogle._TokenValido: Boolean;
begin
  TemAcesso;

  Result := (FExpiresIn > 0);
end;

procedure TOAuthGoogle.TemAcesso;
var
  LResposta: String;
  LRespostaJson: TlkJSONobject;  
begin
  if not(TemToken) then
    Exit;

  LRespostaJson := nil;

  try
    try
      LResposta := FHttpCliente.Get(Format(URL_INFOMACOES_USUARIO, [FAccessToken]));

      LRespostaJson := TlkJSON.ParseText(LResposta) as TlkJSONobject;

      FTemAcesso := (LRespostaJson.IndexOfName('scope') >= 0) and (LRespostaJson.getString('scope') = FScope);

      if (LRespostaJson.IndexOfName('expires_in') >= 0) then
        FExpiresIn := LRespostaJson.getInt('expires_in');
    except on E: Exception do
      begin
        FExpiresIn := 0;
        ExecutaEventoResposta(TStatus.TFalha, 'Oops, token inválido!');
      end;
    end;
  finally
    if (Assigned(LRespostaJson)) then
      LRespostaJson.Free;
  end;    
end;

procedure TOAuthGoogle.Autorizar;
var
  LParametro,
  LResposta: TStringStream;
  LRespostaJson: TlkJSONobject;
begin
  LParametro := TStringStream.Create;
  LResposta := TStringStream.Create;
  try
    try           
      FHttpCliente.Post(Concat(FUrlToken, '?', BuscaParametrosTrocaToken), LParametro, LResposta);

      LRespostaJson := TlkJSON.ParseText(LResposta.DataString) as TlkJSONobject;

      if not(Assigned(LRespostaJson)) then
      begin
        ExecutaEventoResposta(TStatus.TFalha, 'Oops, não conseguimos autorizar!');
        Exit;
      end;

      FAccessToken := LRespostaJson.getString('access_token');
      FRefreshToken := LRespostaJson.getString('refresh_token');
      FExpiresIn := LRespostaJson.getInt('expires_in');
      FTokenType := LRespostaJson.getString('token_type');      

      ExecutaEventoFinalizar;      
    except on E: Exception do
      ExecutaEventoResposta(TStatus.TFalha, 'Oops, não conseguimos autorizar!');
    end;    
  finally
    LParametro.Free;
    LResposta.Free;    
    LRespostaJson.Free;    
  end;
end;

procedure TOAuthGoogle.AtualizaToken;
var
  LParametro,
  LResposta: TStringStream;
  LRespostaJson: TlkJSONobject;  
begin
  LParametro := TStringStream.Create;
  LResposta := TStringStream.Create;
  
  try
    try
      FHttpCliente.Post(Concat(FUrlToken, '?', BuscaParametrosAtualizar), LParametro, LResposta);

      LRespostaJson := TlkJSON.ParseText(LResposta.DataString) as TlkJSONobject;    

      if not(Assigned(LRespostaJson)) then
      begin
        ExecutaEventoResposta(TStatus.TFalha, 'Oops, não conseguimos atualizar seu token!');
        Exit;
      end;

      FAccessToken := LRespostaJson.getString('access_token');
      FExpiresIn := LRespostaJson.getInt('expires_in');
      FTokenType := LRespostaJson.getString('token_type');

      ExecutaEventoFinalizar;
    except on E: Exception do
      ExecutaEventoResposta(TStatus.TFalha, 'Oops, não conseguimos atualizar seu token!');
    end;      
  finally
    LParametro.Free;
    LResposta.Free;
    LRespostaJson.Free;
  end;
end;

procedure TOAuthGoogle._QuandoResponder(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  FCronometro.Enabled := False;

  AResponseInfo.ContentType := 'text/html';
  
  if (ARequestInfo.URI = '/Autenticacao') or ContainsText('favicon', ARequestInfo.URI) then
  begin
    // sucesso
    AResponseInfo.ResponseNo := 200;
    AResponseInfo.ContentText := TEMPLATE_PADRAO_SUCESSO;
    
    BuscaCodigoRespostaPorUrl(TIdURI.URLDecode(ARequestInfo.UnparsedParams));
    
    Autorizar;

    ExecutaEventoResposta(TStatus.TSucesso, 'Sucesso, atenticação realizada!');
  end
  else
  begin
    // erro
    AResponseInfo.ResponseNo := 401;
    AResponseInfo.ContentText := TEMPLATE_PADRAO_ERRO;
    
    ExecutaEventoResposta(TStatus.TFalha, 'Oops, não conseguimos realizar sua autenticação!');
  end;

  ExecutaEventoResposta(TStatus.TFalha, 'Oops, erro inesperado!');
end;

procedure TOAuthGoogle.Login;
begin
  FTipoExecucao := TTipoExecucao.TLogin;
  
  try
    IniciaServidor;

    ExecutaEventoIniciar;

    FCronometro.Enabled := True;

    ShellExecute(0, 'open', PWideChar(BuscaUrlAutenticarCodigo), nil, nil, SW_SHOWNORMAL);
  except on E: Exception do
    ExecutaEventoResposta(TStatus.TFalha, 'Oops, Não conseguimos realizar o login!');
  end;
end;

procedure TOAuthGoogle.Refresh;
begin
  FTipoExecucao := TTipoExecucao.TRefresh;
  
  try
    if not(TemToken) then
    begin
      ExecutaEventoResposta(TStatus.TFalha, 'Necessário informar um "Access Token" e "Refresh Token" para atualizar!');
      Exit;
    end;
      
    IniciaServidor;

    ExecutaEventoIniciar;

    AtualizaToken;
  except on E: Exception do
    ExecutaEventoResposta(TStatus.TFalha, 'Oops, não conseguimos atualizar o acesso!');
  end;
end;

end.
