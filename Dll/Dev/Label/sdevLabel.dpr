library sdevLabel;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

{$R *.res}
{$R *.dres}

uses
  vcl.forms,
  System.SysUtils,
  System.Classes,
  winapi.windows,
  vcl.graphics,
  vcl.controls,
  unitClasses4Devices in '..\..\..\Units\Other\unitClasses4Devices.pas',
  frmSettings in 'frmSettings.pas' {shBC},
  UnitRes in 'UnitRes.pas';

Const
  cNumberOfPorts = 0; // ���������� ������ �� ����� ����������
  // cCurrentVersion:shortstring='1.0'; //������ ATCSS, ��� ���. ��������� ����������
  cImgDeviceWidth = 20; // ������ ����������� ����� ����������� �� "�����"
  cImgDeviceHeigth = 20; // ������ ����������� ����� ����������� �� "�����"
  cDevType = 10; // ��� ������ ����������
  cSDevType: shortstring = 'Decoration';
  cSDevFamily: shortstring = 'Label';
  cSDevModel: shortstring = 'Label';

Var
  TD: array of TDevice;
  // ��������� ������ "���������", ������ - ��������� ����� ���� ����� ��������� �������
  // TP: TRCPorts;// ��������� ������� "������" , ������ - ��������� ����� ���� ����� ��������� �������
  TID: TInfoDevice; // ��������� ������ "���������� � ����������"


  // CallBack -������
function BackProcGetLevel(Sender: TObject): single; stdcall;
// ������� ��������� ������ ������ �������, �� ����� ������ �� �����;
begin

end;




procedure BackProcDraw(Sender: TObject; isRunning: boolean;
  RunningTime: Extended); stdcall;
var
  s: integer;
  h, w: integer;
begin

  // ������� Image
  if Assigned((Sender as TDevice).Image) then
  begin
        (Sender as TDevice).Image.Canvas.Font.Style := [];
      if vBold[(Sender as TDevice).InternalIndex] then (Sender as TDevice).Image.Canvas.Font.Style :=(Sender as TDevice).Image.Canvas.Font.Style + [fsBold];
      if vItalic[(Sender as TDevice).InternalIndex] then (Sender as TDevice).Image.Canvas.Font.Style :=(Sender as TDevice).Image.Canvas.Font.Style + [fsItalic];
      if vUnderLine[(Sender as TDevice).InternalIndex] then (Sender as TDevice).Image.Canvas.Font.Style :=(Sender as TDevice).Image.Canvas.Font.Style + [fsUnderLine];
      (Sender as TDevice).Image.Canvas.Font.Color:=vTextColor[(Sender as TDevice).InternalIndex];


      (Sender as TDevice).Image.Canvas.Brush.Color:=vBackColor[(Sender as TDevice).InternalIndex];

      (Sender as TDevice).Image.Canvas.Font.Size :=vSize[(Sender as TDevice).InternalIndex];

    w := (Sender as TDevice).Image.Canvas.TextExtent(vText[(Sender as TDevice).InternalIndex]).cx;
    if w <> (Sender as TDevice).Image.Width then
    BEGIN

      // fsItalic fs Underline
      h := (Sender as TDevice).Image.Canvas.TextExtent(vText[(Sender as TDevice).InternalIndex]).cy;
      (Sender as TDevice).Image.Width := w;
      (Sender as TDevice).Image.Height := h;
      (Sender as TDevice).Image.Picture.Bitmap.Height := h;
      (Sender as TDevice).Image.Picture.Bitmap.Width := w;

    END;




    // (Sender as TDevice).Image.Canvas.;

    //(Sender as TDevice).Image.CleanupInstance;
    if vBackColor[(Sender as TDevice).InternalIndex]=clWhite then (Sender as TDevice).Image.Transparent:=true else (Sender as TDevice).Image.Transparent:=false;
   // begin
    //PatBlt((Sender as TDevice).Image.Canvas.Handle, 0, 0,
//(Sender as TDevice).Image.ClientWidth, (Sender as TDevice).Image.ClientHeight, WHITENESS);

    //(Sender as TDevice).Image.Canvas.Rectangle(0,0,(Sender as TDevice).Image.Width,(Sender as TDevice).Image.Height);
    //(Sender as TDevice).Image.Canvas.FillRect(rect(0,0,(Sender as TDevice).Image.Width,(Sender as TDevice).Image.Height));
   // end;

    (Sender as TDevice).Image.Canvas.TextOut(0, 0, vText[(Sender as TDevice).InternalIndex]);

  end;

end;

Procedure BackApplySaveData(Sender: TObject); stdcall;
var r,g,b,c:byte;
i:integer;
Str:ansistring;
begin
r:=ord((Sender as TDevice).SaveData[0]);
g:=ord((Sender as TDevice).SaveData[1]);
b:=ord((Sender as TDevice).SaveData[2]);
vTextColor[(Sender as TDevice).InternalIndex]:=rgb(r,g,b);
r:=ord((Sender as TDevice).SaveData[3]);
g:=ord((Sender as TDevice).SaveData[4]);
b:=ord((Sender as TDevice).SaveData[5]);
vBackColor[(Sender as TDevice).InternalIndex]:=rgb(r,g,b);
vSize[(Sender as TDevice).InternalIndex]:=ord((Sender as TDevice).SaveData[6]);
if (Sender as TDevice).SaveData[7]='1' then vBold[(Sender as TDevice).InternalIndex]:=true else vBold[(Sender as TDevice).InternalIndex]:=false;
if (Sender as TDevice).SaveData[8]='1' then vItalic[(Sender as TDevice).InternalIndex]:=true else vItalic[(Sender as TDevice).InternalIndex]:=false;
if (Sender as TDevice).SaveData[9]='1' then vUnderline[(Sender as TDevice).InternalIndex]:=true else vUnderline[(Sender as TDevice).InternalIndex]:=false;
C:=ord((Sender as TDevice).SaveData[10]);
Str:='';
for I := 1 to C do
  begin
    Str:=Str+(Sender as TDevice).SaveData[10+I];
  end;
vText[(Sender as TDevice).InternalIndex]:= Str;

    BackProcDraw(Sender, false, 0);
end;

Procedure BackShowSettings(Sender: TObject); stdcall;
begin
  application.Handle := TD[(Sender as TDevice).InternalIndex].hosthandle;
  Application.CreateForm(TformSettings, formSettings);
  // frmsettings.formSettings:=TFormSettings.Create(application);

  formSettings.InternalIndex := (Sender as TDevice).InternalIndex;
  formSettings.Device := (Sender as TDevice);
  formSettings.OrigHandle := TD[(Sender as TDevice).InternalIndex].OrigHandle;
  formSettings.ShowModal;
  BackApplySaveData(Sender);
end;
// ���������� ������
Function What_is(var Version: shortstring): integer; stdcall;
begin
  Version := AppVersion4Dll;
  result := cDevType;

end;

Function Get_info_class(): TInfoDevice; stdcall;

begin
  // ��������� ����
  UnitRes.SetLang();
  TID := TInfoDevice.Create;
  TID.vType := cDevType;
  TID.vSType := cSDevType;
  TID.vSFamily := cSDevFamily;
  TID.evFileName := '';
  TID.evLoaded := false;
  TID.evLibHandle := 0;
  SetLength(TID.vSModel, 1);
  TID.vSModel[0] := cSDevModel;
  TID.vIcon := LoadIcon(HInstance, 'tlb');
  TID.vSDisplayName := GetText(0);
  Get_info_class := TID;
end;

Function Get_Device_class(hosthandle: THandle; MainDevice: TDevice)
  : TDevice; stdcall;
  var Str:AnsiString;
begin
  UnitRes.SetLang();

  // ������� ��������� ������ ������ ����������
  // ������� ��������� ������ ������ ����������
  SetLength(TD, High(TD) + 2);
  SetLength(vText, High(vText) + 2);
  SetLength(vSize, High(vSize) + 2);
  SetLength(vTextColor, High(vTextColor) + 2);
  SetLength(vBackColor, High(vBackColor) + 2);
  SetLength(vBold, High(vBold) + 2);
  SetLength(vItalic, High(vItalic) + 2);
  SetLength(vUnderline, High(vUnderline) + 2);

  TD[High(TD)] := TDevice.Create(High(TD), cImgDeviceWidth, cImgDeviceHeigth,
    cDevType, cSDevType, cSDevFamily, cSDevModel, cNumberOfPorts, @BackProcDraw,
    nil, Nil, Nil, Nil, nil, @BackShowSettings, @BackApplySaveData, nil,
    application.Handle, hosthandle, MainDevice, nil);

  TD[High(TD)].LenSaveData := 111;
  TD[High(TD)].SaveData[0] := AnsiChar(0);//R ������
  TD[High(TD)].SaveData[1] := AnsiChar(0); //G ������
  TD[High(TD)].SaveData[2] := AnsiChar(0); //B ������

  TD[High(TD)].SaveData[3] := AnsiChar(255); //R ���� ������
  TD[High(TD)].SaveData[4] := AnsiChar(255); //G ���� ������
  TD[High(TD)].SaveData[5] := AnsiChar(255); //B ���� ������
  TD[High(TD)].SaveData[6] := AnsiChar(8); //������ ������
  TD[High(TD)].SaveData[7] := '0'; //��������
  TD[High(TD)].SaveData[8] := '0'; //�����������
  TD[High(TD)].SaveData[9] := '0'; //��������������

  TD[High(TD)].SaveData[10] := AnsiChar(5); //���������� ��������
  TD[High(TD)].SaveData[11] := 'L'; //��� �����
  TD[High(TD)].SaveData[12] := 'a'; //��� �����
  TD[High(TD)].SaveData[13] := 'b'; //��� �����
  TD[High(TD)].SaveData[14] := 'e'; //��� �����
  TD[High(TD)].SaveData[15] := 'l'; //��� �����
  TD[High(TD)].ApplySettings;
  // �������� ��������� ������� Pushed

  // ��������� ������ �� ��������� ������ ����������
  result := TD[High(TD)];

end;

exports Get_Device_class name 'Get_Device_class';

exports Get_info_class name 'Get_info_class';

exports What_is name 'What_is';

exports BackApplySaveData name 'BackApplySaveData';

begin

end.
