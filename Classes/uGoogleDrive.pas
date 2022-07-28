unit uGoogleDrive;

interface

uses
  uAuthGoogle, uLkJSON,
  IdHTTP, IdSSLOpenSSL,
  Generics.Collections, IdComponent,
  IdMultipartFormData, Classes;

type
  TGoogleArquivo = class(TObject)
  private
    FId,
    FTipo,
    FNome,
    FFormato: String;
  const
    IDENTIFICADOR_DIRETORIO = 'application/vnd.google-apps.folder';

    function _EhDiretorio: Boolean;

    procedure Inicializa(const AJsonElemento: TlkJSONobject);
  public
    constructor Create(const AJsonString: String); overload;
    constructor Create(const AJsonElemento: TlkJSONobject); overload;

    property Id: String read FId;
    property Nome: String read FNome;
    property Formato: String read FFormato;

    property EhDiretorio: Boolean read _EhDiretorio;

    function ToString: string; override;

    class function FromJsonArray(const AJsonArrayString: String): TList<TGoogleArquivo>;
  end;

  TStatus = (TInativo, TSucesso, TFalha, TExecutando);

  TQuandoAguardarEvento = procedure of object;
  TQuandoIniciar = procedure of object;
  TQuandoFinalizar = procedure(AStatus: TStatus) of object;

  TGoogleDrive = class
  protected
  type
    TTipoRequisicao = (TGet, TPost, TPatch, TDelete);
    TListaIds = array of string;
  private
    FOAuth: TOAuthGoogle;
    FHttpCliente: TIdHTTP;
    FSSL: TIdSSLIOHandlerSocketOpenSSL;
    FTemResposta: Boolean;
    FRespostaString: String;
    FFinalizouAutenticacao,
    FCancelar: Boolean;
    FQuandoAguardarEvento: TQuandoAguardarEvento;
    FQuandoIniciar: TQuandoIniciar;
    FQuandoFinalizar: TQuandoFinalizar;
    FStatus: TStatus;
  const
    IDENTIFICADOR_DIRETORIO = 'application/vnd.google-apps.folder';
    IDENTIFICADOR_ARQUIVO_NOME = 'name';
    IDENTIFICADOR_ARQUIVO_TIPO = 'mimeType';
    IDENTIFICADOR_ARQUIVO_PASTAS = 'parents';

    GOOGLE_DRIVE_SCOPE = 'https://www.googleapis.com/auth/drive';

    URL_GOOGLE_BASE = 'https://www.googleapis.com/';
    URL_GOOGLE_DRIVE_BASE = 'drive/';
    URL_GOOGLE_UPLOAD_BASE = 'upload/';
    URL_GOOGLE_VERSAO_BASE = 'v3/files';
    URL_GOOGLE_PERMISSAO_BASE = '/permissions';
    URL_GOOGLE_PERMISSAO_MENSAGEM_BASE = '?emailMessage=%s';

    URL_GOOGLE_UPLOAD_TIPO = '?uploadType=media';

    URL_GOOGLE_PADRAO = Concat(URL_GOOGLE_BASE, URL_GOOGLE_DRIVE_BASE, URL_GOOGLE_VERSAO_BASE);

    URL_GOOGLE_CRIA_ARQUIVO = Concat(URL_GOOGLE_PADRAO, '?alt=json');

    URL_GOOGLE_ATUALIZA_ARQUIVO = Concat(URL_GOOGLE_BASE, URL_GOOGLE_UPLOAD_BASE, URL_GOOGLE_DRIVE_BASE, URL_GOOGLE_VERSAO_BASE, '/%s', URL_GOOGLE_UPLOAD_TIPO);

    URL_GOOGLE_COMPARTILHAR = Concat(URL_GOOGLE_PADRAO, '/%s', URL_GOOGLE_PERMISSAO_BASE, URL_GOOGLE_PERMISSAO_MENSAGEM_BASE);

    URL_GOOGLE_LISTAR = Concat(URL_GOOGLE_PADRAO, '?pageSize=1000');

    procedure QuandoIniciarAutenticacao(ATipoExecucao: TTipoExecucao);
    procedure QuandoFinalizarAutenticacao(ATipoExecucao: TTipoExecucao);

    procedure ExecutaEventoIniciar;
    procedure ExecutaEventoFinalizar(AStatus: TStatus);
    procedure ExecutaEventoAguardar;

    procedure QuandoFinalizaRequisicao(ASender: TObject; AWorkMode: TWorkMode);
    procedure QuandoIniciaRequisicao(ASender: TObject; AWorkMode: TWorkMode; AWorkCountMax: Int64);

    procedure DefineAccessToken(const Value: String);
    procedure DefineQuandoIniciaLogin(const Value: TQuandoIniciarEvento);
    procedure DefineQuandoFinalizaLogin(const Value: TQuandoFinalizarEvento);

    function BuscaFormatoPorExtensao(const AExtensao: String): String;
    function BuscaElementosPorNome(const ANome: String): TList<TGoogleArquivo>;

    procedure ConfiguraRequisicao;
    procedure ExecutaRequisicao(const AUrl: String;
      ATipo: TTipoRequisicao; AParametro: TStream = nil);
    function CriaArquivoVazio(const ADiretorioCompleto: String;
      AIdsPastas: TListaIds): TGoogleArquivo;
    procedure CriaMidiaArquivo(const AIdArquivo, ADiretorioCompleto: String);
    procedure CriaArquivo(const ADiretorioCompleto: String;
      AIdsPastas: TListaIds);
    procedure AtualizaTipoArquivo(const AIdArquivo, ADiretorioCompleto: String);
  public
    constructor Create(const AClientId, AClientSecret: String);
    destructor Destroy; override;

    property AccessToken: String write DefineAccessToken;

    property QuandoAguardar: TQuandoAguardarEvento read FQuandoAguardarEvento write FQuandoAguardarEvento;
    property QuandoIniciarLogin: TQuandoIniciarEvento write DefineQuandoIniciaLogin;
    property QuandoFinalizarLogin: TQuandoFinalizarEvento write DefineQuandoFinalizaLogin;

    property QuandoIniciar: TQuandoIniciar read FQuandoIniciar write FQuandoIniciar;
    property QuandoFinalizar: TQuandoFinalizar read FQuandoFinalizar write FQuandoFinalizar;

    property Cancelar: Boolean read FCancelar write FCancelar;

    function ListarArquivos: TList<TGoogleArquivo>;

    procedure Enviar(const ADiretorioArquivoCompleto: String;
      ASubstituir: Boolean = False; AIdsPai: TListaIds = nil);
  end;

implementation

uses
  SysUtils, StrUtils,
  Variants, IdURI;

{ TGoogleDrive }

constructor TGoogleDrive.Create(const AClientId, AClientSecret: String);
begin
  inherited Create;

  FOAuth := TOAuthGoogle.Create;
  FOAuth.ClientID := AClientId;
  FOAuth.ClientSecret := AClientSecret;
  FOAuth.Scope := GOOGLE_DRIVE_SCOPE;
  FOAuth.QuandoIniciar := QuandoIniciarAutenticacao;
  FOAuth.QuandoFinalizar := QuandoFinalizarAutenticacao;

  FHttpCliente := TIdHTTP.Create(nil);
  FHttpCliente.HTTPOptions := [hoKeepOrigProtocol, hoForceEncodeParams];
  FHttpCliente.Request.Accept := 'application/json';
  FHttpCliente.Request.ContentType := 'application/json';
  FHttpCliente.OnWorkBegin := QuandoIniciaRequisicao;
  FHttpCliente.OnWorkEnd := QuandoFinalizaRequisicao;

  FSSL := TIdSSLIOHandlerSocketOpenSSL.Create(FHttpCliente);
  FHttpCliente.IOHandler := FSSL;

  LoadOpenSSLLibrary;

  FStatus := TStatus.TInativo;
end;

destructor TGoogleDrive.Destroy;
begin
  FOAuth.Free;

  FHttpCliente.Free;

  inherited;
end;

procedure TGoogleDrive.DefineAccessToken(const Value: String);
begin
  FOAuth.AccessToken := Value;
end;

procedure TGoogleDrive.DefineQuandoIniciaLogin(
  const Value: TQuandoIniciarEvento);
begin
  FOAuth.QuandoIniciar := Value;
end;

procedure TGoogleDrive.DefineQuandoFinalizaLogin(
  const Value: TQuandoFinalizarEvento);
begin
  FOAuth.QuandoFinalizar := Value;
end;

procedure TGoogleDrive.QuandoIniciarAutenticacao(ATipoExecucao: TTipoExecucao);
begin
  FFinalizouAutenticacao := False;
end;

procedure TGoogleDrive.QuandoFinalizarAutenticacao(ATipoExecucao: TTipoExecucao);
begin
  FFinalizouAutenticacao := True;
end;

procedure TGoogleDrive.QuandoIniciaRequisicao(ASender: TObject;
  AWorkMode: TWorkMode; AWorkCountMax: Int64);
begin
  FTemResposta := False;
  FRespostaString := '';
  FCancelar := False;
end;

procedure TGoogleDrive.QuandoFinalizaRequisicao(ASender: TObject;
  AWorkMode: TWorkMode);
var
  LResposta: TStringStream;
  LA: String;
begin
  FTemResposta := (Assigned((ASender as TIdHTTP).Response.ContentStream) and ((ASender as TIdHTTP).ResponseCode < 203));

  if not(FTemResposta) then
    Exit;

  LResposta := TStringStream.Create;
  try
    LResposta.LoadFromStream(FHttpCliente.Response.ContentStream);
    FRespostaString := LResposta.DataString;
  finally
    LResposta.Free;
  end;
end;

procedure TGoogleDrive.ExecutaEventoIniciar;
begin
  FStatus := TStatus.TInativo;

  if not(Assigned(FQuandoIniciar)) then
    Exit;

  FQuandoIniciar;
end;

procedure TGoogleDrive.ExecutaEventoFinalizar(AStatus: TStatus);
begin
  FStatus := AStatus;

  if not(Assigned(FQuandoFinalizar)) then
    Exit;

  FQuandoFinalizar(FStatus);
end;

procedure TGoogleDrive.ExecutaEventoAguardar;
begin
  if not(Assigned(FQuandoAguardarEvento)) then
    Exit;

  FQuandoAguardarEvento;
end;

procedure TGoogleDrive.ConfiguraRequisicao;
begin
  FHttpCliente.Request.CustomHeaders.Clear;
  FHttpCliente.Request.CustomHeaders.Add(Concat('Authorization: Bearer ', FOAuth.AccessToken));
  FHttpCliente.Request.Accept := 'application/json';
end;

procedure TGoogleDrive.ExecutaRequisicao(const AUrl: String;
  ATipo: TTipoRequisicao; AParametro: TStream);
begin
  // quando não houver token de acesso
  // realizar login
  if not(FOAuth.TemToken) then
  begin
    FOAuth.Login;

    while not(FFinalizouAutenticacao) and not(FOAuth.Status = uAuthGoogle.TStatus.TFalha) and not(FCancelar) do
      ExecutaEventoAguardar;
  end
  else if (FOAuth.TemToken) and not(FOAuth.TokenValido) then
  begin
    // quando estiver expirado o token de acesso
    FOAuth.Refresh;
    while not(FFinalizouAutenticacao) and not(FOAuth.Status = uAuthGoogle.TStatus.TFalha) and not(FCancelar) do
      ExecutaEventoAguardar;
  end;

  if (not(FOAuth.TemToken) or not(FOAuth.TokenValido)) then
  begin
    ExecutaEventoFinalizar(TStatus.TFalha);
    Exit;
  end;

  ConfiguraRequisicao;

  try
    case ATipo of
      TGet: FHttpCliente.Get(AUrl);
      TPost: FHttpCliente.Post(AUrl, AParametro);
      TPatch: FHttpCliente.Patch(AUrl, AParametro);
      TDelete: FHttpCliente.Delete(AUrl);
    end;
  except on E: Exception do
    ExecutaEventoFinalizar(TStatus.TFalha);
  end;
end;

function TGoogleDrive.BuscaFormatoPorExtensao(const AExtensao: String): String;
begin
  case AnsiIndexText(AExtensao, ['.rar', '.zip', '.pas', '.iso', '.mov', '.png', '.jpeg', '.pdf', '.odt', '.jpg']) of
    0: Result := 'application/rar';
    1: Result := 'application/x-zip-compressed';
    2: Result := 'text/x-pascal';
    3: Result := 'application/x-iso9660-image';
    4: Result := 'video/quicktime';
    5: Result := 'image/png';
    6: Result := 'image/jpeg';
    7: Result := 'application/pdf';
    8: Result := 'application/vnd.oasis.opendocument.text';
    9: Result := 'image/jpeg';
    else
      Result := 'application/octet-stream';
  end;
end;

function TGoogleDrive.CriaArquivoVazio(const ADiretorioCompleto: String; AIdsPastas: TListaIds): TGoogleArquivo;
var
  LJsonEnvio: TlkJSONobject;
  LJsonIdsEnvio: TlkJSONlist;
  LId: String;
  LParametroEnvio: TStream;
  LArquivo: TGoogleArquivo;
begin
  Result := nil;

  LJsonEnvio := TlkJSONobject.Create;
  try
    LJsonEnvio.Add(IDENTIFICADOR_ARQUIVO_NOME, ExtractFileName(ADiretorioCompleto));
    LJsonEnvio.Add(IDENTIFICADOR_ARQUIVO_TIPO, BuscaFormatoPorExtensao(ExtractFileExt(ADiretorioCompleto)));

    if (Assigned(AIdsPastas)) then
    begin
      LJsonIdsEnvio := TlkJSONlist.Create;

      for LId in AIdsPastas do
        LJsonIdsEnvio.Add(LId);

      LJsonEnvio.Add(IDENTIFICADOR_ARQUIVO_PASTAS, LJsonIdsEnvio);
    end;

    LParametroEnvio := TStringStream.Create(TlkJSON.GenerateText(LJsonEnvio));

    // envia metadados
    ExecutaRequisicao(URL_GOOGLE_CRIA_ARQUIVO, TTipoRequisicao.TPost, LParametroEnvio);

    if not(FTemResposta) then
      Exit;

    Result := TGoogleArquivo.Create(FRespostaString);
  finally
    LJsonEnvio.Free;
    LParametroEnvio.Free;
  end;
end;

procedure TGoogleDrive.CriaMidiaArquivo(const AIdArquivo, ADiretorioCompleto: String);
var
  LParametroEnvio: TIdMultiPartFormDataStream;
begin
  LParametroEnvio := TIdMultiPartFormDataStream.Create;
  LParametroEnvio.AddFile('file', ADiretorioCompleto);

  // envia mídia
  ExecutaRequisicao(Format(URL_GOOGLE_ATUALIZA_ARQUIVO, [AIdArquivo]), TTipoRequisicao.TPatch, LParametroEnvio);
end;

procedure TGoogleDrive.CriaArquivo(const ADiretorioCompleto: String; AIdsPastas: TListaIds);
var
  LArquivo: TGoogleArquivo;
begin
  LArquivo := CriaArquivoVazio(ADiretorioCompleto, AIdsPastas);

  if (Assigned(LArquivo)) then
    CriaMidiaArquivo(LArquivo.Id, ADiretorioCompleto)
  else
    ExecutaEventoFinalizar(TStatus.TFalha);
end;

procedure TGoogleDrive.AtualizaTipoArquivo(const AIdArquivo, ADiretorioCompleto: String);
var
  LParametroJson: TlkJSONobject;
  LParametro: TStringStream;
begin
  LParametroJson := TlkJSONobject.Create;
  try
    LParametroJson.Add(IDENTIFICADOR_ARQUIVO_TIPO, BuscaFormatoPorExtensao(ExtractFileExt(ADiretorioCompleto)));

    LParametro := TStringStream.Create(TlkJSON.GenerateText(LParametroJson));

    ExecutaRequisicao(Format(URL_GOOGLE_ATUALIZA_ARQUIVO, [AIdArquivo]), TTipoRequisicao.TPatch, LParametro);
  finally
    LParametroJson.Free;
  end;
end;

function TGoogleDrive.BuscaElementosPorNome(const ANome: String): TList<TGoogleArquivo>;
var
  LUrl: String;
begin
  Result := nil;

  LUrl := Concat(URL_GOOGLE_LISTAR, '&q=name contains "', ANome, '" ');

  ExecutaRequisicao(TIdURI.URLEncode(LUrl), TGet);

  if not(FTemResposta) then
    Exit;

  Result := TGoogleArquivo.FromJsonArray(FRespostaString);
end;

procedure TGoogleDrive.Enviar(const ADiretorioArquivoCompleto: String;
  ASubstituir: Boolean; AIdsPai: TListaIds);
var
  LArquivos: TList<TGoogleArquivo>;
  LArquivo: TGoogleArquivo;
begin
  ExecutaEventoIniciar;

  if (ASubstituir) then
  begin
    LArquivos := BuscaElementosPorNome(ExtractFileName(ADiretorioArquivoCompleto));

    // captura primeiro arquivo para substiruir
    if (Assigned(LArquivos)) and (LArquivos.Count > 0) then
    begin
      CriaMidiaArquivo(LArquivos.Items[0].Id, ADiretorioArquivoCompleto);

      ExecutaEventoFinalizar(TStatus.TSucesso);

      Exit;
    end;
  end;

  CriaArquivo(ADiretorioArquivoCompleto, AIdsPai);

  ExecutaEventoFinalizar(TStatus.TSucesso);
end;

function TGoogleDrive.ListarArquivos: TList<TGoogleArquivo>;
begin
  Result := nil;

  ExecutaEventoIniciar;

  ExecutaRequisicao(URL_GOOGLE_LISTAR, TTipoRequisicao.TGet);

  if not(FTemResposta) then
  begin
    ExecutaEventoFinalizar(TStatus.TFalha);
    Exit;
  end;

  ExecutaEventoFinalizar(TStatus.TSucesso);

  Result := TGoogleArquivo.FromJsonArray(FRespostaString);
end;

{ TGoogleArquivo }

procedure TGoogleArquivo.Inicializa(const AJsonElemento: TlkJSONobject);
var
  I: Integer;
begin
  for I := 0 to AJsonElemento.Count - 1 do
    begin
      case AnsiIndexText(AJsonElemento.NameOf[I], ['id', 'kind', 'name', 'mimeType']) of
        0: FId := AJsonElemento.getString(I);
        1: FTipo := AJsonElemento.getString(I);
        2: FNome := AJsonElemento.getString(I);
        3: FFormato := AJsonElemento.getString(I);
      end;
    end;
end;

function TGoogleArquivo.ToString: string;
begin
  Result := Concat('Id: ', Id, ' Tipo: ', FTipo, ' Nome: ', Nome, ' Formato: ', Formato);
end;

constructor TGoogleArquivo.Create(const AJsonString: String);
var
  LJsonResposta: TlkJSONobject;
begin
  inherited Create;

  LJsonResposta := TlkJSON.ParseText(AJsonString) as TlkJSONobject;
  try
    Inicializa(LJsonResposta);
  finally
    if (Assigned(LJsonResposta)) then
      LJsonResposta.Free;
  end;
end;

constructor TGoogleArquivo.Create(const AJsonElemento: TlkJSONobject);
begin
  inherited Create;

  Inicializa(AJsonElemento);
end;

class function TGoogleArquivo.FromJsonArray(
  const AJsonArrayString: String): TList<TGoogleArquivo>;
var
  LJsonResposta: TlkJSONbase;
  I: Integer;
begin
  LJsonResposta := TlkJSON.ParseText(AJsonArrayString);

  try
    if ((LJsonResposta is TlkJSONobject) and ((LJsonResposta as TlkJSONobject).IndexOfName('files') >= 0)) then
      LJsonResposta := LJsonResposta.Field['files'] as TlkJSONlist;

    Result := TList<TGoogleArquivo>.Create;

    for I := 0 to LJsonResposta.Count - 1 do
      Result.Add(TGoogleArquivo.Create((LJsonResposta.Field[I] as TlkJSONobject)));
  finally
    if (Assigned(LJsonResposta)) then
      LJsonResposta.Free;
  end;
end;

function TGoogleArquivo._EhDiretorio: Boolean;
begin
  Result := FFormato = IDENTIFICADOR_DIRETORIO;
end;

end.
