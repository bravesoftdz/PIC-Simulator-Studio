unit unitDev;

//
interface

uses SysUtils, Classes, winapi.windows, forms, Vcl.ExtCtrls, System.UITypes,
  Vcl.dialogs,
  Vcl.controls, unitClasses4Devices, unitRes, Vcl.stdctrls,
  unitregistry, System.Types, IoUtils;

type


  // ����� ��� ��������� ������� ����

  clsMouse = class
    procedure imgMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure imgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure imgMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure ImgDblClick(Sender: TObject);
    procedure ImgClick(Sender: TObject);
  end;

var
  AInfoDevice: array of TInfoDevice; // ������ �������� ��������� (��� ��������)
  CurrentDevice: integer; // ������� ���������� �� ������� ����
  CurrentSubDevice: integer; // ������� ���-���������� ��� ������

  // DevLibCount: integer = 0; // ������� ����������� ���������
  lastErrCode: integer = 0; // ��� ��������� ������
  lastErrText: string = ''; // ���. ���������� �� ������

  Devices:TDevices; // ������ ��������� �� �����
  Nodes:TNodes; //������ �����
  // Dev_ln: integer; // ������ ������� ��������� �� �����
  cMouse: clsMouse;

  tmpImage: TImage;
  // ����� �������� ���� �����, ��� �������� ������� �����-����

  // �������, ������� ����� �� ��������� ������
  // ����� ����� (�������� ���� ����-�, �������� 0-�� ���������� - ����������������)
function Reset(): boolean;
// ������� ���������� �� �����
function Create_device(DevIndex: integer; Parent: TComponent;
  X, Y: integer): boolean;
// ��������� ������������� ����������� c ������� ���� ��������� � ���������� ���� �� ���
function FindAndLoadDevices(OutComponent: TMemo; Path: string): boolean;
// ������� � ������ �������
function LoadLib(DevIndex: integer): boolean;
//�������� ����� �� ������ ����������
function Create_nodes(DevIndex:integer):boolean;
implementation

uses main;

procedure clsMouse.imgMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
 tmpImage := (Sender as TImage);

if get_rtRunning then //Run-time mode
  begin
  if Devices[(Sender as TImage).Tag].AssignedBackMD   then
   Devices[(Sender as TImage).Tag].MouseDown(Button,Shift,X,Y);
  exit;
  end;



  if Button = TMouseButton.mbLeft then
  begin
    Devices[(Sender as TImage).Tag].x_img_XX := X;
    Devices[(Sender as TImage).Tag].x_img_YY := Y;
  end;
  if Button = TMouseButton.mbRight then
  begin
    // Popup ���� ����������, ���� ��������� image, ���. �������
    main.MainForm.exchange:=true;

  end;
end;

procedure clsMouse.imgMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
begin
if get_rtRunning then //Run-time mode
  begin
  if Devices[(Sender as TImage).Tag].AssignedBackMM then
  Devices[(Sender as TImage).Tag].MouseMove(Shift,X,Y);
  exit;
  end;

  if ssLeft in Shift then
  begin
    Devices[(Sender as TImage).Tag].Image.Left :=
      Devices[(Sender as TImage).Tag].Image.Left -
      (Devices[(Sender as TImage).Tag].x_img_XX - X);
    Devices[(Sender as TImage).Tag].Image.Top := Devices[(Sender as TImage).Tag]
      .Image.Top - (Devices[(Sender as TImage).Tag].x_img_YY - Y);
    if Devices[(Sender as TImage).Tag].Image.Left < 0 then
      Devices[(Sender as TImage).Tag].Image.Left := 0;
    if Devices[(Sender as TImage).Tag].Image.Top < 48 then
      Devices[(Sender as TImage).Tag].Image.Top := 48;
   main.MainForm.exchange:=true;
  end;
end;


procedure clsMouse.imgMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
begin
if get_rtRunning then //Run-time mode
  begin
  if Devices[(Sender as TImage).Tag].AssignedBackMU then
  Devices[(Sender as TImage).Tag].MouseUp(Button,Shift,X,Y);
  exit;
  end;


end;

procedure clsMouse.ImgDblClick(Sender: TObject);
begin
if get_rtRunning then //Run-time mode
  begin
  if Devices[(Sender as TImage).Tag].AssignedBackDblClick then
  Devices[(Sender as TImage).Tag].DblClick();
  exit;
  end
else
begin //Design-mode
main.MainForm.exchange:=true;
main.MainForm.CompChild.mnuPopupSetupPortsClick(Sender);

end;

end;
procedure clsMouse.ImgClick(Sender: TObject);
begin
if get_rtRunning then //Run-time mode
  begin
  if Devices[(Sender as TImage).Tag].AssignedBackClick then
  Devices[(Sender as TImage).Tag].Click();
  exit;
  end;

end;

function Reset(): boolean;
var
  J: integer;
  HD,LD: integer;
//  img:TImage;
  // tmpTP:TRCPorts;
begin
  // ��������� ��� ������ "���������� �� �����"
  HD := high(Devices);
  LD:=Low(Devices);
  if HD > -1 then
    for J := HD downto LD do
    begin
      Devices[J].Image.Free;
      Devices[J].Free;
      //img.Free;

    end;
 SetLength(Devices, 0);

 //���������� ������ "����" nodes
  HD := high(Nodes);
  LD:=Low(Nodes);
  if HD > -1 then
    for J := HD downto LD do
    begin
      Nodes[J].Free;
      //img.Free;

    end;
 SetLength(Nodes, 0);



  // �������� ������� � �������� 0 - ���������������
  {
    SetLength(Devices, 1);

    //Devices[0]:=TDevice.Create( 110,77,0,'','','',4,tmpTP,@Reset);
    if not AInfoDevice[CurrentDevice].evLoaded then LoadLib(CurrentDevice);
    Devices[0]:=AInfoDevice[CurrentDevice].Get_Device_class(AppVersion4Dll);
    Devices[0].image := TImage.Create(Parent);
    Devices[0].image.Parent := (Parent as twincontrol);
    Devices[0].image.Left := 30;
    Devices[0].image.Top := 30;
    Devices[0].image.Tag := 0;
    Devices[0].image.WIDTH:=Devices[0].Width;
    Devices[0].image.HEIGHT:=Devices[0].Height;
    Devices[0].image.Transparent := true;
    Devices[0].DrawImage(FALSE,0);

    // (Dev[Dev_ln - 1].Img as TImage).Height := 10;
    // (Dev[Dev_ln - 1].Img as TImage).Width := 10;

    (Devices[0].image as TImage).OnMouseDown := cMouse.imgMouseDown;
    // TMouseEvent(mMd);

    (Devices[0].image as TImage).OnMouseMove := cMouse.imgMouseMove; }

end;

function LoadLib(DevIndex: integer): boolean;
var
  s: string;
begin
  AInfoDevice[DevIndex].evLoaded := false;
  LoadLib := false;
  // 1.�������� ������������� �����
  if not TFile.exists(AInfoDevice[DevIndex].evFileName) then
  begin // ���� �� ������
    lastErrCode := 1; // ���� ���������� �� ������
    exit;
  end;
  // 2.������� ��������� ����������
  s := AInfoDevice[DevIndex].evFileName;
  AInfoDevice[DevIndex].evLibHandle := LoadLibrary(PWideChar(s));
  // PWideChar(AInfoDevice[DevIndex].evFileName));
  if AInfoDevice[DevIndex].evLibHandle < 32 then
  begin // ������ �������� ����������
    lastErrCode := 2; // ������ ��������� ����������� (handle) ����������
    exit;
  end;
  // 3.������� �������� ����������� ��� �������
  @AInfoDevice[DevIndex].Get_info_class :=
    GetProcAddress(AInfoDevice[DevIndex].evLibHandle, 'Get_info_class');
  @AInfoDevice[DevIndex].Get_Device_class :=
    GetProcAddress(AInfoDevice[DevIndex].evLibHandle, 'Get_Device_class');
  @AInfoDevice[DevIndex].What_is :=
    GetProcAddress(AInfoDevice[DevIndex].evLibHandle, 'What_is');
  if (not Assigned(AInfoDevice[DevIndex].Get_info_class)) or
    (not Assigned(AInfoDevice[DevIndex].Get_Device_class)) or
    (not Assigned(AInfoDevice[DevIndex].What_is)) then
  begin // ������ ������������� �����-������ �������
    lastErrCode := 4; // �� ������� ����� ������ � �����
    FreeLibrary(AInfoDevice[DevIndex].evLibHandle);
    exit;
  end;
  // ��� ��� ����������� ���
  AInfoDevice[DevIndex].evLoaded := true;
  LoadLib := true;
end;

function Create_nodes(DevIndex:integer):boolean;
var
  I: Integer;
begin
Create_nodes:=false; //�� ������ ������, �������� ���� ���������
if ((devindex>High(Devices)) or (devindex<0)) then exit;   //������ ������� �� �������
for I := Low(Devices[DevIndex].Port) to High(Devices[DevIndex].Port) do
  begin
    SetLength(Nodes, High(Nodes)+2);  //������ ��� ��������
    Nodes[High(Nodes)]:=TNode.Create; //�������� ���� � ������� ��������
    SetLength(Nodes[High(Nodes)].Ports,1); //�������� ���� ����� �� ���� � ����
    Nodes[High(Nodes)].Ports[0]:=Devices[DevIndex].Port[I]; //������� ���� ����
    Devices[DevIndex].Port[I].Node:=Nodes[High(Nodes)]; //� ����� ����
  end;


Create_nodes:=true;
end;

function Create_device(DevIndex: integer; Parent: TComponent;
  X, Y: integer): boolean;
// ������� ���������� �� �����

begin
if not AInfoDevice[DevIndex].evLoaded then
    if not LoadLib(DevIndex) then
    begin
      showmessage('Error loading  dll or atcdev file');
      exit;
    end;
  // inc(Dev_ln);
  SetLength(Devices, High(Devices) + 2); //#Bug? 2

  if High(Devices)=0 then Devices[High(Devices)] := AInfoDevice[DevIndex].Get_Device_class
    (application.Handle,nil) else Devices[High(Devices)] := AInfoDevice[DevIndex].Get_Device_class
    (application.Handle,Devices[0]);
  Devices[High(Devices)].Image := TImage.Create(Parent);
  Devices[High(Devices)].Image.Parent := (Parent as twincontrol);
  Devices[High(Devices)].Image.Left := X;
  Devices[High(Devices)].Image.Top := Y;
  Devices[High(Devices)].Image.Tag := High(Devices);
  Devices[High(Devices)].Image.Transparent := true;
  Devices[High(Devices)].Image.Height := Devices[High(Devices)].Height;
  Devices[High(Devices)].Image.Width := Devices[High(Devices)].Width;
  Devices[High(Devices)].Image.PopupMenu := main.MainForm.CompChild.PopupMenu;
  Devices[High(Devices)].Image.OnMouseDown := cMouse.imgMouseDown;
  Devices[High(Devices)].Image.OnMouseMove := cMouse.imgMouseMove;
  Devices[High(Devices)].Image.OnMouseUp := cMouse.imgMouseUp;
  Devices[High(Devices)].Image.OnClick := cMouse.imgClick;
  Devices[High(Devices)].image.OnDblClick:=cMouse.imgDblClick;
  Devices[High(Devices)].Image.OnContextPopup:=main.MainForm.CompChild.Image1ContextPopup;


  // TMouseEvent(mMd);


  Devices[High(Devices)].DrawImage(false, 0);

end;

// �������� ���� � ���������� �� ���������� ������
Function RemoveLastDevInfoIfIsAvailable(): boolean;
var
  I,N: integer;
  //s1,s2:tashortstring;
begin
  if not Assigned(AInfoDevice[High(AInfoDevice)]) then
  begin
    RemoveLastDevInfoIfIsAvailable := true;
    SetLength(AInfoDevice, High(AInfoDevice));
    exit;
  end;

  N:= High(AInfoDevice);
  for I := Low(AInfoDevice) to  N - 1 do
  begin
    if (AInfoDevice[I].vSModel[0] = AInfoDevice[N].vSModel[0]) and (AInfoDevice[I].vSFamily = AInfoDevice[N].vsFamily) and (AInfoDevice[I].vSType = AInfoDevice[N].vSType) and (AInfoDevice[I].vType = AInfoDevice[N].vType)  then
    begin
      RemoveLastDevInfoIfIsAvailable := true;
      // AInfoDevice[High(AInfoDevice)].Free;
      AInfoDevice[High(AInfoDevice)].Free;
      SetLength(AInfoDevice, High(AInfoDevice));
      exit;
    end;
  end;
  RemoveLastDevInfoIfIsAvailable := false;

end;

// �������� ���������� � ����������
function LoadDevInfo(fn: string): boolean;

var
  id2: TInfoDevice;
  iI, HID: integer;
  DllVer:shortstring;
  // �������, ������������� �� Dll-��
  Get_info_class: Function(): TInfoDevice; stdcall;
  Get_Device_class: Function(HostHandle: THandle;MainDevice:TDevice): TDevice; stdcall;
  What_is: Function(var version: shortstring): integer; stdcall;
  // ����������
  ELibHandle: THandle; // �������, ����������� ����������
  WI: integer; // ������� �������� �� �-��� ������? (WhatIs)
begin
  LoadDevInfo := false;
  // 1.�������� ������������� �����
  if not TFile.exists(fn) then
  begin // ���� �� ������
    lastErrCode := 1; // ���� ���������� �� ������
    exit;
  end;
  // 2.������� ��������� ����������
  ELibHandle := LoadLibrary(PWideChar(fn));
  if ELibHandle < 32 then
  begin // ������ �������� ����������
    lastErrCode := 2; // ������ ��������� ����������� (handle) ����������
    exit;
  end;
  // 3.������� �������� ����������� ��� �������
  @Get_info_class := GetProcAddress(ELibHandle, 'Get_info_class');
  @Get_Device_class := GetProcAddress(ELibHandle, 'Get_Device_class');
  @What_is := GetProcAddress(ELibHandle, 'What_is');
  if (not Assigned(Get_info_class)) or (not Assigned(Get_Device_class)) or
    (not Assigned(What_is)) then
  begin // ������ ������������� �����-������ �������
    lastErrCode := 4; // �� ������� ����� ������ � �����
    FreeLibrary(ELibHandle);
    exit;
  end;
  // 4. ��������, ������������ ��  ���� ������
  WI := What_is(DllVer);
  if (WI < 0) or (DllVer<>AppVersion4Dll) then
  begin // ������ �� ��������������
    lastErrCode := 3; // ������ �� ��������������
    FreeLibrary(ELibHandle);
    exit;
  end;
  // 5. ��������� ��������
  // if not assigned(AInfoDevice[high(AInfoDevice)]) then AInfoDevice[high(AInfoDevice)]:=TInfodevice.Create;
  // if not assigned(id2) then id2:=TInfodevice.Create;

  id2 := Get_info_class();
  HID := high(AInfoDevice);
  // ����������� �� id2 � AInfoDevice
  if not Assigned(AInfoDevice[HID]) then
    AInfoDevice[HID] := TInfoDevice.Create;

  AInfoDevice[HID].vType := id2.vType;
  AInfoDevice[HID].vSType := id2.vSType;
  AInfoDevice[HID].vSFamily := id2.vSFamily;
  SetLength(AInfoDevice[HID].vSModel, High(id2.vSModel) + 1);
  for iI := Low(id2.vSModel) to High(id2.vSModel) do
    AInfoDevice[HID].vSModel[iI] := id2.vSModel[iI];
  AInfoDevice[HID].vIcon := id2.vIcon;
  AInfoDevice[HID].evFileName := id2.evFileName;
  AInfoDevice[HID].evLoaded := id2.evLoaded;
  AInfoDevice[HID].vSDisplayName:=id2.vSDisplayName;
  // finalize(id2);
  id2.Free;

  AInfoDevice[high(AInfoDevice)].evFileName := fn;
  // LoadDevInfo:=id2; //id2;

  // Dispose(@id2);
  //
  // id2:=nil;
  LoadDevInfo := true;
  FreeLibrary(ELibHandle);

end;

// ��������� ������������� ����������� c ��������� ���� ���������
function FindAndLoadDevices(OutComponent: TMemo; Path: string): boolean;
var
  sda, sda2: TStringDynArray;
  I,HSDA: integer;
  Id: TInfoDevice;
  // b:boolean;
begin
  OutComponent.lines.add(GetText(2002));
  application.processmessages;
  sda := SearchFiles(Path, '*.atcdev', true);
  sda2 := SearchFiles(Path, '*.dll', true);
  OutComponent.lines.add(GetText(2003));
  application.processmessages;
  HSDA:=High(sda);
  for I := Low(sda) to HSDA  do
  begin
    SetLength(AInfoDevice, High(AInfoDevice) + 2);
    // �������� �� 1 ������ AINfoDevice

    // AInfoDevice[High(AInfoDevice)]:=TInfoDevice.Create;
    OutComponent.lines.add('[Loading]' + sda[I]);
    if LoadDevInfo(sda[I]) then
    begin
      OutComponent.lines.add('[Ok]' + sda[I]);
      application.processmessages;
      RemoveLastDevInfoIfIsAvailable; // ������ ���������
      // AddDevInfo(id);
    end
    else
    begin
      OutComponent.lines.add('[ER' + Inttostr(lastErrCode) + ']' + sda[I]);
      application.processmessages;
      RemoveLastDevInfoIfIsAvailable;
    end;
  end;

  for I := Low(sda2) to High(sda2) do
  begin

    SetLength(AInfoDevice, High(AInfoDevice) + 2);
    // �������� �� 1 ������ AINfoDevice
    OutComponent.lines.add('[Loading]' + sda2[I]);
    if LoadDevInfo(sda2[I]) then
    begin
      OutComponent.lines.add('[Ok]' + sda2[I]);
      application.processmessages;
      RemoveLastDevInfoIfIsAvailable; // ������ ���������
      // AddDevInfo(id);
    end
    else
    begin
      OutComponent.lines.add('[ER' + Inttostr(lastErrCode) + ']' + sda2[I]);
      application.processmessages;
      RemoveLastDevInfoIfIsAvailable;
    end;
  end;

end;

end.
