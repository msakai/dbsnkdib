{
  Translated from "Plugif.h" by Masahiro Sakai

  Masahiro Sakai
    e-mail : ZVM01052@nifty.ne.jp
    www    : http://homepage1.nifty.com/susho/
}

unit PlugIf;

interface

uses
{$IFDEF WIN32}
  Windows,
{$ELSE}
  WinTypes,
{$ENDIF}
  SysUtils, Messages;

{$IFNDEF WIN32}
  type
    UINT  = Integer;
    DWORD = LongInt;
    WPARAM = Longint;
    LPARAM = Longint;
    PRGBQuad = ^TRGBQuad;
    TRGBQuad = packed record
      rgbBlue: Byte;
      rgbGreen: Byte;
      rgbRed: Byte;
      rgbReserved: Byte;
    end;
{$ENDIF}


{ Transrated from Plugif.h }

const
  IFPLUG_VERSION = 1;       { インターフェースのバージョン番号 }

  { result code }
  FTR_OK     =  0;          { 正常終了 }
  FTR_FAIL   = -1;          { エラー終了 }
  FTR_CANCEL =  1;          { ユーザによって中断 }


type
{ プロセス表示＆中断取り合わせ用関数。

 フィルター機能実行中に定期的に呼び出すのが望ましい。非０が帰った場合は
 処理を中断すること。

 IN:  pos     処理中の位置を示す値
      total   最大位置を示す値
 OUT:         ユーザが中断ボタンを押したなら非０、
              押してなければ０を返す。

 使用例

    for y := 0 to height-1 do begin
        if Arg.Abortfunc(y, height) <> FTR_OK then begin
            後処理
            Result := FTR_CANCEL;
            Exit;
        end;
        ... フィルター処理
    end;
}

{$IFDEF WIN32}
  TAbortfunc = function(pos, total: Word): Word; stdcall;
{$ELSE}
  TAbortfunc = function(pos, total: Word): Word;
{$ENDIF}


{ 画像データ、マスクデータへの２次元配列。

  画像データの場合　： 青 := data[y][x * 3 + 0]
                       緑 := data[y][x * 3 + 1]
                       赤 := data[y][x * 3 + 2] でアクセスする。

  マスクデータの場合： マスク値 := data[y][x]
                       マスク値が０のデータに関しては処理しなくてよい。
                       (処理しても影響はない）}
type
  PScanLines  = ^TScanLines;
  TScanLines = array[0..10000] of PByteArray;


{ plugin flag }
const
  PLGF_LOCKDLL = $0001;     { DLLを未使用時にアンロードしない }

type
  PPlugInfo = ^TPlugInfo;
  TPlugInfo = packed record
    version    : Word;   { OUT: IFPLUG_VERSION }
    nEntries   : Word;   { OUT: number of plug-in entries in this DLL }
    aboutID    : Word;   { OUT: resource string-ID of description
                                about plugin }
    flag       : Word;   { OUT: plugin flag }
  end;

{Filter Plugin Interface}
const
  FT_PAINT     =  1;        { フィルター：塗り潰し系 }
  FT_COLOR     =  2;        { フィルター：階調変更系 }
  FT_SHARP     =  3;        { フィルター：先鋭化系 }
  FT_SMOOTH    =  4;        { フィルター：平滑化系 }
  FT_NOISE     =  5;        { フィルター：ノイズ系 }
  FT_RESERVED1 =  6;        { フィルター：予約 }
  FT_RESERVED2 =  7;        { フィルター：予約 }
  FT_RESERVED3 =  8;        { フィルター：予約 }
  FT_VISUAL    =  9;        { フィルター：視覚効果系 }
  FT_EDGE      = 10;        { フィルター：輪郭検出系 }
  FT_SPECIAL   = 11;        { フィルター：特殊な用途系 }
  FT_OTHER     = 12;        { フィルター：その他 }

{ サイズ変更 ([編集]-[サイズ変更]) }
  FT_RESIZE    = 13;        { サイズ変更 }

{ 画像の合成 (合成ツール、合成ペン) }
  FT_COMBINE   = 14;        { 合成 }

{ 減色       ([編集]-[減色]) }
  FT_QUANT256  = 15;        { 減色：２５６色以下 }
  FT_QUANT16   = 16;        { 減色：１６色以下 }
  FT_QUANT2    = 17;        { 減色：２色以下 }
  FT_QUANTDSP  = 18;        { 減色：予約 }

{ filter flag }
const
  FF_MENUONLY  = $0001;   { メニューでだけ使えるフィルター }
  FF_PENONLY   = $0002;   { [ペン機能]でだけ使えるフィルター }
  FF_ONESHOT   = $0004;   { 重ね書き無効 }
  FF_NOPARAM   = $0008;   { パラメーター設定なし }
  FF_USEMASK   = $0010;   { maskデータを使用 }

type
  PFilterInfo = ^TFilterInfo;
  TFilterInfo = packed record
    FilterType : Word;     { OUT: filter type }
    Flag       : Word;     { OUT: filter flag }
    NameID     : Word;     { OUT: resource string-ID of filter name }
    BitmapID   : Word;     { OUT: resource bitmap-ID of filter (optional) }
  end;

  PFilterArg = ^TFilterArg;
  TFilterArg = packed record
    Abortfunc : TAbortfunc;  { IN:  query abort function }
    inData    : PScanLines;  { IN:  source data (B,G,R ordered 24bits data) }
    outData   : PScanLines;  { OUT: result data (B,G,R ordered 24bits data) }
    mask      : PScanLines;  { IN:  mask data (8 bits data) }
    xInData   : Word;        { IN:  left pixel of inData }
    yInData   : Word;        { IN:  top pixel of inData }
    cxData    : Word;        { IN:  result data width }
    cyData    : Word;        { IN:  result data height }
    fgColor   : LongInt;     { IN:  current foreground color }
    bgColor   : LongInt;     { IN:  current background color }
    cxInData  : Word;        { IN:  width of inData }
    cyInData  : Word;        { IN:  height of inData }
  end;

  PResizeArg = ^TResizeArg;
  TResizeArg = packed record
    Abortfunc : TAbortfunc;  { IN:  query abort function }
    inData    : PScanLines;  { IN:  source data (B,G,R ordered 24bits data) }
    cxIn      : Word;        { IN:  source data width }
    cyIn      : Word;        { IN:  source data height }
    outData   : PScanLines;  { OUT: result data (B,G,R ordered 24bits data) }
    cxOut     : Word;        { IN:  destination data width }
    cyOut     : Word;        { IN:  destination data height }
  end;
  
  PCombineArg = ^TCombineArg;
  TCombineArg = packed record
    Abortfunc : TAbortfunc;  { IN:  query abort function }
    inData1   : PScanLines;  { IN:  source data (B,G,R ordered 24bits data) }
    xInData1  : Word;        { IN:  left pixel of inData }
    yInData1  : Word;        { IN:  top pixel of inData }
    inData2   : PScanLines;  { IN:  source data (B,G,R ordered 24bits data) }
    xInData2  : Word;        { IN:  left pixel of inData }
    yInData2  : Word;        { IN:  top pixel of inData }
    outData   : PScanLines;  { OUT: result data (B,G,R ordered 24bits data) }
    cxData    : Word;        { IN:  data width }
    cyData    : Word;        { IN:  data height }
  end;

  PQuantizeArg = ^TQuantizeArg;
  TQuantizeArg = packed record
    Abortfunc : TAbortfunc;  { IN:  query abort function }
    inData    : PScanLines;  { IN:  source data (B,G,R ordered 24bits data) }
    outData   : PScanLines;  { OUT: result data (8 bits color index data) }
    outRGB    : PRGBQUAD;    { OUT: color palette }
    cxData    : Word;        { IN:  data width }
    cyData    : Word;        { IN:  data height }
    mask      : PScanLines;  { IN:  mask data (8 bits data) }
  end;

  TDialogInfo = packed record
    dlgName   : PChar;      { OUT: dialog template name }
    paramSize : DWORD;      { OUT: size of parameter contents }
    dlgProc   : TFNDlgProc; { OUT: dialog procedure address (optional) }
    lParam    : LPARAM;     { OUT: dialog argument (optional) }
    helpFile  : PChar;      { OUT: help file name (optional) }
    contextID : DWORD;      { OUT: help context-ID (optional) }
  end;



{ Transrated from Sample01.txt }

const
  DBSM_FILTER_PREVIEW  = WM_USER + 100;
{ SetParam()呼び出し中にFilter()を呼び出してもらう。
  SetParam()がFTR_OKを返すとプレビュー時のデータをそのまま
  処理結果として使用し、SetParam()後のFilter()の呼び出しは
  スキップされる。
  プレビューで使用。}

  DBSM_GET_PALETTE = WM_USER + 101;
{ 画像表示用のパレットを返す。256色環境でなければ、０を返す。
  (このパレットは削除してはいけない。)
  16色減色で作成した色の一覧を表示するために使用 }

  DBSM_GET_NEARESTCOLOR  = WM_USER + 102;
{ 画像表示用のパレットの中から、引数で渡した色に一番近い
  色を探して返す。256色環境でなければ引数がそのまま返る。
  16色減色で作成した色の一覧を表示するために使用。}


  DBSM_GET_TOOLFONT = WM_USER + 103;
{ [設定]-[その他のウィンドウフォント]で指定されたフォントを
  返す。(このフォントは削除してはいけない。)
  ダイアログのフォントを他のウィンドウと合わせるために使用。}

implementation

end.
