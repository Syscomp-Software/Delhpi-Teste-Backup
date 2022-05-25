unit uZip;

interface

uses
  SysUtils, AbArcTyp;

type
  TTipoExecucao = (TCompactar, TDescompactar);

  TZip = class
  private
    FDiretorioDestino,
    FNomeArquivo,
    FDiretorioCompletoOrigem: String;
    FProgressoArquivo: TAbArchiveProgressEvent;
    FQuandoFalhar: TProc<String>;
    FTipoExecucao: TTipoExecucao;
    FEmExecucao: Boolean;

    const
      EXTENSAO_COMPRESSAO = '.ZIP';

      DIRETORIO_ZIP = '%s\Zip';

    procedure ExecutaFuncaoFalha(AMensagem: String);

    function AjustaDiretorio(const ADiretorio: String): String;

    procedure CriaDiretorioExecucao;

    function Validar: Boolean;
  public
    constructor Create(const ADiretorioCompletoOrigem: String);
    destructor Destroy; override;

    property QuandoFalhar: TProc<String> read FQuandoFalhar write FQuandoFalhar;
    property ProgressoArquivo: TAbArchiveProgressEvent read FProgressoArquivo write FProgressoArquivo;
    property EmExecucao: Boolean read FEmExecucao;

    procedure Compactar;
    procedure Descompactar;
  end;

implementation

uses
  AbZipper, AbUnzper,
  Classes;

{ TZip }

constructor TZip.Create(
  const ADiretorioCompletoOrigem: String);
begin
  inherited Create;

  FNomeArquivo := ExtractFileName(ADiretorioCompletoOrigem);
  FDiretorioCompletoOrigem := ADiretorioCompletoOrigem;
  FDiretorioDestino := Format(DIRETORIO_ZIP, [ExtractFileDir(ParamStr(0))]);
end;

destructor TZip.Destroy;
begin
  inherited;
end;

procedure TZip.ExecutaFuncaoFalha(AMensagem: String);
begin
  if (Assigned(FQuandoFalhar)) then
    FQuandoFalhar(AMensagem);

  FEmExecucao := False;
end;

function TZip.AjustaDiretorio(const ADiretorio: String): String;
begin
  Result := ADiretorio;

  if (ADiretorio[Length(ADiretorio)] <> '\') then
    Result := Concat(ADiretorio, '\');
end;

function TZip.Validar: Boolean;
begin
  Result := False;

  if not(DirectoryExists(ExtractFileDir(FDiretorioCompletoOrigem))) then
  begin
    ExecutaFuncaoFalha('Diretório de origem não existe!');
    Exit;
  end;

  if ((FTipoExecucao = TTipoExecucao.TCompactar) and (ExtractFileExt(FDiretorioCompletoOrigem) = EXTENSAO_COMPRESSAO)) then
  begin
    ExecutaFuncaoFalha('Arquivo não compativel para compactação!');
    Exit;
  end;

  if ((FTipoExecucao = TTipoExecucao.TDescompactar) and (ExtractFileExt(FDiretorioCompletoOrigem) <> EXTENSAO_COMPRESSAO)) then
  begin
    ExecutaFuncaoFalha('Arquivo não compativel para descompactação!');
    Exit;
  end;

  Result := True;
end;

procedure TZip.CriaDiretorioExecucao;
begin
  if not(DirectoryExists(FDiretorioDestino)) then
    ForceDirectories(FDiretorioDestino);
end;

procedure TZip.Descompactar;
var
  LZipper: TAbUnZipper;
  I: Integer;
  LDiretorioCompleto: string;
  LArquivo: TMemoryStream;
begin
  FTipoExecucao := TTipoExecucao.TDescompactar;

  if not(Validar) then
    Exit;

  FEmExecucao := True;

  CriaDiretorioExecucao;

  LZipper := TAbUnZipper.Create(nil);
  try
    LZipper.BaseDirectory := FDiretorioDestino;
    LZipper.FileName := Concat(AjustaDiretorio(FDiretorioDestino), ChangeFileExt(FNomeArquivo, EXTENSAO_COMPRESSAO));
    LZipper.OnArchiveProgress := FProgressoArquivo;
    LZipper.ExtractOptions := [TAbExtractOption.eoCreateDirs];

    for I := 0 to LZipper.Count - 1 do
    begin
      LDiretorioCompleto := Concat(LZipper.BaseDirectory, '\', StringReplace(LZipper.Items[i].Filename, '/', '\', [rfReplaceAll, rfIgnoreCase]));

      // quando for não for arquivo criar diretorio
      if (ExtractFileName(LDiretorioCompleto) = '') then
      begin
        if not(DirectoryExists(LDiretorioCompleto)) then
          CreateDir(LDiretorioCompleto);
      end
      else
      begin
        LArquivo := TMemoryStream.Create;
        LZipper.ExtractToStream(LZipper.Items[i].Filename, LArquivo);
        LArquivo.SaveToFile(LDiretorioCompleto);
        LArquivo.Free;
      end;
    end;
  finally
    LZipper.CloseArchive;
    LZipper.Free;
    FEmExecucao := False;
  end;
end;

procedure TZip.Compactar;
var
  LZipper: TAbZipper;
begin
  FTipoExecucao := TTipoExecucao.TCompactar;

  if not(Validar) then
    Exit;

  FEmExecucao := True;

  CriaDiretorioExecucao;

  LZipper := TAbZipper.Create(nil);
  try
    LZipper.BaseDirectory := FDiretorioDestino;
    LZipper.FileName := Concat(AjustaDiretorio(FDiretorioDestino), ChangeFileExt(FNomeArquivo, EXTENSAO_COMPRESSAO));
    LZipper.OnArchiveProgress := FProgressoArquivo;
    LZipper.StoreOptions := [soStripPath, soStripDrive];
    LZipper.AddFiles(FDiretorioCompletoOrigem, 0);
    LZipper.Save;
  finally
    LZipper.CloseArchive;
    LZipper.Free;
    FEmExecucao := False;
  end;
end;

end.
