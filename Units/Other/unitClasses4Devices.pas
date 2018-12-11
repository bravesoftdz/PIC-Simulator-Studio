unit unitClasses4Devices;

// ���� � ��������� �������� ������� ��� ���������
interface

uses
  vcl.extctrls, // ��� ������� � TImage
  vcl.controls, // ��� ������� � TMouseButton
  winapi.windows, // ��� �������� ���� hicon
  system.classes, // ��� �������� ����� TPersistent
  math; // ��� NaN, IsNan

Type

  TResStack = array of boolean;

  TRCPort = class; // ����������� ���������� ������ TPort
  TDevice = class; // ����������� ���������� ������ TDevice
  TNode = class; // ����������� ���������� ������ TNode
  TRCPorts = array of TRCPort; // ��� - ����� (������ ������� ������)
  TDevices = array of TDevice; // ������ ���������
  TNodes = array of TNode; // ������ �����
  TArrayChar = array of ansichar;
  TAshortstrings = array of shortstring; // ������ ����� �����
  // Call-back ������
  TBackProcDraw = procedure(Sender: TObject; isRunning: boolean;
    RunningTime: Extended); stdcall; // ��������� ��������� ������ �����������
  TBackClick = procedure(Sender: TObject); stdcall;
  TBackShowSettings = procedure(Sender: TObject); stdcall;
  TBackApplySaveData = procedure(Sender: TObject); stdcall;
  TBackTact = procedure(Sender: TObject; Tact: Int64); stdcall;
  TBackMouseDown = procedure(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer); stdcall;
  TBackMouseMove = procedure(Sender: TObject; Shift: TShiftState;
    X, Y: Integer); stdcall;
  TBackMouseUp = procedure(Sender: TObject; Button: TMouseButton;
    Shift: TShiftState; X, Y: Integer); stdcall;
  TBackDblClick = procedure(Sender: TObject); stdcall;
  // ������� ��������� ������ ������ �������
  TBackProcGetLevel = function(Sender: TObject): single; stdcall;
  TGet_MCandCF = procedure(var vMC: Int64; var vCF: Integer); stdcall;

  // "�������" ����� - ���� node
  TNode = class sealed(TObject)
  private // ��� ���������� ����

  public // �����������, ����������, �������, ����������
    Ports: TRCPorts; // ������ ������ �� �����
  published // ��������, ������
    Function GetLevel(): single; stdcall;
  end;

  TInfoDevice = class sealed(TObject)
  public
    vType: byte; // ��� (����)
    vSType: shortstring; // ��� (�������) ?
    vSFamily: shortstring; // ��������� (�������)?
    vSModel: TAshortstrings; // TAshortstrings; //������ (�������)?
    vSDisplayName: shortstring; // ������������ ��� (�� ������)
    vIcon: hicon; // ������
    evFileName: shortstring; // ��� ����� � ���� � dll
    evLoaded: boolean; // ��������� �� � ������ dll-��
    evLibHandle: THandle; // ����� ����������� ����������
    // �������, �������������� �� dll-��
    Get_info_class: function(): TInfoDevice; stdcall;
    Get_Device_class: Function(HostHandle: THandle; MainDevice: TDevice)
      : TDevice; stdcall;
    What_is: Function(var version: shortstring): Integer; stdcall;
    // procedure AssignF(Source: TInfoDevice);
  end;

  TDevice = class sealed(TObject) // ��� - ����������� ��� ����������
  private
    fMainDevice: TDevice; // ������� ����������
    fDevType: byte;
    fRCType: shortstring;
    fRCFamily: shortstring;
    fRCModel: shortstring;
    fRCShowName: shortstring; // ���, ���. ������������ �� ������
    fPortsCount: Integer;
    fImage: TImage;
    fWidth: Integer;
    fHeight: Integer;
    fSaveData: TArrayChar;
    fHostHandle: THandle; // Application Handle ������� ���������
    fOrigHandle: THandle; // Application Handle Dll-��
    // ������ �� ���������
    fBackProcDraw: TBackProcDraw; // ��������� �����������
    fBackClick: TBackClick; // ��������� ����� � ���-����
    fBackMD: TBackMouseDown; // ��������� MouseDown in run-time
    fBackMM: TBackMouseMove; // ��������� MouseMove in run-time
    fBackMU: TBackMouseUp; // ��������� MouseDown in run-time
    fGet_MCandCF: TGet_MCandCF;
    fBackDblClick: TBackDblClick; // ��������� DblClick in run-time
    fBackShowSettings: TBackShowSettings; // ��������� ������ ��������
    fBackApplySaveData: TBackApplySaveData;
    // ���������, ���. ���������� ��� ��������� �������� ���������� (����� �������� �������)
    fBackTact: TBackTact;
    // ���������� �� ���������

    fAssignedBackClick: boolean; // ��������� ����� � ���-����
    fAssignedBackMD: boolean; // ��������� MouseDown in run-time
    fAssignedBackMM: boolean; // ��������� MouseMove in run-time
    fAssignedBackMU: boolean; // ��������� MouseDown in run-time
    fAssignedBackDblClick: boolean; // ��������� DblClick in run-time
    fAssignedShowSettings: boolean; // ��������� ������ ��������
    fAssignedBackTact: boolean; // ��������� ����� ����������������
    fAssignedGet_MCandCF: boolean;
    // ���������
    // Procedure ChangeSaveData(vSaveData:TArrayChar);
    Function GetLenSD: Integer;
    Procedure SetLenSD(val: Integer);

  public

    Port: TRCPorts; // ������ ������ ��� �������
    x_img_XX, x_img_YY: Integer; // ��� ����������� Img
    InternalIndex: Integer; // ���������� (������ dll) ������ �������
    Procedure AddPort(pPortName: shortstring; pDirection: byte;
      pDigital: boolean; pLevel: single; BackProcGetLevel: TBackProcGetLevel);
    Constructor Create(pInternalIndex: Integer; Width: Integer; Height: Integer;
      pDevType: byte; pRCType: shortstring; pRCFamily: shortstring;
      pRCModel: shortstring; pNumberOfPorts: Integer;
      BackProcDraw: TBackProcDraw; BackClick: TBackClick;
      BackMD: TBackMouseDown; BackMM: TBackMouseMove; BackMU: TBackMouseUp;
      BackDblClick: TBackDblClick; BackShowSettings: TBackShowSettings;
      BackApplySaveData: TBackApplySaveData; BackTact: TBackTact;
      OrigHandle: THandle; HostHandle: THandle; MainDevice: TDevice;
      Get_MCandCF: TGet_MCandCF);
    destructor Destroy;

  published
    // ��������
    property MainDevice: TDevice read fMainDevice;
    property DevType: byte read fDevType; // ��� ����
    property SaveData: TArrayChar read fSaveData write fSaveData;
    // ������, ��� ����������� ������ � ��������
    property LenSaveData: Integer read GetLenSD write SetLenSD;
    property RCType: shortstring read fRCType; // ��� �������
    property RCFamily: shortstring read fRCFamily; // ���������
    property RCModel: shortstring read fRCModel; // ������
    property RCShowName: shortstring read fRCShowName;
    // ���, ��� ������������ �� ������ (������� �� �����)
    Property PortsCount: Integer read fPortsCount; // ���������� ������
    Property Image: TImage read fImage write fImage;
    Property HostHandle: THandle read fHostHandle;
    // Application Handle ������� ���������
    Property OrigHandle: THandle read fOrigHandle; // Application Handle Dll-��
    // Image Box ��� ������ �����������
    Property Width: Integer read fWidth; // ������ ��������
    Property Height: Integer read fHeight; // ������ ��������
    // ���������� �� ���������
    Property AssignedBackClick: boolean read fAssignedBackClick;
    // ��������� ����� � ���-����
    Property AssignedBackMD: boolean read fAssignedBackMD;
    // ��������� MouseDown in run-time
    Property AssignedBackMM: boolean read fAssignedBackMM;
    // ��������� MouseMove in run-time
    Property AssignedBackMU: boolean read fAssignedBackMU;
    // ��������� MouseDown in run-time
    Property AssignedBackDblClick: boolean read fAssignedBackDblClick;
    // ��������� DblClick in run-time
    Property AssignedShowSettings: boolean read fAssignedShowSettings;
    // ��������� ������ ��������
    Property AssignedBackTact: boolean read fAssignedBackTact;
    // ��������� ��������� ������ � ������ ����� ��

    // ��������� ������ Call-Back
    Procedure Get_MCandCF(var vMC: Int64; var vCF: Integer); stdcall;
    Procedure DrawImage(isRunning: boolean; RunningTime: Extended);
    Procedure Click();
    Procedure DblClick();
    Procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer);
    Procedure MouseMove(Shift: TShiftState; X, Y: Integer);
    Procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    Procedure ShowSettings();
    Procedure ApplySettings();
    Procedure BackTact(Tact: Int64);

  end;

  TRCPort = class
  Private
    fPortName: shortstring; // �������� �����
    fDirection: byte; // ����������� 0 - �������� 1 - ����, 2 - �����, 3 - ���
    fDigital: boolean; // ��� ������� - 1 -�����  0 - ������
    fLevel: single; // ������� �������
    fBackProcGetLevel: TBackProcGetLevel;
    fDefaultLevel: single; // ������� ��� ������ ��-���������
    fPortNo: Integer; // ����� �����

    // function Get_PortName():shortstring;
  protected

  Public
    Node: TNode;
    Device: TDevice;
    constructor Create(pPortName: shortstring; pDirection: byte;
      pDigital: boolean; pLevel: single; BackProcGetLevel: TBackProcGetLevel;
      pPortNo: Integer);

  Published

    property PortName: shortstring // �������� �����
      read fPortName;
    property PortNo: Integer read fPortNo;
    Function GetLevel(): single;
  end;

Const
  AppVersion4Dll: shortstring = '1.0';



implementation

Constructor TDevice.Create(pInternalIndex: Integer; Width: Integer;
  Height: Integer; pDevType: byte; pRCType: shortstring; pRCFamily: shortstring;
  pRCModel: shortstring; pNumberOfPorts: Integer; BackProcDraw: TBackProcDraw;
  BackClick: TBackClick; BackMD: TBackMouseDown; BackMM: TBackMouseMove;
  BackMU: TBackMouseUp; BackDblClick: TBackDblClick;
  BackShowSettings: TBackShowSettings; BackApplySaveData: TBackApplySaveData;
  BackTact: TBackTact; OrigHandle: THandle; HostHandle: THandle;
  MainDevice: TDevice; Get_MCandCF: TGet_MCandCF);
begin
  // fRCShowName:=pRCShowName;

  fMainDevice := MainDevice;

  fOrigHandle := OrigHandle;
  fHostHandle := HostHandle;
  InternalIndex := pInternalIndex;
  if not assigned(BackClick) then
    fAssignedBackClick := false
  else
    fAssignedBackClick := true; // ��������� ����� � ���-����
  if not assigned(BackMD) then
    fAssignedBackMD := false
  else
    fAssignedBackMD := true; // ��������� MouseDown in run-time
  if not assigned(BackMM) then
    fAssignedBackMM := false
  else
    fAssignedBackMM := true; // ��������� MouseMove in run-time
  if not assigned(BackMU) then
    fAssignedBackMU := false
  else
    fAssignedBackMU := true; // ��������� MouseDown in run-time
  if not assigned(BackDblClick) then
    fAssignedBackDblClick := false
  else
    fAssignedBackDblClick := true; // ��������� DblClick in run-time
  if not assigned(BackShowSettings) then
    fAssignedShowSettings := false
  else
    fAssignedShowSettings := true; // ��������� ������ ��������
  if not assigned(BackTact) then
    fAssignedBackTact := false
  else
    fAssignedBackTact := true; // ���-��� �����
  if not assigned(Get_MCandCF) then
    fAssignedGet_MCandCF := false
  else
    fAssignedGet_MCandCF := true;

  fBackProcDraw := BackProcDraw;
  // if ((@BackProcDraw) <>Pointer(nil)) then fAssignedBackProcDraw:=true;

  fBackClick := BackClick;
  // if @BackClick<>nil then fAssignedBackClick:=true;

  fBackMD := BackMD;
  // if @BackMD<>nil then fAssignedBackMD:=true;

  fBackMM := BackMM;
  // if @BackMM<>nil then fAssignedBackMM:=true;

  fBackMU := BackMU;
  // if @BackMU<>nil then fAssignedBackMU:=true;

  fBackDblClick := BackDblClick;
  // if @BackDblClick<>nil then fAssignedBackDblClick:=true;   }

  fBackShowSettings := BackShowSettings;

  fBackApplySaveData := BackApplySaveData;

  fBackTact := BackTact;

  fGet_MCandCF := Get_MCandCF;

  fDevType := pDevType;
  fRCType := pRCType;
  fRCFamily := pRCFamily;
  fRCModel := pRCModel;
  fPortsCount := pNumberOfPorts;
  fWidth := Width;
  fHeight := Height;
  // SetLength(self.Port
  // Port := pPorts;

end;

Function TDevice.GetLenSD: Integer;
begin
  Result := High(fSaveData) + 1;
end;

Procedure TDevice.SetLenSD(val: Integer);
begin
  SetLength(fSaveData, val);
end;

Procedure TDevice.AddPort(pPortName: shortstring; pDirection: byte;
  pDigital: boolean; pLevel: single; BackProcGetLevel: TBackProcGetLevel);
begin
  SetLength(Self.Port, High(Self.Port) + 2);
  Self.Port[High(Self.Port)] := TRCPort.Create(pPortName, pDirection, pDigital,
    pLevel, BackProcGetLevel, High(Self.Port));
  Self.Port[High(Self.Port)].Device := Self;
end;

destructor TDevice.Destroy;
var
  I: Integer;
begin
  for I := 0 to fPortsCount - 1 do
    Port[I].Free;

  inherited;
end;

procedure TDevice.DrawImage(isRunning: boolean; RunningTime: Extended);
begin
  fBackProcDraw(Self, isRunning, RunningTime);
end;

Procedure TDevice.Get_MCandCF(var vMC: Int64; var vCF: Integer); stdcall;
begin
  if assigned(fMainDevice) then
    fMainDevice.fGet_MCandCF(vMC, vCF)
  else
  begin
    vMC := -1;
    vCF := -1;
  end;
end;

procedure TDevice.Click();
begin
  fBackClick(Self);
end;

procedure TDevice.ShowSettings();
begin
  fBackShowSettings(Self);
end;

Procedure TDevice.ApplySettings();
begin
  fBackApplySaveData(Self);
end;

procedure TDevice.DblClick();
begin
  fBackDblClick(Self);
end;

procedure TDevice.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  fBackMD(Self, Button, Shift, X, Y);
end;

procedure TDevice.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  fBackMM(Self, Shift, X, Y);
end;

procedure TDevice.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  fBackMU(Self, Button, Shift, X, Y);
end;

Procedure TDevice.BackTact(Tact: Int64);
begin
  fBackTact(Self, Tact);
end;

constructor TRCPort.Create(pPortName: shortstring; pDirection: byte;
  pDigital: boolean; pLevel: single; BackProcGetLevel: TBackProcGetLevel;
  pPortNo: Integer);

begin

  Self.fPortName := pPortName;
  Self.fDirection := pDirection;
  Self.fDigital := pDigital;
  Self.fDefaultLevel := pLevel;
  Self.fBackProcGetLevel := BackProcGetLevel;
  Self.fPortNo := pPortNo;
end;

Function TNode.GetLevel(): single; stdcall;

var
  I, vHigh: Integer;
  s, n: single;
  mn: Integer;
begin
  vHigh := High(Self.Ports);
  s := 0; // ������� ������� �� �������
  mn := 0; // ���������� ������ ��� �������
  for I := 0 to vHigh do
  begin
    if Self.Ports[I].fDirection < 2 then
      continue;
    n := Self.Ports[I].GetLevel();
    if isnan(n) then
      continue;
    s := s + n;
    mn := mn + 1;
  end;
  if mn = 0 then
    Result := NaN
  else
    Result := s / mn; // ���������, � ��� ����� ���� ���-� NaN

end;

Function TRCPort.GetLevel(): single;
begin
  Result := fBackProcGetLevel(Self);
end;

end.
