library dbsnkdib;

uses
  Windows, SysUtils, Graphics, NkDib, PlugIf;

{$E f32}

{$R strres.res}

type
  EDibasAbort = Exception;

  TProgressHandler = class(TObject)
  private
      FAbortFunc: TAbortFunc;
  public
      procedure Progress(Sender: TObject; Stage: TProgressStage;
        PercentDone: Byte; RedrawNow: Boolean; const R: TRect; const Msg: string);
  end;

procedure TProgressHandler.Progress;
begin
    if FAbortFunc(PercentDone, 100) <> FTR_OK then
        raise EDibasAbort.Create('');
end;

procedure PlugInfo(var Info: TPlugInfo); stdcall;
begin
    with Info do begin
        version  := IFPLUG_VERSION;
        nEntries := 2;
        aboutID  := 100;
    end;
end;

procedure FilterInfo(No: Word; var Info: TFilterInfo); stdcall;
begin
    case No of
      1, 2:
        begin
            Info.FilterType := FT_QUANT256;
            Info.NameID     := No;
            Info.Flag       := FF_NOPARAM;
        end;
    end;
end;

function  SetParam(No: Word; ParentWindow: hwnd; Pen: WordBool): Integer; stdcall;
begin
    Result := FTR_FAIL;
end;

function  Filter(No: Word; var Arg: TFilterArg)     : Integer; stdcall;
begin
    Result := FTR_FAIL;
end;

function  Resize(No: Word; var Arg: TResizeArg)     : Integer; stdcall;
begin
    Result := FTR_FAIL;
end;

function  Combine(No: Word; var Arg: TCombineArg)   : Integer; stdcall;
begin
    Result := FTR_FAIL;
end;

function  Quantize(No: Word; var Arg: TQuantizeArg) : Integer; stdcall;
var Dib: TNkDib;
    ProgressHandler: TProgressHandler;
    PPal: PRGBQuad;
    i: Integer;
begin
    Result := FTR_FAIL;
    case No of
      1, 2:
        begin
            Dib := TNkDib.Create;
            try
                Dib.Width    := Arg.cxData;
                Dib.Height   := Arg.cyData;
                Dib.BitCount := 24;

                // 元データをコピー
                for i := 0 to Arg.cyData - 1 do
                    Move(Arg.inData[i]^, Dib.ScanLine[i]^, Arg.cxData * 3);

                // 品質の設定
                if No = 1 then
                    Dib.ConvertMode := nkCmNormal
                else
                    Dib.ConvertMode := nkCmFine;

                // 減色
                ProgressHandler := TProgressHandler.Create;
                try
                    ProgressHandler.FAbortFunc := Arg.Abortfunc;
                    Dib.OnProgress  := ProgressHandler.Progress;
                    try
                        Dib.PixelFormat := nkPf8Bit;
                    except
                        on EDibasAbort do begin
                            Result := FTR_CANCEL;
                            Exit;
                        end;
                    end;
                finally
                    ProgressHandler.Free;
                    Dib.OnProgress := nil;
                end;

                // パレットのコピー
                PPal := Arg.outRGB;
                for i := 0 to Dib.PaletteSize - 1 do begin
                    PPal.rgbBlue  := GetBValue(Dib.Colors[i]);
                    PPal.rgbGreen := GetGValue(Dib.Colors[i]);
                    PPal.rgbRed   := GetRValue(Dib.Colors[i]);
                    Inc(PPal);
                end;
                // 結果のコピー
                for i := 0 to Arg.cyData - 1 do
                    Move(Dib.ScanLine[i]^, Arg.outData[i]^, Arg.cxData);

                // 無事終了
                Result := FTR_OK;
            finally
                Dib.Free;
            end;
        end;
    end;
end;

exports
  PlugInfo   name 'PlugInfo',
  SetParam   name 'SetParam',
  FilterInfo name 'FilterInfo',
  Filter     name 'Filter',
  Resize     name 'Resize',
  Combine    name 'Combine',
  Quantize   name 'Quantize';

begin
end.
