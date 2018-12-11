library mcPIC10F;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

{$R *.dres}

uses
  System.SysUtils,
  System.Classes,
  vcl.forms,
  Winapi.Windows,
  vcl.Graphics,
  ExtCtrls,
  mmsystem,
  Math,
  unitClasses4Devices in '..\..\..\Units\Other\unitClasses4Devices.pas',
  frmSettings in 'frmSettings.pas' {formSettings} ,
  UnitRes in 'UnitRes.pas';

// ������ �������� ������
Const
  // �umberOfPorts = 4; // ���������� ������ �� ����� ����������

  cDevType = 0; // ��� ������ ����������
  cSDevType: shortstring = 'Microchip PIC';
  cSDevFamily: shortstring = 'BASELINE';
  cSDevModel: array [0 .. 15] of shortstring = (('PIC10F200'), ('PIC10F202'),
    ('PIC10F204'), ('PIC10F206'), ('PIC10F220'), ('PIC10F222'), ('PIC12F508'),
    ('PIC12F509'), ('PIC12F510'), ('PIC12F519'), ('PIC16F505'), ('PIC16F506'),
    ('PIC16F526'), ('PIC16F54'), ('PIC16F57'), ('PIC16F59'));
  cHighLogicLevel: Single = 5;
  cLowLogicLevel: Single = 0;
  MinHighLevelVoltage: Single = 3;
  MaxHighLevelVoltage: Single = 5.5;
  MinLowLevelVoltage: Single = 0;
  MaxLowLevelVoltage: Single = 1;

  St2: array [0 .. 12] of integer = ((1), (2), (4), (8), (16), (32), (64),
    (128), (256), (512), (1024), (2048), (4096));

Var
  ResAlreadyLoaded: boolean = false;
  TD: TDevice; // ��������� ������ "���������"
  // TP: TRCPorts;// ��������� ������� "������"
  TID: TInfoDevice; // ��������� ������ "���������� � ����������"
  {
    procedure PCLpp();
    procedure resetRAM(Id:Byte);
    procedure SelectMC(Id:byte);
    function GetInstruction():String;
    function DimensionCPUCyclesPerSecond:int64;
    Function BinToHex():string;
    procedure ByteToBinInCD(X:Byte);
    Function BinToDec():integer;
    function ReadRAM(ByteNo:Integer; BitNo:Byte):boolean; }

TYPE
  TReturnNextMethod = PROCEDURE; stdcall; // Stop_simulation � Main

type
  TRun = class(TThread)
  public

  private
    // Private declarations
    // function ReadRAM(ByteNo:Integer; BitNo:Byte):boolean;
  protected
    procedure Execute; override;

  end;

type
  TMatrixRAM = record
    IDEaddres: integer;
    SIMadress: Word; // ����� ����������� �������������
    IDEName: String[16];
    IDEHexaddres: string[3];
    Used: boolean;
    SFR: boolean;
    VirtSFR: boolean;
    delta: boolean;
    greenDelta: boolean;
    // value: array[0..7] of boolean;
    deltabit: array [0 .. 7] of boolean; // ��� ����������(���)
    usedbit: array [0 .. 7] of boolean; // ����� ���� ������������
    bitname: array [0 .. 7] of string[8];
    ToClearDelta: boolean;
    BreakPoint: boolean;
    GreenBP: boolean;

  end;

type
  TSystemCommand = record
    CommandName: String[10];
  end;

type
  TConfigBits = record
    Name: string;
    DescriptionId: integer;
    No: integer;
    Value0Id: integer;
    Value1Id: integer;
  end;

const
  // ����� � RAM �������� INDF
  cMCU_regINDF = 0;
  // ����� � RAM �������� TMR0
  cMCU_regTMR0 = 1;
  // ����� � RAM �������� PCL
  cMCU_regPCL = 2;
  // ����� � RAM �������� STATUS
  cMCU_regSTATUS = 3;
  // ����� � RAM �������� FSR
  cMCU_regFSR = 4;
  // ����� �������� W � RAM
  cMCU_regW = 256;
  // ����� �������� OPTION � RAM
  cMCU_regOPTION = 257;
  // ����� � RAM �������� TRISGPIO
  cMCU_regTRISGPIO = 258;
  // ����� � RAM �������� TRISA
  cMCU_regTRISA = 259;
  // ����� � RAM �������� TRISA
  cMCU_regTRISB = 260;
  // ����� � RAM �������� TRISA
  cMCU_regTRISC = 261;
  // ����� � RAM �������� TRISA
  cMCU_regTRISD = 262;
  // ����� � RAM �������� TRISA
  cMCU_regTRISE = 263;
  // ����� � RAM �������� TMR0 Prescaler
  cMCU_regTMR0P = 264;
  AllRAMSize = 264; // ������ ������ RAM - GPR,SFR, ������� �����������

var

  Bmp200, Bmp200_free, Bmp202, Bmp202_free, Bmp204, Bmp204_free, Bmp206,
    Bmp206_free, Bmp220, Bmp220_free, Bmp222, Bmp222_free, Bmp508, Bmp508_free,
    Bmp509, Bmp509_free, Bmp510, Bmp510_free, Bmp519, Bmp519_free, Bmp505,
    Bmp505_free, Bmp506, Bmp506_free, Bmp526, Bmp526_free, Bmp54, Bmp54_free,
    Bmp57, Bmp57_free, Bmp59, Bmp59_free, Bmp_MCLR, Bmp_Fosc4, Bmp_T0CKI,
    Bmp_GP0, Bmp_GP1, Bmp_GP2, Bmp_GP3, Bmp_GP4, Bmp_GP5, Bmp_r0, Bmp_r1,
    bmp_r3, Bmp_In, Bmp_Out, Bmp_In2, Bmp_Out2, bmp_HiToLo, bmp_LoToHi,
    Bmp_CINn, Bmp_CINp, Bmp_cout, Bmp_minus, Bmp_V, bmp_0, bmp_1, bmp_2, bmp_3,
    bmp_4, bmp_5, bmp_6, bmp_7, bmp_8, bmp_9, bmp_dot, Bmp_AN0, Bmp_AN1,
    Bmp_CLKIN, Bmp_OSC1, Bmp_OSC2, bmp_RA0, bmp_RA1, bmp_RA2, bmp_RA3, bmp_RB0,
    bmp_RB1, bmp_RB2, bmp_RB3, bmp_RB4, bmp_RB5, bmp_RB6, bmp_RB7, bmp_RC0,
    bmp_RC1, bmp_RC2, bmp_RC3, bmp_RC4, bmp_RC5, bmp_RC6, bmp_RC7, bmp_RD0,
    bmp_RD1, bmp_RD2, bmp_RD3, bmp_RD4, bmp_RD5, bmp_RD6, bmp_RD7, bmp_RE4,
    bmp_RE5, bmp_RE6, bmp_RE7, bmp_C1INp, bmp_C1INn, bmp_AN2, bmp_C1OUT,
    bmp_CLKOUT, bmp_C2OUT, bmp_C2INp, bmp_C2INn, bmp_CVref, bmp_AN0C1INp,
    bmp_AN1C1INn: TBitmap;
  // �������� ��� PIC10F200
  CO: TRun;
  StopSimulation_METOD: pointer;
  // ���� ����������, ���������� �� ����� ������ ����������
  rtMCId: byte; // �� ����������������
  rtRunning: boolean; // � ������ �������� ��?
  rtStepByStep: boolean; // ��� �� �����?
  rtexStep: boolean; // ��������� ������� ���
  rtPause: boolean; // �����
  rtPaused: boolean=false; // ����� ��������� (����� ����������� � �����. �����)
  rtWithDelay: boolean; // � ���������
  rtDelayMS: integer; // ��������
  rtWithSyncro: boolean; // � �������������� � ��������� �������
  rtSyncro: real = 1; // ������ ����
  rtRefreshComplete: boolean = false; // ��� ������ � ��������� � ���� ��� ����

  rtSyncroTMP: int64;
  // ��������� ���� ��� ������������� (������������� ������ �������)

  rtCyclPerCycMK: int64;
  // ����, ������������, ������� ������ CPU � ����� ����� ��
  rtCrystalFreq: integer; // ������� �� � ������ ��

  // ����������, ���������� �� "������� ������"
  SystemCommand: array of TSystemCommand;
  SystemCommandCounter: integer;

  // �������� ����������, ���������� "������� �����" ���������
  I: integer;
  // ����������, ������� ����� �������� ��������� ������ ���� ��
  BackTactDevices: TDevices;
  // ���������� "��������� ��������� ��� �� ����� GPIO
  realGPIO: array [0 .. 7] of boolean;
  // ���������� � � ��-�� �, ����� ��� ���������� �������� ������� �� �����. ���������� � �����. ������
  realPA: array [0 .. 7] of boolean;
  realPB: array [0 .. 7] of boolean;
  realPC: array [0 .. 7] of boolean;
  realPD: array [0 .. 7] of boolean;
  realPE: array [0 .. 7] of boolean;
  // ����������, ������������� �� ����� "���";
  SleepMode: boolean;
  sleepRegGPIO: array [0 .. 7] of boolean;
  sleepCM: boolean;
  // ����� ����� ��������� ������ �������� GPIO �� ����� � ����� ���
  // �������� ����������, ��������� � ������ ��
  MatrixRAM: array [0 .. 265] of TMatrixRAM;
  // �������� ������� ��� �/� ���������� � IDE

  SFRCount: Word; // ���-�� SFR, ������� W � �����������
  GPRCount: Word; // ���-�� GPR
  ROM_Size: integer; // ������ ������ ROM
  // �������� ���
  ROM: array of array [0 .. 11] of boolean;
  ROM_Str_No: array of integer;
  ROM_Str_No_from: array of integer;
  ROM_Str_No_to: array of integer;
  ROM_BP: array of boolean; // ����� �������� ��� ���
  // ������� �������� �� ���
  CurrentCommand: array [0 .. 11] of boolean;

  // ����������� ����������, ������������ ������ ��
  cMCU_pcLen: integer; // ������ PC
  // ������� ���������
  cMCU_avGPIO: boolean; // ���� GPIO
  cMCU_hiGPIO: integer; // ������� ���� � GPIO
  cMCU_hiPORTA: integer; // ������� ���� � PORTA
  cMCU_hiPORTB: integer; // ������� ���� � PORTB
  cMCU_hiPORTC: integer; // ������� ���� � PORTC
  cMCU_hiPORTD: integer; // ������� ���� � PORTD
  cMCU_hiPORTE: integer; // ������� ���� � PORTE
  cMCU_avFosc4Out: boolean; // ����� Fosc/4
  { �MCU_PinCount:integer; //���-�� ������� �� ��
    �MCU_Pin_X:array[1..40] of integer; //����� ������� �� ��� X ��� ������ �� �������
    �MCU_Pin_Y:array[1..40] of integer; //����� ������� �� ��� X ��� ������ �� ������� }
  // ��������

  cMCU_regOSCCAL: integer; // ����� � RAM �������� OSCCAL
  cMCU_regGPIO: integer; // ����� � RAM �������� GPIO
  cMCU_regPORTA: integer; // ����� � RAM �������� PORTA
  cMCU_regPORTB: integer; // ����� � RAM �������� PORTB
  cMCU_regPORTC: integer; // ����� � RAM �������� PORTC
  cMCU_regPORTD: integer; // ����� � RAM �������� PORTD
  cMCU_regPORTE: integer; // ����� � RAM �������� PORTE
  // ����� � RAM �������� CMCON (������ ��� ��������� ������� � ������������)
  cMCU_regCMCON: integer;
  // ���
  cMCU_regADCON0: integer;
  cMCU_regADRES: integer;
  // EEPROM
  cMCU_regEECON: integer;
  cMCU_regEEDATA: integer;
  cMCU_regEEADR: integer;
  // ���� ������������
  cMCU_cfgWDTE: integer;
  cMCU_cfgMCLRE: integer;
  // �����
  cMCU_portT0CKI: integer; // ����� ����� T0CKI
  cMCU_portMCLR: integer; // ����� ����� MCLR
  // ��� ������������
  Config: array [0 .. 11] of boolean;
  ConfigBits: TArrayConfigBits;
  ConfigBitsCounter: integer;
  // ����������� ������, ������� GFR � SFR
  RAM: array [0 .. 264] of array [0 .. 7] of boolean;
  // Instruction Counter
  IC: int64;
  // Machine cycles
  MC: int64;
  // UserTimer
  UserTimer: Extended;
  // Stack
  stMax: byte;
  StC: byte;
  St: array [0 .. 1] of integer;
  bSt: array [0 .. 1] of array of boolean;
  PC: array of boolean;
  // ADC
  rtTaktsADC: integer;
  // WDT
  rtTaktsWDT: real; // ������� ������ �� ������
  TaktsWDT: real; // ������� ������ ������ ������
  rtKWDT: byte; // ���� ������� WDT
  // Timer0
  rtKTMR0: integer; // ���� �������  Timer0
  rtTMR0: integer; // ���������� �������, ��� ����� ������������
  // ����� � ������ � Ram, ������� ������ ����� ���� ��������
  ChangeAddr: Word;
  �hangeData: array [0 .. 7] of boolean;
  ChangeBitAddr: Word;
  ChangeBitNo: byte;
  ChangeBitData: boolean;
  ChangeDataNotInstruction: boolean;
  // ��� ���������
  ByteNo: integer;
  BitNo: byte;
  // ��������� �� �� ���������� �.�. �� �� BCF, MOVF � �.�., � �� �����. ����������
  // ��������, � ������� ����������� bin-������ ��� ��������������� � �� ��
  par: array [0 .. 8] of boolean;
  // �������� ������� �������� ��������, � ���. ���������� ��������, ���. ����� ������������
  parCommand: array [0 .. 11] of boolean;
  // ��������, � ���. ����� ����������� ������ �� ����� ������ ����� GOTO
  parGOTOaddr: integer;
  // ��������� (������������� ����������
  tempPCL: array [0 .. 7] of boolean;
{$R *.res}

Function BinToDec(): integer;
var
  res: integer;
begin
  res := 0;
  if par[0] then
    res := res + 1;
  if par[1] then
    res := res + 2;
  if par[2] then
    res := res + 4;
  if par[3] then
    res := res + 8;
  if par[4] then
    res := res + 16;
  if par[5] then
    res := res + 32;
  if par[6] then
    res := res + 64;
  if par[7] then
    res := res + 128;
  if par[8] then
    res := res + 256;
  result := res;
end;

Function BinToHex(): string;
var
  L, H: string[1];
begin
  // LOW
  if par[0] then
  begin // XXX1
    if par[1] then
    begin // XX11
      if par[2] then
      begin // X111
        if par[3] then // 1111
          L := 'F'
        else // 0111
          L := '7';
      end
      else
      begin // X011
        if par[3] then // 1011
          L := 'B'
        else // 0011
          L := '3';
      end;
    end
    else
    begin // XX01
      if par[2] then
      begin // X101
        if par[3] then // 1101
          L := 'D'
        else // 0101
          L := '5';
      end
      else
      begin // X001
        if par[3] then // 1001
          L := '9'
        else // 0001
          L := '1';
      end;
    end;
  end
  else
  begin // XXX0
    if par[1] then
    begin // XX10
      if par[2] then
      begin // X110
        if par[3] then // 1110
          L := 'E'
        else // 0110
          L := '6';
      end
      else
      begin // X010
        if par[3] then // 1010
          L := 'A'
        else // 0010
          L := '2';
      end;
    end
    else
    begin // XX00
      if par[2] then
      begin // X100
        if par[3] then // 1100
          L := 'C'
        else // 0100
          L := '4';
      end
      else
      begin // X000
        if par[3] then // 1000
          L := '8'
        else // 0000
          L := '0';
      end;
    end;
  end;

  // HIGHT

  if par[4] then
  begin // XXX1
    if par[5] then
    begin // XX11
      if par[6] then
      begin // X111
        if par[7] then // 1111
          H := 'F'
        else // 0111
          H := '7';
      end
      else
      begin // X011
        if par[7] then // 1011
          H := 'B'
        else // 0011
          H := '3';
      end;
    end
    else
    begin // XX01
      if par[6] then
      begin // X101
        if par[7] then // 1101
          H := 'D'
        else // 0101
          H := '5';
      end
      else
      begin // X001
        if par[7] then // 1001
          H := '9'
        else // 0001
          H := '1';
      end;
    end;
  end
  else
  begin // XXX0
    if par[5] then
    begin // XX10
      if par[6] then
      begin // X110
        if par[7] then // 1110
          H := 'E'
        else // 0110
          H := '6';
      end
      else
      begin // X010
        if par[7] then // 1010
          H := 'A'
        else // 0010
          H := '2';
      end;
    end
    else
    begin // XX00
      if par[6] then
      begin // X100
        if par[7] then // 1100
          H := 'C'
        else // 0100
          H := '4';
      end
      else
      begin // X000
        if par[7] then // 1000
          H := '8'
        else // 0000
          H := '0';
      end;
    end;
  end;
  if par[8] then
    result := '1' + H + L
  else
    result := H + L;
end;

function GetInstruction(): shortstring; stdcall;
var
  tmpByte1: byte;
begin
  //

  if parCommand[11] then // 1XXXXXXXXXXX
  begin
    if parCommand[10] then // 11XXXXXXXXXX
    begin
      if parCommand[9] then // 111XXXXXXXXX
      begin
        if parCommand[8] then // 1111XXXXXXXX
        begin
          // XORLW k(8)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := parCommand[5];
          par[6] := parCommand[6];
          par[7] := parCommand[7];
          par[8] := false;
          result := 'XORLW ' + BinToHex() + 'h';
        end
        else // 1110XXXXXXXX
        begin
          // ANDLW k(8)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := parCommand[5];
          par[6] := parCommand[6];
          par[7] := parCommand[7];
          par[8] := false;
          result := 'ANDLW ' + BinToHex() + 'h';
        end;
      end
      else // 110XXXXXXXXX
      begin
        if parCommand[8] then // 1101XXXXXXXX
        begin
          // IORLW k(8)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := parCommand[5];
          par[6] := parCommand[6];
          par[7] := parCommand[7];
          par[8] := false;
          result := 'IORLW ' + BinToHex() + 'h';
        end
        else // 1100XXXXXXXX
        begin
          // MOVLW k(8)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := parCommand[5];
          par[6] := parCommand[6];
          par[7] := parCommand[7];
          par[8] := false;
          result := 'MOVLW ' + BinToHex() + 'h';
        end;
      end;
    end
    else // 10XXXXXXXXXX
      if parCommand[9] then // 101XXXXXXXXX
      begin
        // GOTO k(9)
        par[0] := parCommand[0];
        par[1] := parCommand[1];
        par[2] := parCommand[2];
        par[3] := parCommand[3];
        par[4] := parCommand[4];
        par[5] := parCommand[5];
        par[6] := parCommand[6];
        par[7] := parCommand[7];
        par[8] := parCommand[8];
        parGOTOaddr := BinToDec();
        result := 'GOTO ' + BinToHex() + 'h';

      end
      else // 100XXXXXXXXX
      begin
        if parCommand[8] then // 1001XXXXXXXX
        begin
          // CALL k(8)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := parCommand[5];
          par[6] := parCommand[6];
          par[7] := parCommand[7];
          par[8] := false;
          parGOTOaddr := BinToDec();
          result := 'CALL ' + BinToHex() + 'h';
        end
        else
        begin // 1000XXXXXXXX
          // RETLW k(8)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := parCommand[5];
          par[6] := parCommand[6];
          par[7] := parCommand[7];
          par[8] := false;
          result := 'RETLW ' + BinToHex() + 'h';
        end;
      end;
  end
  else
  begin // 0XXXXXXXXXXX
    if parCommand[10] then
    begin // 01XXXXXXXXXX
      if parCommand[9] then
      begin // 011XXXXXXXXX
        if parCommand[8] then
        begin // 0111XXXXXXXX
          // BTFSS f(5),b(3)  0111bbbfffff
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := false;
          par[6] := false;
          par[7] := false;
          par[8] := false;
          tmpByte1 := 0;
          if parCommand[5] then
            tmpByte1 := tmpByte1 + 1;
          if parCommand[6] then
            tmpByte1 := tmpByte1 + 2;
          if parCommand[7] then
            tmpByte1 := tmpByte1 + 4;

          result := 'BTFSS ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end
        else
        begin // 0110XXXXXXXX
          // BTFSC f(5),b(3)  0110bbbfffff
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := false;
          par[6] := false;
          par[7] := false;
          par[8] := false;
          tmpByte1 := 0;
          if parCommand[5] then
            tmpByte1 := tmpByte1 + 1;
          if parCommand[6] then
            tmpByte1 := tmpByte1 + 2;
          if parCommand[7] then
            tmpByte1 := tmpByte1 + 4;

          result := 'BTFSC ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end;
      end
      else
      begin // 010XXXXXXXXX
        if parCommand[8] then
        begin // 0101XXXXXXXX
          // BSF  f(5),b(3)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := false;
          par[6] := false;
          par[7] := false;
          par[8] := false;
          tmpByte1 := 0;
          if parCommand[5] then
            tmpByte1 := tmpByte1 + 1;
          if parCommand[6] then
            tmpByte1 := tmpByte1 + 2;
          if parCommand[7] then
            tmpByte1 := tmpByte1 + 4;

          result := 'BSF ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end
        else
        begin // 0100XXXXXXXX
          // BCF  f(5),b(3)
          par[0] := parCommand[0];
          par[1] := parCommand[1];
          par[2] := parCommand[2];
          par[3] := parCommand[3];
          par[4] := parCommand[4];
          par[5] := false;
          par[6] := false;
          par[7] := false;
          par[8] := false;
          tmpByte1 := 0;
          if parCommand[5] then
            tmpByte1 := tmpByte1 + 1;
          if parCommand[6] then
            tmpByte1 := tmpByte1 + 2;
          if parCommand[7] then
            tmpByte1 := tmpByte1 + 4;

          result := 'BCF ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end;
      end;
    end
    else
    begin // 00XXXXXXXXXX
      if parCommand[9] then
      begin // 001XXXXXXXXX
        if parCommand[8] then
        begin // 0011XXXXXXXX
          if parCommand[7] then
          begin // 00111XXXXXXX
            if parCommand[6] then
            begin // 001111XXXXXX
              // INCFSZ f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'INCFSZ ' + BinToHex() + 'h, f'
              else
                result := 'INCFSZ ' + BinToHex() + 'h, W';

            end
            else
            begin // 001110XXXXXX
              // SWAPF f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'SWAPF ' + BinToHex() + 'h, f'
              else
                result := 'SWAPF ' + BinToHex() + 'h, W';
            end;

          end
          else
          begin // 00110XXXXXXX
            if parCommand[6] then
            begin // 001101XXXXXX
              // RLF f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'RLF ' + BinToHex() + 'h, f'
              else
                result := 'RLF ' + BinToHex() + 'h, W';

            end
            else
            begin // 001100XXXXXX
              // RRF f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'RRF ' + BinToHex() + 'h, f'
              else
                result := 'RRF ' + BinToHex() + 'h, W';

            end;
          end;

        end
        else
        begin // 0010XXXXXXXX
          if parCommand[7] then
          begin // 00101XXXXXXX
            if parCommand[6] then
            begin // 001011XXXXXX
              // DECFSZ  f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'DECFSZ ' + BinToHex() + 'h, f'
              else
                result := 'DECFSZ ' + BinToHex() + 'h, W';

            end
            else
            begin // 001010XXXXXX
              // INCF f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'INCF ' + BinToHex() + 'h, f'
              else
                result := 'INCF ' + BinToHex() + 'h, W';

            end
          end
          else
          begin // 00100XXXXXXX
            if parCommand[6] then
            begin // 001001XXXXXX
              // COMF f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'COMF ' + BinToHex() + 'h, f'
              else
                result := 'COMF ' + BinToHex() + 'h, W';

            end
            else
            begin // 001000XXXXXX
              // MOVF f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'MOVF ' + BinToHex() + 'h, f'
              else
                result := 'MOVF ' + BinToHex() + 'h, W';

            end;
          end;
        end;

      end
      else
      begin // 000XXXXXXXXX
        if parCommand[8] then
        begin // 0001XXXXXXXX
          if parCommand[7] then
          begin // 00011XXXXXXX
            if parCommand[6] then
            begin // 000111XXXXXX
              // ADDWF f(5),d(1)  - ��� ���� �������� ��������� W � f
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'ADDWF ' + BinToHex() + 'h, f'
              else
                result := 'ADDWF ' + BinToHex() + 'h, W';
            end
            else
            begin // 000110XXXXXX
              // XORWF  f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'XORWF ' + BinToHex() + 'h, f'
              else
                result := 'XORWF ' + BinToHex() + 'h, W';
            end;
          end
          else
          begin // 00010XXXXXXX
            if parCommand[6] then
            begin // 000101XXXXXX
              // ANDWF  f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'ANDWF ' + BinToHex() + 'h, f'
              else
                result := 'ANDWF ' + BinToHex() + 'h, W';
            end
            else
            begin // 000100XXXXXX
              // IORWF f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'IORWF ' + BinToHex() + 'h, f'
              else
                result := 'IORWF ' + BinToHex() + 'h, W';
            end;
          end;

        end
        else
        begin // 0000XXXXXXXX
          if parCommand[7] then
          begin // 00001XXXXXXX
            if parCommand[6] then
            begin // 000011XXXXXX
              // DECF  f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'DECF ' + BinToHex() + 'h, f'
              else
                result := 'DECF ' + BinToHex() + 'h, W';

            end
            else
            begin // 000010XXXXXX
              // SUBWF     f(5),d(1)
              par[0] := parCommand[0];
              par[1] := parCommand[1];
              par[2] := parCommand[2];
              par[3] := parCommand[3];
              par[4] := parCommand[4];
              par[5] := false;
              par[6] := false;
              par[7] := false;
              par[8] := false;
              if parCommand[5] then
                result := 'SUBWF ' + BinToHex() + 'h, f'
              else
                result := 'SUBWF ' + BinToHex() + 'h, W';
            end;

          end
          else
          begin // 00000XXXXXXX
            if parCommand[6] then
            begin // 000001XXXXXX
              if parCommand[5] then
              begin // 0000011XXXXX
                // CLRF     f(5)
                par[0] := parCommand[0];
                par[1] := parCommand[1];
                par[2] := parCommand[2];
                par[3] := parCommand[3];
                par[4] := parCommand[4];
                par[5] := false;
                par[6] := false;
                par[7] := false;
                par[8] := false;
                result := 'CLRF ' + BinToHex() + 'h';
              end
              else
              begin // 0000010XXXXX
                // CLRW
                result := 'CLRW'
              end;
            end
            else
            begin // 000000XXXXXX
              if parCommand[5] then
              begin // 0000001XXXXX
                // MOVWF    f(5)
                par[0] := parCommand[0];
                par[1] := parCommand[1];
                par[2] := parCommand[2];
                par[3] := parCommand[3];
                par[4] := parCommand[4];
                par[5] := false;
                par[6] := false;
                par[7] := false;
                par[8] := false;
                result := 'MOVWF ' + BinToHex() + 'h';
              end
              else
              begin // 0000000XXXXX
                if parCommand[4] then
                begin // 00000001XXXX
                  // Unknow command
                  result := 'unknown';
                end
                else
                begin // 00000000XXXX
                  if parCommand[3] then
                  begin // 000000001XXX
                    if parCommand[2] then
                    begin // 0000000011XX
                      // Unknow command
                      result := 'unknown';
                    end
                    else if parCommand[1] then
                    begin // 00000000101X
                      // Unknow command
                      result := 'unknown';
                    end
                    else if parCommand[0] then
                    begin
                      result := 'TRIS 9';
                    end
                    else
                    begin
                      result := 'TRIS 8';
                    end;
                  end
                  else
                  begin // 000000000XXX
                    if parCommand[2] then
                    begin // 0000000001XX
                      if parCommand[1] then
                      begin // 00000000011X
                        if parCommand[0] then
                        begin // 000000000111
                          // !TRIS 7  - PORT?    //Unknow command
                          result := 'TRIS 7';
                        end
                        else
                        begin // 000000000110
                          // aTRIS 6
                          result := 'TRIS 6';
                        end;
                      end
                      else
                      begin // 00000000010X
                        if parCommand[0] then
                        begin // 000000000101
                          // !TRIS 5 - PORT?    //Unknow command
                          result := 'TRIS 5';
                        end
                        else
                        begin // 000000000100
                          // !CLRWDT
                          result := 'CLRWDT';
                        end;

                      end;

                    end
                    else
                    begin // 0000000000XX
                      if parCommand[1] then
                      begin // 00000000001X
                        if parCommand[0] then
                        Begin // 000000000011
                          // !Sleep
                          result := 'SLEEP';
                        End
                        else
                        begin // 000000000010
                          // aOPTION
                          result := 'OPTION';

                        end;

                      end
                      else
                      begin // 00000000000X
                        if parCommand[0] then
                        Begin // 000000000001
                          // Unknow command
                          result := 'unknown';
                        End
                        else
                        begin // 000000000000
                          // aNOP
                          result := 'NOP';

                        end;
                      end;
                    end;
                  end;

                end;

              end;
            end;
          end;

        end;
      end;
    end;
  end;
end;

function DecTo3Hex(Dec: cardinal): string;
var
  j: cardinal;
  a, b, c: byte;
  res: string;
begin
  a := 0;
  b := 0;
  c := 0;
  res := '';
  for j := 1 to Dec do
  begin
    a := a + 1;
    if a = 16 then
    begin
      a := 0;
      b := b + 1;
      if b = 16 then
      begin
        b := 0;
        c := c + 1;
      end;
    end;
  end;

  if c = 0 then
    res := res + '0';
  if c = 1 then
    res := res + '1';
  if c = 2 then
    res := res + '2';
  if c = 3 then
    res := res + '3';
  if c = 4 then
    res := res + '4';
  if c = 5 then
    res := res + '5';
  if c = 6 then
    res := res + '6';
  if c = 7 then
    res := res + '7';
  if c = 8 then
    res := res + '8';
  if c = 9 then
    res := res + '9';
  if c = 10 then
    res := res + 'A';
  if c = 11 then
    res := res + 'B';
  if c = 12 then
    res := res + 'C';
  if c = 13 then
    res := res + 'D';
  if c = 14 then
    res := res + 'E';
  if c = 15 then
    res := res + 'F';

  if b = 0 then
    res := res + '0';
  if b = 1 then
    res := res + '1';
  if b = 2 then
    res := res + '2';
  if b = 3 then
    res := res + '3';
  if b = 4 then
    res := res + '4';
  if b = 5 then
    res := res + '5';
  if b = 6 then
    res := res + '6';
  if b = 7 then
    res := res + '7';
  if b = 8 then
    res := res + '8';
  if b = 9 then
    res := res + '9';
  if b = 10 then
    res := res + 'A';
  if b = 11 then
    res := res + 'B';
  if b = 12 then
    res := res + 'C';
  if b = 13 then
    res := res + 'D';
  if b = 14 then
    res := res + 'E';
  if b = 15 then
    res := res + 'F';

  if a = 0 then
    res := res + '0';
  if a = 1 then
    res := res + '1';
  if a = 2 then
    res := res + '2';
  if a = 3 then
    res := res + '3';
  if a = 4 then
    res := res + '4';
  if a = 5 then
    res := res + '5';
  if a = 6 then
    res := res + '6';
  if a = 7 then
    res := res + '7';
  if a = 8 then
    res := res + '8';
  if a = 9 then
    res := res + '9';
  if a = 10 then
    res := res + 'A';
  if a = 11 then
    res := res + 'B';
  if a = 12 then
    res := res + 'C';
  if a = 13 then
    res := res + 'D';
  if a = 14 then
    res := res + 'E';
  if a = 15 then
    res := res + 'F';
  DecTo3Hex := res;
end;

Function GetXValue(): boolean;
begin
  case TD.SaveData[22] of
    '0':
      begin
        result := false;
      end;
    '1':
      begin
        result := true;
      end;
  else
    if random(2) = 1 then
      result := true
    else
      result := false;

  end;

end;

procedure POR();

// ����� ��������� ������������� RAM �� ����� ������ POR
Var
  Z: Word;
  j: byte;
begin
  // ������� ���� ����������� ������ GPR � SFR
  for Z := 0 to AllRAMSize do
    for j := 0 to 7 do
    begin
      RAM[Z, j] := false;
    end;

  case rtMCId of
    0:
{$REGION 'POR for PIC10F200'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 00-1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO ---- xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := false;
        RAM[cMCU_regGPIO, 4] := false;
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� GPR xxxx xxxx
        for Z := 16 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO ---- 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
      end;
{$ENDREGION}
    1:
{$REGION 'POR for PIC10F202'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 00-1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO ---- xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := false;
        RAM[cMCU_regGPIO, 4] := false;
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� GPR xxxx xxxx
        for Z := 8 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO ---- 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
      end;
{$ENDREGION}
    2:
{$REGION 'POR for PIC10F204'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 00-1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO ---- xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := false;
        RAM[cMCU_regGPIO, 4] := false;
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� CMCON 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regCMCON, j] := true;
        // ��������� GPR xxxx xxxx
        for Z := 16 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO ---- 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
      end;
{$ENDREGION}
    3:
{$REGION 'POR for PIC10F206'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 00-1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO ---- xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := false;
        RAM[cMCU_regGPIO, 4] := false;
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� CMCON 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regCMCON, j] := true;
        // ��������� GPR xxxx xxxx
        for Z := 8 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO ---- 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
      end;

{$ENDREGION}
    4:
{$REGION 'POR for PIC10F220'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0--1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO ---- xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := false;
        RAM[cMCU_regGPIO, 4] := false;
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� ADCON0 11-- 1100
        RAM[cMCU_regADCON0, 7] := true;
        RAM[cMCU_regADCON0, 6] := true;
        RAM[cMCU_regADCON0, 5] := false;
        RAM[cMCU_regADCON0, 4] := false;
        RAM[cMCU_regADCON0, 3] := true;
        RAM[cMCU_regADCON0, 2] := true;
        RAM[cMCU_regADCON0, 1] := false;
        RAM[cMCU_regADCON0, 0] := false;
        // ��������� ADRES xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regADRES, j] := GetXValue();

        // ��������� GPR xxxx xxxx
        for Z := 16 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO ---- 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
      end;

{$ENDREGION}
    5:
{$REGION 'POR for PIC10F222'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0--1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO ---- xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := false;
        RAM[cMCU_regGPIO, 4] := false;
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� ADCON0 11-- 1100
        RAM[cMCU_regADCON0, 7] := true;
        RAM[cMCU_regADCON0, 6] := true;
        RAM[cMCU_regADCON0, 5] := false;
        RAM[cMCU_regADCON0, 4] := false;
        RAM[cMCU_regADCON0, 3] := true;
        RAM[cMCU_regADCON0, 2] := true;
        RAM[cMCU_regADCON0, 1] := false;
        RAM[cMCU_regADCON0, 0] := false;
        // ��������� ADRES xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regADRES, j] := GetXValue();

        // ��������� GPR xxxx xxxx
        for Z := 9 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO ---- 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
      end;

{$ENDREGION}
    6:
{$REGION 'POR for PIC12F508'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0--1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO --�� xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := GetXValue();
        RAM[cMCU_regGPIO, 4] := GetXValue();
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();

        // ��������� GPR xxxx xxxx
        for Z := 7 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO --11 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
        RAM[cMCU_regTRISGPIO, 4] := true;
        RAM[cMCU_regTRISGPIO, 5] := true;
      end;

{$ENDREGION}
    7:
{$REGION 'POR for PIC12F509'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0--1 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 110x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := false;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO --�� xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := GetXValue();
        RAM[cMCU_regGPIO, 4] := GetXValue();
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();

        // ��������� GPR xxxx xxxx
        for Z := 7 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        for Z := 48 to 63 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO --11 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
        RAM[cMCU_regTRISGPIO, 4] := true;
        RAM[cMCU_regTRISGPIO, 5] := true;
      end;

{$ENDREGION}
    8:
{$REGION 'POR for PIC12F510'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0001 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 110x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := false;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO --�� xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := GetXValue();
        RAM[cMCU_regGPIO, 4] := GetXValue();
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� CM1CON 1111 1111
        RAM[cMCU_regCMCON, 7] := true;
        RAM[cMCU_regCMCON, 6] := true;
        RAM[cMCU_regCMCON, 5] := true;
        RAM[cMCU_regCMCON, 4] := true;
        RAM[cMCU_regCMCON, 3] := true;
        RAM[cMCU_regCMCON, 2] := true;
        RAM[cMCU_regCMCON, 1] := true;
        RAM[cMCU_regCMCON, 0] := true;
        // ��������� ADCON0 1111 1100
        RAM[cMCU_regADCON0, 7] := true;
        RAM[cMCU_regADCON0, 6] := true;
        RAM[cMCU_regADCON0, 5] := true;
        RAM[cMCU_regADCON0, 4] := true;
        RAM[cMCU_regADCON0, 3] := true;
        RAM[cMCU_regADCON0, 2] := true;
        RAM[cMCU_regADCON0, 1] := false;
        RAM[cMCU_regADCON0, 0] := false;
        // ��������� ADRES xxxx xxxx
        RAM[cMCU_regADRES, 7] := GetXValue();
        RAM[cMCU_regADRES, 6] := GetXValue();
        RAM[cMCU_regADRES, 5] := GetXValue();
        RAM[cMCU_regADRES, 4] := GetXValue();
        RAM[cMCU_regADRES, 3] := GetXValue();
        RAM[cMCU_regADRES, 2] := GetXValue();
        RAM[cMCU_regADRES, 1] := GetXValue();
        RAM[cMCU_regADRES, 0] := GetXValue();
        // ��������� GPR xxxx xxxx
        for Z := 10 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        for Z := 48 to 63 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO --11 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
        RAM[cMCU_regTRISGPIO, 4] := true;
        RAM[cMCU_regTRISGPIO, 5] := true;
      end;

{$ENDREGION}
    9:

{$REGION 'POR for PIC12F519'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0001 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 110x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := false;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();
        // ��������� OSCCAL 1111 1110
        RAM[cMCU_regOSCCAL, 7] := true;
        RAM[cMCU_regOSCCAL, 6] := true;
        RAM[cMCU_regOSCCAL, 5] := true;
        RAM[cMCU_regOSCCAL, 4] := true;
        RAM[cMCU_regOSCCAL, 3] := true;
        RAM[cMCU_regOSCCAL, 2] := true;
        RAM[cMCU_regOSCCAL, 1] := true;
        RAM[cMCU_regOSCCAL, 0] := false;
        // ��������� GPIO --�� xxxx
        RAM[cMCU_regGPIO, 7] := false;
        RAM[cMCU_regGPIO, 6] := false;
        RAM[cMCU_regGPIO, 5] := GetXValue();
        RAM[cMCU_regGPIO, 4] := GetXValue();
        RAM[cMCU_regGPIO, 3] := GetXValue();
        RAM[cMCU_regGPIO, 2] := GetXValue();
        RAM[cMCU_regGPIO, 1] := GetXValue();
        RAM[cMCU_regGPIO, 0] := GetXValue();
        // ��������� EECON ---0 x000
        RAM[cMCU_regEECON, 7] := false;
        RAM[cMCU_regEECON, 6] := false;
        RAM[cMCU_regEECON, 5] := false;
        RAM[cMCU_regEECON, 4] := false;
        RAM[cMCU_regEECON, 3] := GetXValue();
        RAM[cMCU_regEECON, 2] := false;
        RAM[cMCU_regEECON, 1] := false;
        RAM[cMCU_regEECON, 0] := false;
        // ��������� EEDATA xxxx xxxx
        RAM[cMCU_regEEDATA, 7] := GetXValue();
        RAM[cMCU_regEEDATA, 6] := GetXValue();
        RAM[cMCU_regEEDATA, 5] := GetXValue();
        RAM[cMCU_regEEDATA, 4] := GetXValue();
        RAM[cMCU_regEEDATA, 3] := GetXValue();
        RAM[cMCU_regEEDATA, 2] := GetXValue();
        RAM[cMCU_regEEDATA, 1] := GetXValue();
        RAM[cMCU_regEEDATA, 0] := GetXValue();
        // ��������� EEADR --xx xxxx
        RAM[cMCU_regADRES, 7] := false;
        RAM[cMCU_regADRES, 6] := false;
        RAM[cMCU_regADRES, 5] := GetXValue();
        RAM[cMCU_regADRES, 4] := GetXValue();
        RAM[cMCU_regADRES, 3] := GetXValue();
        RAM[cMCU_regADRES, 2] := GetXValue();
        RAM[cMCU_regADRES, 1] := GetXValue();
        RAM[cMCU_regADRES, 0] := GetXValue();
        // ��������� GPR xxxx xxxx
        for Z := 7 to 31 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        for Z := 48 to 63 do
          for j := 0 to 7 do
            RAM[Z, j] := GetXValue();
        // ��������� OPTION 1111 1111
        RAM[cMCU_regOPTION, 7] := true;
        RAM[cMCU_regOPTION, 6] := true;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISGPIO --11 1111
        RAM[cMCU_regTRISGPIO, 0] := true;
        RAM[cMCU_regTRISGPIO, 1] := true;
        RAM[cMCU_regTRISGPIO, 2] := true;
        RAM[cMCU_regTRISGPIO, 3] := true;
        RAM[cMCU_regTRISGPIO, 4] := true;
        RAM[cMCU_regTRISGPIO, 5] := true;
      end;

{$ENDREGION}
    13:
{$REGION 'POR for PIC16F54'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0001 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 111x xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := true;
        RAM[cMCU_regFSR, 5] := true;
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();

        // ��������� PORTA ---- xxxx
        RAM[cMCU_regPORTA, 7] := false;
        RAM[cMCU_regPORTA, 6] := false;
        RAM[cMCU_regPORTA, 5] := false;
        RAM[cMCU_regPORTA, 4] := false;
        RAM[cMCU_regPORTA, 3] := GetXValue();
        RAM[cMCU_regPORTA, 2] := GetXValue();
        RAM[cMCU_regPORTA, 1] := GetXValue();
        RAM[cMCU_regPORTA, 0] := GetXValue();
        // ��������� PORTB xxxx xxxx
        RAM[cMCU_regPORTB, 7] := GetXValue();
        RAM[cMCU_regPORTB, 6] := GetXValue();
        RAM[cMCU_regPORTB, 5] := GetXValue();
        RAM[cMCU_regPORTB, 4] := GetXValue();
        RAM[cMCU_regPORTB, 3] := GetXValue();
        RAM[cMCU_regPORTB, 2] := GetXValue();
        RAM[cMCU_regPORTB, 1] := GetXValue();
        RAM[cMCU_regPORTB, 0] := GetXValue();
        // ��������� GPR xxxx xxxx
        for Z := 1 to 255 do
          if (MatrixRAM[Z].Used = true) and (MatrixRAM[Z].SFR = false) then
            for j := 0 to 7 do
              RAM[Z, j] := GetXValue();

        // ��������� OPTION --11 1111
        RAM[cMCU_regOPTION, 7] := false;
        RAM[cMCU_regOPTION, 6] := false;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISA ---- 1111
        RAM[cMCU_regTRISA, 0] := true;
        RAM[cMCU_regTRISA, 1] := true;
        RAM[cMCU_regTRISA, 2] := true;
        RAM[cMCU_regTRISA, 3] := true;
        // ��������� TRISB 1111 1111
        RAM[cMCU_regTRISB, 0] := true;
        RAM[cMCU_regTRISB, 1] := true;
        RAM[cMCU_regTRISB, 2] := true;
        RAM[cMCU_regTRISB, 3] := true;
        RAM[cMCU_regTRISB, 4] := true;
        RAM[cMCU_regTRISB, 5] := true;
        RAM[cMCU_regTRISB, 6] := true;
        RAM[cMCU_regTRISB, 7] := true;

      end;

{$ENDREGION}
    14:
{$REGION 'POR for PIC16F57'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0001 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 1xxx xxxx
        RAM[cMCU_regFSR, 7] := true;
        RAM[cMCU_regFSR, 6] := GetXValue();
        RAM[cMCU_regFSR, 5] := GetXValue();
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();

        // ��������� PORTA ---- xxxx
        RAM[cMCU_regPORTA, 7] := false;
        RAM[cMCU_regPORTA, 6] := false;
        RAM[cMCU_regPORTA, 5] := false;
        RAM[cMCU_regPORTA, 4] := false;
        RAM[cMCU_regPORTA, 3] := GetXValue();
        RAM[cMCU_regPORTA, 2] := GetXValue();
        RAM[cMCU_regPORTA, 1] := GetXValue();
        RAM[cMCU_regPORTA, 0] := GetXValue();
        // ��������� PORTB xxxx xxxx
        RAM[cMCU_regPORTB, 7] := GetXValue();
        RAM[cMCU_regPORTB, 6] := GetXValue();
        RAM[cMCU_regPORTB, 5] := GetXValue();
        RAM[cMCU_regPORTB, 4] := GetXValue();
        RAM[cMCU_regPORTB, 3] := GetXValue();
        RAM[cMCU_regPORTB, 2] := GetXValue();
        RAM[cMCU_regPORTB, 1] := GetXValue();
        RAM[cMCU_regPORTB, 0] := GetXValue();
        // ��������� PORTC xxxx xxxx
        RAM[cMCU_regPORTC, 7] := GetXValue();
        RAM[cMCU_regPORTC, 6] := GetXValue();
        RAM[cMCU_regPORTC, 5] := GetXValue();
        RAM[cMCU_regPORTC, 4] := GetXValue();
        RAM[cMCU_regPORTC, 3] := GetXValue();
        RAM[cMCU_regPORTC, 2] := GetXValue();
        RAM[cMCU_regPORTC, 1] := GetXValue();
        RAM[cMCU_regPORTC, 0] := GetXValue();
        // ��������� GPR xxxx xxxx
        for Z := 1 to 255 do
          if (MatrixRAM[Z].Used = true) and (MatrixRAM[Z].SFR = false) then
            for j := 0 to 7 do
              RAM[Z, j] := GetXValue();

        // ��������� OPTION --11 1111
        RAM[cMCU_regOPTION, 7] := false;
        RAM[cMCU_regOPTION, 6] := false;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISA ---- 1111
        RAM[cMCU_regTRISA, 0] := true;
        RAM[cMCU_regTRISA, 1] := true;
        RAM[cMCU_regTRISA, 2] := true;
        RAM[cMCU_regTRISA, 3] := true;
        // ��������� TRISB 1111 1111
        RAM[cMCU_regTRISB, 0] := true;
        RAM[cMCU_regTRISB, 1] := true;
        RAM[cMCU_regTRISB, 2] := true;
        RAM[cMCU_regTRISB, 3] := true;
        RAM[cMCU_regTRISB, 4] := true;
        RAM[cMCU_regTRISB, 5] := true;
        RAM[cMCU_regTRISB, 6] := true;
        RAM[cMCU_regTRISB, 7] := true;
        // ��������� TRISC 1111 1111
        RAM[cMCU_regTRISC, 0] := true;
        RAM[cMCU_regTRISC, 1] := true;
        RAM[cMCU_regTRISC, 2] := true;
        RAM[cMCU_regTRISC, 3] := true;
        RAM[cMCU_regTRISC, 4] := true;
        RAM[cMCU_regTRISC, 5] := true;
        RAM[cMCU_regTRISC, 6] := true;
        RAM[cMCU_regTRISC, 7] := true;
      end;

{$ENDREGION}
    15:
{$REGION 'POR for PIC16F59'}
      begin
        // ��������� TMR0 xxxx xxxx
        for j := 0 to 7 do
          RAM[cMCU_regTMR0, j] := GetXValue();
        // ��������� PCL 1111 1111
        for j := 0 to 7 do
          RAM[cMCU_regPCL, j] := true;
        // ��������� STATUS 0001 1xxx
        RAM[cMCU_regSTATUS, 7] := false;
        RAM[cMCU_regSTATUS, 6] := false;
        RAM[cMCU_regSTATUS, 5] := false;
        RAM[cMCU_regSTATUS, 4] := true;
        RAM[cMCU_regSTATUS, 3] := true;
        RAM[cMCU_regSTATUS, 2] := GetXValue();
        RAM[cMCU_regSTATUS, 1] := GetXValue();
        RAM[cMCU_regSTATUS, 0] := GetXValue();
        // ��������� FSR 1xxx xxxx
        RAM[cMCU_regFSR, 7] := GetXValue();
        RAM[cMCU_regFSR, 6] := GetXValue();
        RAM[cMCU_regFSR, 5] := GetXValue();
        RAM[cMCU_regFSR, 4] := GetXValue();
        RAM[cMCU_regFSR, 3] := GetXValue();
        RAM[cMCU_regFSR, 2] := GetXValue();
        RAM[cMCU_regFSR, 1] := GetXValue();
        RAM[cMCU_regFSR, 0] := GetXValue();

        // ��������� PORTA ---- xxxx
        RAM[cMCU_regPORTA, 7] := false;
        RAM[cMCU_regPORTA, 6] := false;
        RAM[cMCU_regPORTA, 5] := false;
        RAM[cMCU_regPORTA, 4] := false;
        RAM[cMCU_regPORTA, 3] := GetXValue();
        RAM[cMCU_regPORTA, 2] := GetXValue();
        RAM[cMCU_regPORTA, 1] := GetXValue();
        RAM[cMCU_regPORTA, 0] := GetXValue();
        // ��������� PORTB xxxx xxxx
        RAM[cMCU_regPORTB, 7] := GetXValue();
        RAM[cMCU_regPORTB, 6] := GetXValue();
        RAM[cMCU_regPORTB, 5] := GetXValue();
        RAM[cMCU_regPORTB, 4] := GetXValue();
        RAM[cMCU_regPORTB, 3] := GetXValue();
        RAM[cMCU_regPORTB, 2] := GetXValue();
        RAM[cMCU_regPORTB, 1] := GetXValue();
        RAM[cMCU_regPORTB, 0] := GetXValue();
        // ��������� PORTC xxxx xxxx
        RAM[cMCU_regPORTC, 7] := GetXValue();
        RAM[cMCU_regPORTC, 6] := GetXValue();
        RAM[cMCU_regPORTC, 5] := GetXValue();
        RAM[cMCU_regPORTC, 4] := GetXValue();
        RAM[cMCU_regPORTC, 3] := GetXValue();
        RAM[cMCU_regPORTC, 2] := GetXValue();
        RAM[cMCU_regPORTC, 1] := GetXValue();
        RAM[cMCU_regPORTC, 0] := GetXValue();
        // ��������� PORTD xxxx xxxx
        RAM[cMCU_regPORTD, 7] := GetXValue();
        RAM[cMCU_regPORTD, 6] := GetXValue();
        RAM[cMCU_regPORTD, 5] := GetXValue();
        RAM[cMCU_regPORTD, 4] := GetXValue();
        RAM[cMCU_regPORTD, 3] := GetXValue();
        RAM[cMCU_regPORTD, 2] := GetXValue();
        RAM[cMCU_regPORTD, 1] := GetXValue();
        RAM[cMCU_regPORTD, 0] := GetXValue();
        // ��������� PORTE xxxx ----
        RAM[cMCU_regPORTE, 7] := GetXValue();
        RAM[cMCU_regPORTE, 6] := GetXValue();
        RAM[cMCU_regPORTE, 5] := GetXValue();
        RAM[cMCU_regPORTE, 4] := GetXValue();
        RAM[cMCU_regPORTE, 3] := false;
        RAM[cMCU_regPORTE, 2] := false;
        RAM[cMCU_regPORTE, 1] := false;
        RAM[cMCU_regPORTE, 0] := false;
        // ��������� GPR xxxx xxxx
        for Z := 1 to 255 do
          if (MatrixRAM[Z].Used = true) and (MatrixRAM[Z].SFR = false) then
            for j := 0 to 7 do
              RAM[Z, j] := GetXValue();

        // ��������� OPTION --11 1111
        RAM[cMCU_regOPTION, 7] := false;
        RAM[cMCU_regOPTION, 6] := false;
        RAM[cMCU_regOPTION, 5] := true;
        RAM[cMCU_regOPTION, 4] := true;
        RAM[cMCU_regOPTION, 3] := true;
        RAM[cMCU_regOPTION, 2] := true;
        RAM[cMCU_regOPTION, 1] := true;
        RAM[cMCU_regOPTION, 0] := true;
        // ��������� TRISA ---- 1111
        RAM[cMCU_regTRISA, 0] := true;
        RAM[cMCU_regTRISA, 1] := true;
        RAM[cMCU_regTRISA, 2] := true;
        RAM[cMCU_regTRISA, 3] := true;
        // ��������� TRISB 1111 1111
        RAM[cMCU_regTRISB, 0] := true;
        RAM[cMCU_regTRISB, 1] := true;
        RAM[cMCU_regTRISB, 2] := true;
        RAM[cMCU_regTRISB, 3] := true;
        RAM[cMCU_regTRISB, 4] := true;
        RAM[cMCU_regTRISB, 5] := true;
        RAM[cMCU_regTRISB, 6] := true;
        RAM[cMCU_regTRISB, 7] := true;
        // ��������� TRISC 1111 1111
        RAM[cMCU_regTRISC, 0] := true;
        RAM[cMCU_regTRISC, 1] := true;
        RAM[cMCU_regTRISC, 2] := true;
        RAM[cMCU_regTRISC, 3] := true;
        RAM[cMCU_regTRISC, 4] := true;
        RAM[cMCU_regTRISC, 5] := true;
        RAM[cMCU_regTRISC, 6] := true;
        RAM[cMCU_regTRISC, 7] := true;
        // ��������� TRID 1111 1111
        RAM[cMCU_regTRISD, 0] := true;
        RAM[cMCU_regTRISD, 1] := true;
        RAM[cMCU_regTRISD, 2] := true;
        RAM[cMCU_regTRISD, 3] := true;
        RAM[cMCU_regTRISD, 4] := true;
        RAM[cMCU_regTRISD, 5] := true;
        RAM[cMCU_regTRISD, 6] := true;
        RAM[cMCU_regTRISD, 7] := true;
        // ��������� TRIE 1111 ----
        RAM[cMCU_regTRISE, 4] := true;
        RAM[cMCU_regTRISE, 5] := true;
        RAM[cMCU_regTRISE, 6] := true;
        RAM[cMCU_regTRISE, 7] := true;
      end;

{$ENDREGION}
  end;

  // ����� �������� RAM � �������, ����� ����� ���� ��������� ������, ����� ������� ������
  for Z := 0 to AllRAMSize do
  begin
    MatrixRAM[Z].delta := false;
    for j := 0 to 7 do
    begin
      // MatrixRAM[Z].value[j]:=RAM[Z,J];
      MatrixRAM[Z].deltabit[j] := false;
    end;
  end;
  // ������� ������������ � �������� �����������
  for Z := 0 to 7 do
  begin
    MatrixRAM[cMCU_regTMR0P].usedbit[Z] := false;
    RAM[cMCU_regTMR0P, Z] := false;
  end;
end;

procedure OtherReset(pMCLR: boolean; pWDT: boolean; pWakeOnPin: boolean = false;
  pWakeOnComp: boolean = false);

// ����� ��������� ������������� RAM �� ����� ������ POR
Var
  Z: Word;
  j: byte;
begin

  // ����� ��� ����� ��������� baseline
  // ��������� INDF uuuu uuuu  (��� ����� ��������� BASELINE)
  // NOP
  // ��������� TMR0 uuuu uuuu (��� ����� ��������� BASELINE)
  // NOP
  // ��������� PCL 1111 1111  (��� ����� ��������� BASELINE)
  for j := 0 to 7 do
    RAM[cMCU_regPCL, j] := true;

  if rtMCId <= 9 then
  begin
{$REGION 'Other reset for PIC10F200/202/204/206 and PIC10F220/222' and PIC12F508/509/510/519}

    // ��������� STATUS q00q quuu ��� qq0q quuu

    if SleepMode and pWakeOnPin then
      RAM[cMCU_regSTATUS, 7] := true
    else
      RAM[cMCU_regSTATUS, 7] := false;

    // PIC10F204/206, 12F510 only, for other - "0"
    if SleepMode and pWakeOnComp then
      RAM[cMCU_regSTATUS, 6] := true
    else
      RAM[cMCU_regSTATUS, 6] := false;

    RAM[cMCU_regSTATUS, 5] := false;

    if pWDT then
      RAM[cMCU_regSTATUS, 4] := false
    else if pMCLR and (SleepMode = false) then
      RAM[cMCU_regSTATUS, 4] := RAM[cMCU_regSTATUS, 4]
    else
      RAM[cMCU_regSTATUS, 4] := true;

    if SleepMode then
      RAM[cMCU_regSTATUS, 3] := false;

    // ��������� FSR 111u uuuu /11uu uuuu
    RAM[cMCU_regFSR, 7] := true;
    RAM[cMCU_regFSR, 6] := true;
    if (rtMCId < 7) then
      RAM[cMCU_regFSR, 5] := true;
    // ��� ���� 1, ����� 509,510,519  (��� ��� unchange)


    // ��������� OSCCAL uuuu uuuu
    // NOP
    // ��������� GPIO ---- uuuu /��� 12f508 --uu uuuu
    // NOP
    // RAM[cMCU_regGPIO, 5] := false;
    // RAM[cMCU_regGPIO, 4] := false;

    // ��������� GPR uuuu uuuu
    // NOP
    // ��������� W qqqq qqqu??????????
    // NOP
    // ��������� OPTION 1111 1111
    RAM[cMCU_regOPTION, 7] := true;
    RAM[cMCU_regOPTION, 6] := true;
    RAM[cMCU_regOPTION, 5] := true;
    RAM[cMCU_regOPTION, 4] := true;
    RAM[cMCU_regOPTION, 3] := true;
    RAM[cMCU_regOPTION, 2] := true;
    RAM[cMCU_regOPTION, 1] := true;
    RAM[cMCU_regOPTION, 0] := true;
    // ��������� TRISGPIO ---- 1111
    if (rtMCId <= 9) then
    begin
      RAM[cMCU_regTRISGPIO, 0] := true;
      RAM[cMCU_regTRISGPIO, 1] := true;
      RAM[cMCU_regTRISGPIO, 2] := true;
      RAM[cMCU_regTRISGPIO, 3] := true;
      if (rtMCId >= 6) then
      begin
        RAM[cMCU_regTRISGPIO, 4] := true;
        RAM[cMCU_regTRISGPIO, 5] := true;
      end;
    end;

    // PIC10F220/222 only
    if (rtMCId = 4) or (rtMCId = 5) then
    begin
      // ��������� ADCON0 11-- 1100
      RAM[cMCU_regADCON0, 7] := true;
      RAM[cMCU_regADCON0, 6] := true;
      RAM[cMCU_regADCON0, 5] := false;
      RAM[cMCU_regADCON0, 4] := false;
      RAM[cMCU_regADCON0, 3] := true;
      RAM[cMCU_regADCON0, 2] := true;
      RAM[cMCU_regADCON0, 1] := false;
      RAM[cMCU_regADCON0, 0] := false;
      // ��������� ADRES uuuu uuuu
      // NOP
    end;
    // PIC12F510 only
    if (rtMCId = 8) then
    begin
      // ��������� ADCON0 uu11 1100

      RAM[cMCU_regADCON0, 5] := true;
      RAM[cMCU_regADCON0, 4] := true;
      RAM[cMCU_regADCON0, 3] := true;
      RAM[cMCU_regADCON0, 2] := true;
      RAM[cMCU_regADCON0, 1] := false;
      RAM[cMCU_regADCON0, 0] := false;
      // ��������� ADRES uuuu uuuu
      // NOP
    end;

{$ENDREGION}
  end;
  if (rtMCId = 13) or (rtMCId = 14) or (rtMCId = 15) then
  begin
{$REGION 'Other reset for PIC16F54/57/59}

    // ��������� STATUS 000q quuu

    RAM[cMCU_regSTATUS, 7] := false;

    RAM[cMCU_regSTATUS, 6] := false;

    RAM[cMCU_regSTATUS, 5] := false;

    if pWDT then
      RAM[cMCU_regSTATUS, 4] := false
    else if pMCLR and (SleepMode = false) then
      RAM[cMCU_regSTATUS, 4] := RAM[cMCU_regSTATUS, 4]
    else
      RAM[cMCU_regSTATUS, 4] := true;

    if SleepMode then
      RAM[cMCU_regSTATUS, 3] := false;

    // ��������� FSR 111u uuuu
    if rtMCId = 13 then
    begin
      RAM[cMCU_regFSR, 7] := true;
      RAM[cMCU_regFSR, 6] := true;
      RAM[cMCU_regFSR, 5] := true;
    end;
    // ��������� FSR 1uuu uuuu
    if rtMCId = 14 then
    begin
      RAM[cMCU_regFSR, 7] := true;
    end;
    // ��������� FSR uuuu uuuu

    // ��������� PORTA,PORTB,PORTC,PORTD,PORTE uuuu uuuu
    // NOP

    // ��������� GPR uuuu uuuu
    // NOP
    // ��������� W qqqq qqqu??????????
    // NOP
    // ��������� OPTION -- 1111
    RAM[cMCU_regOPTION, 7] := false;
    RAM[cMCU_regOPTION, 6] := false;
    RAM[cMCU_regOPTION, 5] := true;
    RAM[cMCU_regOPTION, 4] := true;
    RAM[cMCU_regOPTION, 3] := true;
    RAM[cMCU_regOPTION, 2] := true;
    RAM[cMCU_regOPTION, 1] := true;
    RAM[cMCU_regOPTION, 0] := true;
    // ��������� TRISA ---- 1111
    if cMCU_regTRISA > 0 then
    begin
      RAM[cMCU_regTRISA, 0] := true;
      RAM[cMCU_regTRISA, 1] := true;
      RAM[cMCU_regTRISA, 2] := true;
      RAM[cMCU_regTRISA, 3] := true;
    end;
    // ��������� TRISB 1111 1111
    if cMCU_regTRISB > 0 then
    begin
      RAM[cMCU_regTRISB, 0] := true;
      RAM[cMCU_regTRISB, 1] := true;
      RAM[cMCU_regTRISB, 2] := true;
      RAM[cMCU_regTRISB, 3] := true;
      RAM[cMCU_regTRISB, 4] := true;
      RAM[cMCU_regTRISB, 5] := true;
      RAM[cMCU_regTRISB, 6] := true;
      RAM[cMCU_regTRISB, 7] := true;
    end;
    // ��������� TRISC 1111 1111
    if cMCU_regTRISC > 0 then
    begin
      RAM[cMCU_regTRISC, 0] := true;
      RAM[cMCU_regTRISC, 1] := true;
      RAM[cMCU_regTRISC, 2] := true;
      RAM[cMCU_regTRISC, 3] := true;
      RAM[cMCU_regTRISC, 4] := true;
      RAM[cMCU_regTRISC, 5] := true;
      RAM[cMCU_regTRISC, 6] := true;
      RAM[cMCU_regTRISC, 7] := true;
    end;
    // ��������� TRID 1111 1111
    if cMCU_regTRISD > 0 then
    begin
      RAM[cMCU_regTRISD, 0] := true;
      RAM[cMCU_regTRISD, 1] := true;
      RAM[cMCU_regTRISD, 2] := true;
      RAM[cMCU_regTRISD, 3] := true;
      RAM[cMCU_regTRISD, 4] := true;
      RAM[cMCU_regTRISD, 5] := true;
      RAM[cMCU_regTRISD, 6] := true;
      RAM[cMCU_regTRISD, 7] := true;
    end;
    // ��������� TRIE 1111 ----
    if cMCU_regTRISE > 0 then
    begin
      RAM[cMCU_regTRISE, 4] := true;
      RAM[cMCU_regTRISE, 5] := true;
      RAM[cMCU_regTRISE, 6] := true;
      RAM[cMCU_regTRISE, 7] := true;
    end;

{$ENDREGION}
  end;
  {
    ����� �������� RAM � �������, ����� ����� ���� ��������� ������, ����� ������� ������   - ����� �� ����
    for Z := 0 to AllRAMSize do
    begin
    MatrixRAM[Z].delta := false;
    for j := 0 to 7 do
    begin
    // MatrixRAM[Z].value[j]:=RAM[Z,J];
    MatrixRAM[Z].deltabit[j] := false;
    end;
    end; }
  // ������� ������������ � �������� �����������
  for Z := 0 to 7 do
  begin
    MatrixRAM[cMCU_regTMR0P].usedbit[Z] := false;
    RAM[cMCU_regTMR0P, Z] := false;
  end;
  SleepMode := false; // ����� �� ������ ���
end;

procedure generateSimAdress();
var
  Z: integer;
begin
  for Z := 0 to AllRAMSize do
  begin
    if MatrixRAM[Z].IDEaddres > -1 then
    begin
      MatrixRAM[MatrixRAM[Z].IDEaddres].SIMadress := Z;
    end;
  end;
end;

function ReadRAM(): boolean;
var

  temp: byte;
  tmpSingle: Single;
begin
  // ��� �������� EEPROM ��� �����
  // ���� ���� � �������, �� �������������� � ���-�� �� ��������� ����� FSR
  // !Port
  // 2-� �������� ������
  if (rtMCId = 7) or (rtMCId = 8) or (rtMCId = 9) then
  begin
    if (ByteNo > 15) and (ByteNo < 32) and (RAM[cMCU_regFSR, 5] = true) then
      ByteNo := ByteNo + 32;
    // <32 �����, ����� �� ��������� �������� ��� ������� >255?
  end;
  // 4-� �������� ������
  if (rtMCId = 10) or (rtMCId = 11) or (rtMCId = 12) or (rtMCId = 14) then
    if (ByteNo > 15) and (ByteNo < 32) then
    // <32 �����, ����� �� ��������� �������� ��� ������� >255?
    begin
      if (RAM[cMCU_regFSR, 5] = true) then
        ByteNo := ByteNo + 32;
      if (RAM[cMCU_regFSR, 6] = true) then
        ByteNo := ByteNo + 64;
    end;

  // 8-�� �������� ������
  if (rtMCId = 15) then
    if (ByteNo > 15) and (ByteNo < 32) then
    // <32 �����, ����� �� ��������� �������� ��� ������� >255?
    begin
      if (RAM[cMCU_regFSR, 5] = true) then
        ByteNo := ByteNo + 32;
      if (RAM[cMCU_regFSR, 6] = true) then
        ByteNo := ByteNo + 64;
      if (RAM[cMCU_regFSR, 7] = true) then
        ByteNo := ByteNo + 128;
    end;



  // SFR

  // INDF
  if ByteNo = cMCU_regINDF then
  begin
    par[0] := RAM[cMCU_regFSR, 0];
    par[1] := RAM[cMCU_regFSR, 1];
    par[2] := RAM[cMCU_regFSR, 2];
    par[3] := RAM[cMCU_regFSR, 3];
    par[4] := RAM[cMCU_regFSR, 4];
    par[5] := false;
    par[6] := false;
    par[7] := false;
    par[8] := false;

    temp := BinToDec();
    if temp <> cMCU_regINDF then
    begin
      ByteNo := temp;
      ReadRAM := ReadRAM()
    end

    else
      ReadRAM := false;
    exit;
  end;
  // GPIO
  if ByteNo = cMCU_regGPIO then
  begin
    if RAM[cMCU_regTRISGPIO, BitNo] then // �� ���� �� �������� �����?
    begin // ��
      // ��������� � ��������� ����� (���� ��������)
      case BitNo of
        0:
          begin
            if (cMCU_regADCON0 > -1) then
            begin
              if (rtMCId = 8) and (RAM[cMCU_regADCON0, 7] = true) then
              // ����� AN0  ��� 510
              begin
                ReadRAM := false; // #?
                exit;
              end
              else if (RAM[cMCU_regADCON0, 6] = true) then
              // ����� AN0  ��� 220/222
              begin
                ReadRAM := false; // #?
                exit;
              end;
            end;
            if (cMCU_regCMCON > -1) and (RAM[cMCU_regCMCON, 3] = true) then
            // ����� CIN+   ��� 204/206 � 510
            begin
              ReadRAM := false; // #?
              exit;
            end

            else
            begin // GP0
              // ������ � �����
              tmpSingle := TD.Port[BitNo].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          end;
        1:
          begin
            if (cMCU_regADCON0 > -1) then
            begin
              if (rtMCId = 8) and (RAM[cMCU_regADCON0, 7] = true) and
                (RAM[cMCU_regADCON0, 6] = true) then
              begin // 510
                ReadRAM := false; // #?
                exit;
              end
              else
              begin // 220/222
                if (RAM[cMCU_regADCON0, 7] = true) then
                // ����� AN1
                begin
                  ReadRAM := false; // #?
                  exit;
                end;
              end;
            end;
            if (cMCU_regCMCON > -1) and (RAM[cMCU_regCMCON, 3] = true) then
            // ����� CIN- ��� 510, 204/206
            begin
              ReadRAM := false; // #?
              exit;
            end
            else
            begin // GP1
              // ������ � �����
              tmpSingle := TD.Port[BitNo].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          end;

        2: // GP2/TOCKI/FOSC4/COUT  //AN2
          if (rtMCId = 8) and ((RAM[cMCU_regADCON0, 7] = true) or
            (RAM[cMCU_regADCON0, 6] = true)) then
          begin // 510  AN2
            ReadRAM := false; // #?
            exit;
          end
          else if (cMCU_regCMCON > -1) and
            ((RAM[cMCU_regCMCON, 3] = true) and (RAM[cMCU_regCMCON, 6] = false))
          then // ����� COUT
          begin
            ReadRAM := false; // #?
            exit;
          end
          else
          begin
            if RAM[5, 0] then
            begin // ���� �� INTOSC/4
              ReadRAM := false; // #?
              exit;
            end;
            if RAM[cMCU_regOPTION, 5] then
            begin // ���� �� T0CKI
              ReadRAM := false; // #?
              exit;
            end;

            // ������ � �����
            tmpSingle := TD.Port[BitNo].Node.GetLevel;
            if isNan(tmpSingle) then
              ReadRAM := true
            else if (tmpSingle <= MaxLowLevelVoltage) then
              ReadRAM := false
            else
              ReadRAM := true;
            exit;
          end;
        3: // GP3/\MCLR
          begin
            if Config[4] = true then // ���� �� \MCLR
            begin
              ReadRAM := false; // ��������� � ������������
              exit;
            end;
            // ������ � �����
            tmpSingle := TD.Port[BitNo].Node.GetLevel;
            if isNan(tmpSingle) then
              ReadRAM := true
            else if (tmpSingle <= MaxLowLevelVoltage) then
              ReadRAM := false
            else
              ReadRAM := true;
            exit;
          end;
        4:
          begin
            if cMCU_hiGPIO > 3 then
            begin
              // GP4
              // ������ � �����
              tmpSingle := TD.Port[BitNo].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end
            else
            begin // unimplemented
              ReadRAM := false;
              exit;
            end;
          end;
        5: // unimplemented
          begin
            if cMCU_hiGPIO > 4 then
            begin
              // GP5
              // ������ � �����
              tmpSingle := TD.Port[BitNo].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end
            else
            begin // unimplemented
              ReadRAM := false;
              exit;
            end;
          end;
        6: // unimplemented
          begin
            ReadRAM := false;
            exit;
          end;
        7: // unimplemented
          begin
            ReadRAM := false;
            exit;
          end;

      end;

    end;
  end;
  // ��� ���� ����������� ������ ��� 5x �����������������, ��� ������ - �� ������ ������ �������, ��� ��� ������ ��������
  if (rtMCId = 13) or (rtMCId = 14) or (rtMCId = 15) then
{$REGION 'PORTS for PIC16F5X'}
  begin
    // PORTA
    if ByteNo = cMCU_regPORTA then
    begin
      if RAM[cMCU_regTRISA, BitNo] then // �� ���� �� �������� �����?
      begin // ��
        // ��������� � ��������� ����� (���� ��������)
        case BitNo of
          0:
            begin
              // ������ � �����
              tmpSingle := TD.Port[0].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          1:
            begin
              // ������ � �����
              tmpSingle := TD.Port[1].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          2:
            begin
              // ������ � �����
              tmpSingle := TD.Port[2].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          3:
            begin
              // ������ � �����
              tmpSingle := TD.Port[3].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
        end;
      end;
    end;
    // PORTB
    if ByteNo = cMCU_regPORTB then
    begin
      if RAM[cMCU_regTRISB, BitNo] then // �� ���� �� �������� �����?
      begin // ��
        // ��������� � ��������� ����� (���� ��������)
        case BitNo of
          0:
            begin
              // ������ � �����
              tmpSingle := TD.Port[4].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          1:
            begin
              // ������ � �����
              tmpSingle := TD.Port[5].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          2:
            begin
              // ������ � �����
              tmpSingle := TD.Port[6].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          3:
            begin
              // ������ � �����
              tmpSingle := TD.Port[7].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          4:
            begin
              // ������ � �����
              tmpSingle := TD.Port[8].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          5:
            begin
              // ������ � �����
              tmpSingle := TD.Port[9].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          6:
            begin
              // ������ � �����
              tmpSingle := TD.Port[10].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          7:
            begin
              // ������ � �����
              tmpSingle := TD.Port[11].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
        end;
      end;
    end;
    // PORTC
    if ByteNo = cMCU_regPORTC then
    begin
      if RAM[cMCU_regTRISC, BitNo] then // �� ���� �� �������� �����?
      begin // ��
        // ��������� � ��������� ����� (���� ��������)
        case BitNo of
          0:
            begin
              // ������ � �����
              tmpSingle := TD.Port[12].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          1:
            begin
              // ������ � �����
              tmpSingle := TD.Port[13].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          2:
            begin
              // ������ � �����
              tmpSingle := TD.Port[14].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          3:
            begin
              // ������ � �����
              tmpSingle := TD.Port[15].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          4:
            begin
              // ������ � �����
              tmpSingle := TD.Port[16].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          5:
            begin
              // ������ � �����
              tmpSingle := TD.Port[17].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          6:
            begin
              // ������ � �����
              tmpSingle := TD.Port[18].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          7:
            begin
              // ������ � �����
              tmpSingle := TD.Port[19].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
        end;
      end;
    end;
    // PORTD
    if ByteNo = cMCU_regPORTD then
    begin
      if RAM[cMCU_regTRISD, BitNo] then // �� ���� �� �������� �����?
      begin // ��
        // ��������� � ��������� ����� (���� ��������)
        case BitNo of
          0:
            begin
              // ������ � �����
              tmpSingle := TD.Port[20].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          1:
            begin
              // ������ � �����
              tmpSingle := TD.Port[21].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          2:
            begin
              // ������ � �����
              tmpSingle := TD.Port[22].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          3:
            begin
              // ������ � �����
              tmpSingle := TD.Port[23].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          4:
            begin
              // ������ � �����
              tmpSingle := TD.Port[24].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          5:
            begin
              // ������ � �����
              tmpSingle := TD.Port[25].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          6:
            begin
              // ������ � �����
              tmpSingle := TD.Port[26].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          7:
            begin
              // ������ � �����
              tmpSingle := TD.Port[27].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
        end;
      end;
    end;
    // PORTE
    if ByteNo = cMCU_regPORTE then
    begin
      if RAM[cMCU_regTRISE, BitNo] then // �� ���� �� �������� �����?
      begin // ��
        // ��������� � ��������� ����� (���� ��������)
        case BitNo of
          4:
            begin
              // ������ � �����
              tmpSingle := TD.Port[28].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          5:
            begin
              // ������ � �����
              tmpSingle := TD.Port[29].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          6:
            begin
              // ������ � �����
              tmpSingle := TD.Port[30].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
          7:
            begin
              // ������ � �����
              tmpSingle := TD.Port[31].Node.GetLevel;
              if isNan(tmpSingle) then
                ReadRAM := true
              else if (tmpSingle <= MaxLowLevelVoltage) then
                ReadRAM := false
              else
                ReadRAM := true;
              exit;
            end;
        end;
      end;
    end;

  end;
{$ENDREGION}
  ReadRAM := RAM[ByteNo, BitNo];
end;

procedure ChangeRAMBit();
// ���. ���������� ChangeBitAddr, ChangeBitNo, ChangeBitData
var
  temp: byte;
begin
  // ���� ���� � �������, �� �������������� � ���-�� �� ��������� ����� FSR
  // !!!�������� �������� �������� ��� ���� � ��������� ���� "!Port"
  // !Port

  // 2-� �������� ����
  if (rtMCId = 7) or (rtMCId = 8) or (rtMCId = 9) then
  begin
    if (ChangeBitAddr > 15) and (ChangeBitAddr < 32) and
      (RAM[cMCU_regFSR, 5] = true) then
      ChangeBitAddr := ChangeBitAddr + 32;
    // <32 �����, ����� �� ��������� �������� ��� ������� >255?
  end;
  // 4-� �������� ����
  if (rtMCId = 10) or (rtMCId = 11) or (rtMCId = 12) or (rtMCId = 14) then
  begin
    if (ChangeBitAddr > 15) and (ChangeBitAddr < 32) then
    begin // <32 �����, ����� �� ��������� �������� ��� ������� >255?
      if (RAM[cMCU_regFSR, 5] = true) then
        ChangeBitAddr := ChangeBitAddr + 32;
      if (RAM[cMCU_regFSR, 6] = true) then
        ChangeBitAddr := ChangeBitAddr + 64;
    end;
  end;
  // 8-�� �������� ����
  if (rtMCId = 15) then
  begin
    if (ChangeBitAddr > 15) and (ChangeBitAddr < 32) then
    begin // <32 �����, ����� �� ��������� �������� ��� ������� >255?
      if (RAM[cMCU_regFSR, 5] = true) then
        ChangeBitAddr := ChangeBitAddr + 32;
      if (RAM[cMCU_regFSR, 6] = true) then
        ChangeBitAddr := ChangeBitAddr + 64;
      if (RAM[cMCU_regFSR, 7] = true) then
        ChangeBitAddr := ChangeBitAddr + 128;
    end;
  end;
  // !Port
  // ��������, � ������ ������������ �� ���� ����
  if MatrixRAM[ChangeBitAddr].Used then // ������������
  begin

    MatrixRAM[ChangeBitAddr].delta := true;
    // ����� ������ � �������, ����� ����� ���� ��������� ��� ������ ����������
    // MatrixRAM[ChangeBitAddr].lastvalue[ChangeBitNo]:=RAM[ChangeAddr,ChangeBitNo];
    // ����������� ��� ������

    if ChangeBitData <> RAM[ChangeBitAddr, ChangeBitNo] then
    begin // ������� ������
      MatrixRAM[ChangeBitAddr].greenDelta := false;
      MatrixRAM[ChangeBitAddr].deltabit[ChangeBitNo] := true;
      // �������� �� ���������� �������
      if MatrixRAM[ChangeBitAddr].BreakPoint then
      begin
        rtPause := true;
      end;

    end
    else
    begin // ������� ������
      MatrixRAM[ChangeBitAddr].greenDelta := true;
      MatrixRAM[ChangeBitAddr].deltabit[ChangeBitNo] := true;
      // �������� �� ���������� �������
      if MatrixRAM[ChangeBitAddr].BreakPoint and MatrixRAM[ChangeBitAddr].GreenBP
      then
      begin
        rtPause := true;
      end;
    end;

    //
    //
    // ��������, ����� ���-�� ����������� ����������
    //
    //



    if ChangeBitAddr = cMCU_regPCL then // ������� PCL
    begin
      if RAM[cMCU_regPCL, ChangeBitNo] = ChangeBitData then
        exit // ��� ������ ������ ������, ��� ��� �� �����
      else if not ChangeDataNotInstruction then
        if ChangeBitData = true then
          I := I + St2[ChangeBitNo]
        else
          I := I - St2[ChangeBitNo];
      RAM[cMCU_regPCL, ChangeBitNo] := ChangeBitData;
      PC[ChangeBitNo] := ChangeBitData;
      exit;
    end;

    if ChangeBitAddr = cMCU_regGPIO then // ������ GPIO
    begin
      // ������ (����� �����, ���� ���� ���������� ���� BSF - �� ���-��� ���)
      if RAM[cMCU_regTRISGPIO, 0] then // ���� �� ����
      begin
        ByteNo := cMCU_regGPIO;
        BitNo := 0;
        RAM[ChangeBitAddr, 0] := ReadRAM();
      end;
      if RAM[cMCU_regTRISGPIO, 1] then // ���� �� ����
      begin
        ByteNo := cMCU_regGPIO;
        BitNo := 1;
        RAM[ChangeBitAddr, 1] := ReadRAM();
      end;
      if RAM[cMCU_regTRISGPIO, 2] then // ���� �� ����
      begin
        ByteNo := cMCU_regGPIO;
        BitNo := 2;
        RAM[ChangeBitAddr, 2] := ReadRAM();
      end;
      if RAM[cMCU_regTRISGPIO, 3] then // ���� �� ����
      begin
        ByteNo := cMCU_regGPIO;
        BitNo := 3;
        RAM[ChangeBitAddr, 3] := ReadRAM();
      end;
      if RAM[cMCU_regTRISGPIO, 4] then // ���� �� ����
      begin
        ByteNo := cMCU_regGPIO;
        BitNo := 4;
        RAM[ChangeBitAddr, 4] := ReadRAM();
      end;
      if RAM[cMCU_regTRISGPIO, 5] then // ���� �� ����
      begin
        ByteNo := cMCU_regGPIO;
        BitNo := 5;
        RAM[ChangeBitAddr, 5] := ReadRAM();
      end;
      // �����������
      RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;
      // ������
      if not RAM[cMCU_regTRISGPIO, ChangeBitNo] then
        realGPIO[ChangeBitNo] := ChangeBitData;
      exit;
    end;
    // ����� ������ ��� PIC16F5X, ��� ��������� - ��������� ���� ����, �.�. ��� �������� ������ ������� �� ����
    if (rtMCId = 13) or (rtMCId = 14) or (rtMCId = 15) then
{$REGION 'PORTS for PIC16F5X'}
    begin
      if ChangeBitAddr = cMCU_regPORTA then // ������ PORTA
      begin
        // ������ (����� �����, ���� ���� ���������� ���� BSF - �� ���-��� ���)
        if RAM[cMCU_regTRISA, 0] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 0;
          RAM[ChangeBitAddr, 0] := ReadRAM();
        end;
        if RAM[cMCU_regTRISA, 1] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 1;
          RAM[ChangeBitAddr, 1] := ReadRAM();
        end;
        if RAM[cMCU_regTRISA, 2] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 2;
          RAM[ChangeBitAddr, 2] := ReadRAM();
        end;
        if RAM[cMCU_regTRISA, 3] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 3;
          RAM[ChangeBitAddr, 3] := ReadRAM();
        end;
        if RAM[cMCU_regPORTA, 4] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 4;
          RAM[ChangeBitAddr, 4] := ReadRAM();
        end;
        if RAM[cMCU_regTRISA, 5] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 5;
          RAM[ChangeBitAddr, 5] := ReadRAM();
        end;
        if RAM[cMCU_regTRISA, 6] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 6;
          RAM[ChangeBitAddr, 6] := ReadRAM();
        end;
        if RAM[cMCU_regTRISA, 7] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTA;
          BitNo := 7;
          RAM[ChangeBitAddr, 7] := ReadRAM();
        end;
        // �����������
        RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;
        // ������
        if not RAM[cMCU_regTRISA, ChangeBitNo] then
          realPA[ChangeBitNo] := ChangeBitData;
        exit;
      end;
      if ChangeBitAddr = cMCU_regPORTB then // ������ PORTB
      begin
        // ������ (����� �����, ���� ���� ���������� ���� BSF - �� ���-��� ���)
        if RAM[cMCU_regTRISB, 0] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 0;
          RAM[ChangeBitAddr, 0] := ReadRAM();
        end;
        if RAM[cMCU_regTRISB, 1] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 1;
          RAM[ChangeBitAddr, 1] := ReadRAM();
        end;
        if RAM[cMCU_regTRISB, 2] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 2;
          RAM[ChangeBitAddr, 2] := ReadRAM();
        end;
        if RAM[cMCU_regTRISB, 3] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 3;
          RAM[ChangeBitAddr, 3] := ReadRAM();
        end;
        if RAM[cMCU_regPORTB, 4] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 4;
          RAM[ChangeBitAddr, 4] := ReadRAM();
        end;
        if RAM[cMCU_regTRISB, 5] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 5;
          RAM[ChangeBitAddr, 5] := ReadRAM();
        end;
        if RAM[cMCU_regTRISB, 6] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 6;
          RAM[ChangeBitAddr, 6] := ReadRAM();
        end;
        if RAM[cMCU_regTRISB, 7] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTB;
          BitNo := 7;
          RAM[ChangeBitAddr, 7] := ReadRAM();
        end;
        // �����������
        RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;
        // ������
        if not RAM[cMCU_regTRISB, ChangeBitNo] then
          realPB[ChangeBitNo] := ChangeBitData;
        exit;
      end;
      if ChangeBitAddr = cMCU_regPORTC then // ������ PORTC
      begin
        // ������ (����� �����, ���� ���� ���������� ���� BSF - �� ���-��� ���)
        if RAM[cMCU_regTRISC, 0] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 0;
          RAM[ChangeBitAddr, 0] := ReadRAM();
        end;
        if RAM[cMCU_regTRISC, 1] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 1;
          RAM[ChangeBitAddr, 1] := ReadRAM();
        end;
        if RAM[cMCU_regTRISC, 2] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 2;
          RAM[ChangeBitAddr, 2] := ReadRAM();
        end;
        if RAM[cMCU_regTRISC, 3] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 3;
          RAM[ChangeBitAddr, 3] := ReadRAM();
        end;
        if RAM[cMCU_regPORTC, 4] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 4;
          RAM[ChangeBitAddr, 4] := ReadRAM();
        end;
        if RAM[cMCU_regTRISC, 5] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 5;
          RAM[ChangeBitAddr, 5] := ReadRAM();
        end;
        if RAM[cMCU_regTRISC, 6] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 6;
          RAM[ChangeBitAddr, 6] := ReadRAM();
        end;
        if RAM[cMCU_regTRISC, 7] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTC;
          BitNo := 7;
          RAM[ChangeBitAddr, 7] := ReadRAM();
        end;
        // �����������
        RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;
        // ������
        if not RAM[cMCU_regTRISC, ChangeBitNo] then
          realPC[ChangeBitNo] := ChangeBitData;
        exit;
      end;
      if ChangeBitAddr = cMCU_regPORTD then // ������ PORTD
      begin
        // ������ (����� �����, ���� ���� ���������� ���� BSF - �� ���-��� ���)
        if RAM[cMCU_regTRISD, 0] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 0;
          RAM[ChangeBitAddr, 0] := ReadRAM();
        end;
        if RAM[cMCU_regTRISD, 1] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 1;
          RAM[ChangeBitAddr, 1] := ReadRAM();
        end;
        if RAM[cMCU_regTRISD, 2] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 2;
          RAM[ChangeBitAddr, 2] := ReadRAM();
        end;
        if RAM[cMCU_regTRISD, 3] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 3;
          RAM[ChangeBitAddr, 3] := ReadRAM();
        end;
        if RAM[cMCU_regPORTD, 4] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 4;
          RAM[ChangeBitAddr, 4] := ReadRAM();
        end;
        if RAM[cMCU_regTRISD, 5] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 5;
          RAM[ChangeBitAddr, 5] := ReadRAM();
        end;
        if RAM[cMCU_regTRISD, 6] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 6;
          RAM[ChangeBitAddr, 6] := ReadRAM();
        end;
        if RAM[cMCU_regTRISD, 7] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTD;
          BitNo := 7;
          RAM[ChangeBitAddr, 7] := ReadRAM();
        end;
        // �����������
        RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;
        // ������
        if not RAM[cMCU_regTRISD, ChangeBitNo] then
          realPD[ChangeBitNo] := ChangeBitData;
        exit;
      end;
      if ChangeBitAddr = cMCU_regPORTE then // ������ PORTE
      begin
        // ������ (����� �����, ���� ���� ���������� ���� BSF - �� ���-��� ���)
        if RAM[cMCU_regPORTE, 4] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTE;
          BitNo := 4;
          RAM[ChangeBitAddr, 4] := ReadRAM();
        end;
        if RAM[cMCU_regTRISE, 5] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTE;
          BitNo := 5;
          RAM[ChangeBitAddr, 5] := ReadRAM();
        end;
        if RAM[cMCU_regTRISE, 6] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTE;
          BitNo := 6;
          RAM[ChangeBitAddr, 6] := ReadRAM();
        end;
        if RAM[cMCU_regTRISE, 7] then // ���� �� ����
        begin
          ByteNo := cMCU_regPORTE;
          BitNo := 7;
          RAM[ChangeBitAddr, 7] := ReadRAM();
        end;
        // �����������
        RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;
        // ������
        if not RAM[cMCU_regTRISE, ChangeBitNo] then
          realPE[ChangeBitNo] := ChangeBitData;
        exit;
      end;
    end;
{$ENDREGION}
    if ChangeBitAddr = cMCU_regINDF then // ������ INDF
    begin
      par[0] := RAM[4, 0];
      par[1] := RAM[4, 1];
      par[2] := RAM[4, 2];
      par[3] := RAM[4, 3];
      par[4] := RAM[4, 4];
      par[5] := false;
      par[6] := false;
      par[7] := false;
      par[8] := false;
      temp := BinToDec();
      ChangeBitAddr := temp;
      if temp <> cMCU_regINDF then
        ChangeRAMBit();
      RAM[cMCU_regINDF, ChangeBitNo] := RAM[ChangeBitAddr, ChangeBitNo];
      exit;
    end;

    if ChangeBitAddr = 4 then // ������� FSR
    Begin
      // !Port
      // ��������, � �� ���� 5-7 �� ����� ��������? (��� ����� ��� ������)
      if (rtMCId < 7) or (rtMCId = 13) then
        if ChangeBitNo > 4 then
          exit; // ���� ��, �� �����
      // ��������, � �� ���� 6-7 �� ����� ��������? (��� ����� c 2 �������)
      if (rtMCId = 7) or (rtMCId = 8) or (rtMCId = 9) then
        if ChangeBitNo > 5 then
          exit; // ���� ��, �� �����
      // ��������, � �� ��� 7 �� ����� ��������? (��� ����� c 4 �������)
      if (rtMCId = 10) or (rtMCId = 11) or (rtMCId = 12) or (rtMCId = 14) then
        if ChangeBitNo > 6 then
          exit; // ���� ��, �� �����
      // �� � �������� ���� ���� � 8 ������� 0 PIC15F59, ��� ���� ������ �� ���� ������
      // ���� ������
      RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;
      // ������� IndF
      par[0] := RAM[cMCU_regFSR, 0];
      par[1] := RAM[cMCU_regFSR, 1];
      par[2] := RAM[cMCU_regFSR, 2];
      par[3] := RAM[cMCU_regFSR, 3];
      par[4] := RAM[cMCU_regFSR, 4];
      if MatrixRAM[cMCU_regFSR].usedbit[5] then
        par[5] := RAM[cMCU_regFSR, 5]
      else
        par[5] := false;
      if MatrixRAM[cMCU_regFSR].usedbit[6] then
        par[6] := RAM[cMCU_regFSR, 6]
      else
        par[6] := false;
      if MatrixRAM[cMCU_regFSR].usedbit[7] then
        par[7] := RAM[cMCU_regFSR, 7]
      else
        par[7] := false;

      temp := BinToDec();
      RAM[cMCU_regINDF, 0] := RAM[temp, 0];
      RAM[cMCU_regINDF, 1] := RAM[temp, 1];
      RAM[cMCU_regINDF, 2] := RAM[temp, 2];
      RAM[cMCU_regINDF, 3] := RAM[temp, 3];
      RAM[cMCU_regINDF, 4] := RAM[temp, 4];
      RAM[cMCU_regINDF, 5] := RAM[temp, 5];
      RAM[cMCU_regINDF, 6] := RAM[temp, 6];
      RAM[cMCU_regINDF, 7] := RAM[temp, 7];
      exit;
    End;

    // ADC
    // ����� - If ADON bit is clear? the GO/\DONE bit cannot be set
    if (ChangeBitAddr = cMCU_regADCON0) and (ChangeBitNo = 1) then
    begin
      if (ChangeBitData = true) and (RAM[cMCU_regADCON0, 0] = false) then
        exit;

    end;

    // ���� ������
    RAM[ChangeBitAddr, ChangeBitNo] := ChangeBitData;

    // ��������, �� ��������� ��� �����. ���������� ��� ��� �������
    if ChangeDataNotInstruction then
    begin
      // �� �����. ����������

      ChangeDataNotInstruction := false;
    end
    else
    begin
      // �� �����. ���������
      if ChangeBitAddr = cMCU_regTMR0 then // TMR0
      begin
        par[0] := RAM[ChangeBitAddr, 0];
        par[1] := RAM[ChangeBitAddr, 1];
        par[2] := RAM[ChangeBitAddr, 2];
        par[3] := RAM[ChangeBitAddr, 3];
        par[4] := RAM[ChangeBitAddr, 4];
        par[5] := RAM[ChangeBitAddr, 5];
        par[6] := RAM[ChangeBitAddr, 6];
        par[7] := RAM[ChangeBitAddr, 7];
        par[8] := false;
        rtTMR0 := BinToDec() * rtKTMR0;
      end;

    end;
  end
  else
  begin
    // �� ������������ ���
  end;

end;

procedure PCLpp(); // ���������� �� 1 �������� PC
label lExit;
begin
  // ������� PCL �� ��������� ����������
  tempPCL[0] := RAM[2, 0];
  tempPCL[1] := RAM[2, 1];
  tempPCL[2] := RAM[2, 2];
  tempPCL[3] := RAM[2, 3];
  tempPCL[4] := RAM[2, 4];
  tempPCL[5] := RAM[2, 5];
  tempPCL[6] := RAM[2, 6];
  tempPCL[7] := RAM[2, 7];

  if PC[0] = false then
  begin
    PC[0] := true;
    goto lExit;
  end
  else
  begin
    PC[0] := false;
    if PC[1] = false then
    begin
      PC[1] := true;
      goto lExit;
    end
    else
    begin
      PC[1] := false;
      if PC[2] = false then
      begin
        PC[2] := true;
        goto lExit;
      end
      else
      begin
        PC[2] := false;
        if PC[3] = false then
        begin
          PC[3] := true;
          goto lExit;
        end
        else
        begin
          PC[3] := false;
          if PC[4] = false then
          begin
            PC[4] := true;
            goto lExit;
          end
          else
          begin
            PC[4] := false;
            if PC[5] = false then
            begin
              PC[5] := true;
              goto lExit;
            end
            else
            begin
              PC[5] := false;
              if PC[6] = false then
              begin
                PC[6] := true;
                goto lExit;
              end
              else
              begin
                PC[6] := false;
                if PC[7] = false then
                begin
                  PC[7] := true;
                  goto lExit;
                end
                else
                begin
                  PC[7] := false;
                  if PC[8] = false then
                  begin
                    PC[8] := true;
                    goto lExit;
                  end
                  else
                  begin
                    PC[8] := false;
                    if cMCU_pcLen > 9 then
                    begin
                      if PC[9] = false then
                      begin
                        PC[9] := true;
                        goto lExit;
                      end
                      else
                      begin
                        PC[9] := false;
                        if cMCU_pcLen > 10 then
                        begin
                          if PC[10] = false then
                          begin
                            PC[10] := true;
                            goto lExit;
                          end
                          else
                          begin
                            PC[10] := false;

                          end;
                        end
                        else
                          goto lExit;

                      end;
                    end
                    else
                      goto lExit;

                  end;

                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;

lExit:
  RAM[2, 0] := PC[0];
  RAM[2, 1] := PC[1];
  RAM[2, 2] := PC[2];
  RAM[2, 3] := PC[3];
  RAM[2, 4] := PC[4];
  RAM[2, 5] := PC[5];
  RAM[2, 6] := PC[6];
  RAM[2, 7] := PC[7];
  // ���������� ������
  MatrixRAM[2].delta := true;
  if tempPCL[0] <> RAM[2, 0] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[0] := true;
  end;
  if tempPCL[1] <> RAM[2, 1] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[1] := true;
  end;
  if tempPCL[2] <> RAM[2, 2] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[2] := true;
  end;
  if tempPCL[3] <> RAM[2, 3] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[3] := true;
  end;
  if tempPCL[4] <> RAM[2, 4] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[4] := true;
  end;
  if tempPCL[5] <> RAM[2, 5] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[5] := true;
  end;
  if tempPCL[6] <> RAM[2, 6] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[6] := true;
  end;
  if tempPCL[7] <> RAM[2, 7] then
  begin
    MatrixRAM[2].greenDelta := false;
    MatrixRAM[2].deltabit[7] := true;
  end;
  // �������� �� ��������� �� ������

  if MatrixRAM[2].BreakPoint then // ������� ��� ������� �����-�����, �� �����
  begin
    rtPause := true;

  end;
end;

procedure ChangeRAMByte(); // ���������� ChangeAddr,ChangeData ������������
var
  CDNI: boolean;
begin
  // ��������� ���� �������� 14.03.2015, ������ ������ � ����� ��������

  ChangeBitAddr := ChangeAddr;
  if ChangeDataNotInstruction then
    CDNI := true
  else
    CDNI := false;
  ChangeBitNo := 0;
  ChangeBitData := �hangeData[0];
  ChangeRAMBit;
  if CDNI then
    ChangeDataNotInstruction := true;
  ChangeBitNo := 1;
  ChangeBitData := �hangeData[1];
  ChangeRAMBit;
  if CDNI then
    ChangeDataNotInstruction := true;
  ChangeBitNo := 2;
  ChangeBitData := �hangeData[2];
  ChangeRAMBit;
  if CDNI then
    ChangeDataNotInstruction := true;
  ChangeBitNo := 3;
  ChangeBitData := �hangeData[3];
  ChangeRAMBit;
  if CDNI then
    ChangeDataNotInstruction := true;
  ChangeBitNo := 4;
  ChangeBitData := �hangeData[4];
  ChangeRAMBit;
  if CDNI then
    ChangeDataNotInstruction := true;
  ChangeBitNo := 5;
  ChangeBitData := �hangeData[5];
  ChangeRAMBit;
  if CDNI then
    ChangeDataNotInstruction := true;
  ChangeBitNo := 6;
  ChangeBitData := �hangeData[6];
  ChangeRAMBit;
  if CDNI then
    ChangeDataNotInstruction := true;
  ChangeBitNo := 7;
  ChangeBitData := �hangeData[7];
  ChangeRAMBit;

end;

function readTSC: int64;
var
  ts: record case byte of 1: (count: int64);
  2: (b, a: cardinal);
end;

begin
  asm
    db $F;
    db $31;
    MOV [ts.a],edx;
    MOV [ts.b],eax;
  end;
  readTSC := ts.count;
end;

function DimensionCPUCyclesPerSecond: int64;
var
  tmpA, tmpB, tmpC: array [0 .. 9] of int64;
  tmpD: int64;
  j: byte;
begin
  timebeginperiod(1); // ������� ������� �������� ����������� ������� �������
  sleep(10); // �������� ������-�� ����� ������ ����
  tmpD := 0;
  for j := 0 to 1 do // ���� 0 �� 9 �� 10.03.2016
  begin
    tmpA[j] := readTSC;
    sleep(100);
    tmpB[j] := readTSC;
    tmpC[j] := tmpB[j] - tmpA[j];
    tmpC[j] := tmpC[j] * 10;
    tmpD := tmpD + tmpC[j];
  end;
  timeEndPeriod(1); // ����������� ��������
  DimensionCPUCyclesPerSecond := tmpD div 2; // ���� div 10 �� 10.03.2016
end;

procedure CLRWDT();
begin
  // ����� WDT
  TaktsWDT := 0;
  // ��������� ��� /TO
  ChangeBitData := true;
  ChangeBitAddr := 3; // STATUS
  ChangeBitNo := 4; // /TO
  ChangeRAMBit;
  if SleepMode then
  begin // ����� SLEEP
    // ������� ��� /PD
    ChangeBitData := false;
    ChangeBitAddr := 3; // STATUS
    ChangeBitNo := 3; // /PD
    ChangeRAMBit;
  end
  else
  begin // ����� CLRWDT
    // ������� ��� /PD
    ChangeBitData := true;
    ChangeBitAddr := 3; // STATUS
    ChangeBitNo := 3; // /PD
    ChangeRAMBit;
  end;

end;

procedure SelectMC(Id: byte); stdcall;
label lblNext;
// ����� ��� ������������� ��� ���������� ��
var
  Z, j: integer;
begin
  rtMCId := Id;
{$REGION '����� ��� ���� ����������� BASELINE'}
  // ������� ������ (��� ���� ����������� BASELINE ���������)
  SystemCommandCounter := 33; // ���������� ������ ����������
  SetLength(SystemCommand, SystemCommandCounter);
  SystemCommand[0].CommandName := 'XORLW';
  SystemCommand[1].CommandName := 'ANDLW';
  SystemCommand[2].CommandName := 'IORLW';
  SystemCommand[3].CommandName := 'MOVLW';
  SystemCommand[4].CommandName := 'GOTO';
  SystemCommand[5].CommandName := 'CALL';
  SystemCommand[6].CommandName := 'RETLW';
  SystemCommand[7].CommandName := 'BTFSS';
  SystemCommand[8].CommandName := 'BTFSC';
  SystemCommand[9].CommandName := 'BSF';
  SystemCommand[10].CommandName := 'BCF';
  SystemCommand[11].CommandName := 'INCFSZ';
  SystemCommand[12].CommandName := 'SWAPF';
  SystemCommand[13].CommandName := 'RLF';
  SystemCommand[14].CommandName := 'RRF';
  SystemCommand[15].CommandName := 'DECFSZ';
  SystemCommand[16].CommandName := 'INCF';
  SystemCommand[17].CommandName := 'COMF';
  SystemCommand[18].CommandName := 'MOVF';
  SystemCommand[19].CommandName := 'ADDWF';
  SystemCommand[20].CommandName := 'XORWF';
  SystemCommand[21].CommandName := 'ANDWF';
  SystemCommand[22].CommandName := 'IORWF';
  SystemCommand[23].CommandName := 'DECF';
  SystemCommand[24].CommandName := 'SUBWF';
  SystemCommand[25].CommandName := 'CLRF';
  SystemCommand[26].CommandName := 'CLRW';
  SystemCommand[27].CommandName := 'MOVWF';
  SystemCommand[28].CommandName := 'TRIS';
  SystemCommand[29].CommandName := 'CLRWDT';
  SystemCommand[30].CommandName := 'SLEEP';
  SystemCommand[31].CommandName := 'OPTION';
  SystemCommand[32].CommandName := 'NOP';
  // 2-�� ��������� ���� (��� ���� ����������� BASELINE -���������)
  stMax := 1;
  // ���-�� ������ ��� ������������ WDT (��� ������������) (��� ���� ����������� BASELINE - ���������)
  rtTaktsWDT := 18000;

  // ��-���������, ������ ���, ���� � �������������� �������� ������������
  // � �����, ��-��������� ��� ���� ����� �����
  for Z := 0 to AllRAMSize do
    for j := 0 to 7 do
    begin
      MatrixRAM[Z].usedbit[j] := true;
      // MatrixRAM[Z].bitname[j]:='';
    end;
{$ENDREGION}
  // �� � ����� � ������ ��� ����� ����� �� ������
  cMCU_regEECON := -1;
  cMCU_regEEDATA := -1;
  cMCU_regEEADR := -1;

  case Id of
    0: // PIC10F200
{$REGION 'PIC10F200'}
      begin
        // ������� ������ �� ���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 9;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 3; // ������� ���� GPIO
        { cMCU_Pin_GP0:=4;
          cMCU_Pin_GP1:=5;
          cMCU_Pin_GP2:=6;
          cMCU_Pin_GP3:=1; }

        cMCU_regCMCON := -1;
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := true; // ����� Fosc/4 �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 256; // ���������� ����� ROM (0..255)

        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ����������� ������
        { �MCU_PinCount:=8;
          �MCU_Pin_Y[1]:=13;
          �MCU_Pin_Y[2]:=31;
          �MCU_Pin_Y[3]:=49;
          �MCU_Pin_Y[4]:=67;
          �MCU_Pin_Y[5]:=67;
          �MCU_Pin_Y[6]:=49;
          �MCU_Pin_Y[7]:=31;
          �MCU_Pin_Y[8]:=13;
          �MCU_Pin_X[1]:=86;
          �MCU_Pin_X[2]:=86;
          �MCU_Pin_X[3]:=86;
          �MCU_Pin_X[4]:=86;
          �MCU_Pin_X[5]:=23;
          �MCU_Pin_X[6]:=23;
          �MCU_Pin_X[7]:=23;
          �MCU_Pin_X[8]:=23; }
        // ���� ������������ ��-���������
        Config[0] := false;
        Config[1] := false;
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 3);
        ConfigBitsCounter := 3;
        ConfigBits[0].Name := 'WDTE';
        ConfigBits[0].DescriptionId := 20;
        ConfigBits[0].No := 2;
        ConfigBits[0].Value0Id := 50;
        ConfigBits[0].Value1Id := 53;
        ConfigBits[1].Name := '\CP';
        ConfigBits[1].DescriptionId := 21;
        ConfigBits[1].No := 3;
        ConfigBits[1].Value0Id := 52;
        ConfigBits[1].Value1Id := 51;
        ConfigBits[2].Name := 'MCLRE';
        ConfigBits[2].DescriptionId := 22;
        ConfigBits[2].No := 4;
        ConfigBits[2].Value0Id := 54;
        ConfigBits[2].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 11;
        GPRCount := 16;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[5] := false;
        MatrixRAM[cMCU_regSTATUS].usedbit[6] := false; // Port!
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        // Port!  MatrixRAM[3].bitname[6]:='CWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';
        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';
        MatrixRAM[cMCU_regOSCCAL].bitname[0] := 'FOSC4';
        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';
        // 7-15 � RAM Unimplemented
        for Z := 7 to 15 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        j := -1;
        // 16-31 � RAM GPR
        for Z := 16 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-255 � RAM Unimplemented
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 8;
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 9;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 10;

      end;
{$ENDREGION}
    1: // PIC10F202
{$REGION 'PIC10F202'}
      begin
        // ������� ������ �� ���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 10;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 3; // ������� ���� GPIO
        cMCU_regCMCON := -1;
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := true; // ����� Fosc/4 �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 512; // ���������� ����� ROM (0..511)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������
        Config[0] := false;
        Config[1] := false;
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 3);
        ConfigBitsCounter := 3;
        ConfigBits[0].Name := 'WDTE';
        ConfigBits[0].DescriptionId := 20;
        ConfigBits[0].No := 2;
        ConfigBits[0].Value0Id := 50;
        ConfigBits[0].Value1Id := 53;
        ConfigBits[1].Name := '\CP';
        ConfigBits[1].DescriptionId := 21;
        ConfigBits[1].No := 3;
        ConfigBits[1].Value0Id := 52;
        ConfigBits[1].Value1Id := 51;
        ConfigBits[2].Name := 'MCLRE';
        ConfigBits[2].DescriptionId := 22;
        ConfigBits[2].No := 4;
        ConfigBits[2].Value0Id := 54;
        ConfigBits[2].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 11;
        GPRCount := 24;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[5] := false;
        MatrixRAM[cMCU_regSTATUS].usedbit[6] := false; // Port!
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        // Port!  MatrixRAM[3].bitname[6]:='CWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';
        MatrixRAM[cMCU_regOSCCAL].bitname[0] := 'FOSC4';
        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';
        // 7 � RAM Unimplemented
        for Z := 7 to 7 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        j := -1;
        // 8-31 � RAM GPR
        for Z := 8 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-255 � RAM Unimplemented
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 8;
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 9;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 10;
      end;
{$ENDREGION}
    2: // PIC10F204
{$REGION 'PIC10F204'}
      begin
        // ������� ������ �� ���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 9;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 3; // ������� ���� GPIO
        cMCU_regCMCON := 7;
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := true; // ����� Fosc/4 �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 256; // ���������� ����� ROM (0..255)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������
        Config[0] := false;
        Config[1] := false;
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 3);
        ConfigBitsCounter := 3;
        ConfigBits[0].Name := 'WDTE';
        ConfigBits[0].DescriptionId := 20;
        ConfigBits[0].No := 2;
        ConfigBits[0].Value0Id := 50;
        ConfigBits[0].Value1Id := 53;
        ConfigBits[1].Name := '\CP';
        ConfigBits[1].DescriptionId := 21;
        ConfigBits[1].No := 3;
        ConfigBits[1].Value0Id := 52;
        ConfigBits[1].Value1Id := 51;
        ConfigBits[2].Name := 'MCLRE';
        ConfigBits[2].DescriptionId := 22;
        ConfigBits[2].No := 4;
        ConfigBits[2].Value0Id := 54;
        ConfigBits[2].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 12;
        GPRCount := 16;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[5] := false;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[6] := 'CWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';
        MatrixRAM[cMCU_regOSCCAL].bitname[0] := 'FOSC4';
        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';
        // 7 � RAM 8 � SFR
        MatrixRAM[cMCU_regCMCON].Used := true;
        MatrixRAM[cMCU_regCMCON].SFR := true;
        MatrixRAM[cMCU_regCMCON].VirtSFR := false;
        MatrixRAM[cMCU_regCMCON].IDEName := 'CMCON0';
        MatrixRAM[cMCU_regCMCON].IDEHexaddres := '007';
        MatrixRAM[cMCU_regCMCON].IDEaddres := 8;
        MatrixRAM[cMCU_regCMCON].bitname[7] := 'CMPOUT';
        MatrixRAM[cMCU_regCMCON].bitname[6] := '\COUTEN';
        MatrixRAM[cMCU_regCMCON].bitname[5] := 'POL';
        MatrixRAM[cMCU_regCMCON].bitname[4] := '\CMPT0CS';
        MatrixRAM[cMCU_regCMCON].bitname[3] := 'CMPON';
        MatrixRAM[cMCU_regCMCON].bitname[2] := 'CNREF';
        MatrixRAM[cMCU_regCMCON].bitname[1] := 'CPREF';
        MatrixRAM[cMCU_regCMCON].bitname[0] := '\CWU';
        // 7-15 � RAM Unimplemented
        for Z := 8 to 15 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        j := -1;
        // 16-31 � RAM GPR
        for Z := 16 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;

        // 32-255 � RAM Unimplemented
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 9;
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 10;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 11;

      end;
{$ENDREGION}
    3: // PIC10F206
{$REGION 'PIC10F206'}
      begin
        // ������� ������ �� ���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 10;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 3; // ������� ���� GPIO
        cMCU_regCMCON := 7;
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := true; // ����� Fosc/4 �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 512; // ���������� ����� ROM (0..511)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������
        Config[0] := false;
        Config[1] := false;
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 3);
        ConfigBitsCounter := 3;
        ConfigBits[0].Name := 'WDTE';
        ConfigBits[0].DescriptionId := 20;
        ConfigBits[0].No := 2;
        ConfigBits[0].Value0Id := 50;
        ConfigBits[0].Value1Id := 53;
        ConfigBits[1].Name := '\CP';
        ConfigBits[1].DescriptionId := 21;
        ConfigBits[1].No := 3;
        ConfigBits[1].Value0Id := 52;
        ConfigBits[1].Value1Id := 51;
        ConfigBits[2].Name := 'MCLRE';
        ConfigBits[2].DescriptionId := 22;
        ConfigBits[2].No := 4;
        ConfigBits[2].Value0Id := 54;
        ConfigBits[2].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 12;
        GPRCount := 24;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[5] := false;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[6] := 'CWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';
        MatrixRAM[cMCU_regOSCCAL].bitname[0] := 'FOSC4';
        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';
        // 7 � RAM 8 � SFR
        MatrixRAM[cMCU_regCMCON].Used := true;
        MatrixRAM[cMCU_regCMCON].SFR := true;
        MatrixRAM[cMCU_regCMCON].VirtSFR := false;
        MatrixRAM[cMCU_regCMCON].IDEName := 'CMCON0';
        MatrixRAM[cMCU_regCMCON].IDEHexaddres := '007';
        MatrixRAM[cMCU_regCMCON].IDEaddres := 8;
        MatrixRAM[cMCU_regCMCON].bitname[7] := 'CMPOUT';
        MatrixRAM[cMCU_regCMCON].bitname[6] := '\COUTEN';
        MatrixRAM[cMCU_regCMCON].bitname[5] := 'POL';
        MatrixRAM[cMCU_regCMCON].bitname[4] := '\CMPT0CS';
        MatrixRAM[cMCU_regCMCON].bitname[3] := 'CMPON';
        MatrixRAM[cMCU_regCMCON].bitname[2] := 'CNREF';
        MatrixRAM[cMCU_regCMCON].bitname[1] := 'CPREF';
        MatrixRAM[cMCU_regCMCON].bitname[0] := '\CWU';

        j := -1;
        // 8-31 � RAM GPR
        for Z := 8 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-255 � RAM Unimplemented
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 9;
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 10;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 11;
      end;
{$ENDREGION}
    4: // PIC10F220
{$REGION 'PIC10F220'}
      begin
        // ������� ������ �� ���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 9;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 3; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := 7; // ���
        cMCU_regADRES := 8; // ���
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := true; // ����� Fosc/4 �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 256; // ���������� ����� ROM (0..255)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������
        Config[0] := false; // Internal Oscillator Frequency Select bit = 4 Mhz
        Config[1] := false; // Master Clear Pull-up is disabled
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 5);
        ConfigBitsCounter := 5;
        ConfigBits[0].Name := 'IOSCFS';
        ConfigBits[0].DescriptionId := 23;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 56;
        ConfigBits[0].Value1Id := 57;
        ConfigBits[1].Name := '\MCPU';
        ConfigBits[1].DescriptionId := 24;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 58;
        ConfigBits[1].Value1Id := 59;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;
        ConfigBits[4].Name := 'MCLRE';
        ConfigBits[4].DescriptionId := 22;
        ConfigBits[4].No := 4;
        ConfigBits[4].Value0Id := 54;
        ConfigBits[4].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 13;
        GPRCount := 16;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[5] := false;
        MatrixRAM[cMCU_regSTATUS].usedbit[6] := false;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';
        MatrixRAM[cMCU_regOSCCAL].bitname[0] := 'FOSC4';
        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';
        // 7 � RAM 8 � SFR
        MatrixRAM[cMCU_regADCON0].Used := true;
        MatrixRAM[cMCU_regADCON0].SFR := true;
        MatrixRAM[cMCU_regADCON0].VirtSFR := false;
        MatrixRAM[cMCU_regADCON0].IDEName := 'ADCON0';
        MatrixRAM[cMCU_regADCON0].IDEHexaddres := '007';
        MatrixRAM[cMCU_regADCON0].IDEaddres := 8;
        MatrixRAM[cMCU_regADCON0].bitname[7] := 'ANS1';
        MatrixRAM[cMCU_regADCON0].bitname[6] := 'ANS0';
        MatrixRAM[cMCU_regADCON0].usedbit[5] := false;
        MatrixRAM[cMCU_regADCON0].usedbit[4] := false;
        MatrixRAM[cMCU_regADCON0].bitname[3] := 'CHS1';
        MatrixRAM[cMCU_regADCON0].bitname[2] := 'CHS0';
        MatrixRAM[cMCU_regADCON0].bitname[1] := 'GO/\DONE';
        MatrixRAM[cMCU_regADCON0].bitname[0] := 'ADON';
        // 8 � RAM 9 � SFR
        MatrixRAM[cMCU_regADRES].Used := true;
        MatrixRAM[cMCU_regADRES].SFR := true;
        MatrixRAM[cMCU_regADRES].VirtSFR := false;
        MatrixRAM[cMCU_regADRES].IDEName := 'ADRES';
        MatrixRAM[cMCU_regADRES].IDEHexaddres := '008';
        MatrixRAM[cMCU_regADRES].IDEaddres := 9;
        // 9-15 � RAM Unimplemented
        for Z := 9 to 15 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        j := -1;
        // 16-31 � RAM GPR
        for Z := 16 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-255 � RAM Unimplemented
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 10;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 11;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 12;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    5: // PIC10F222
{$REGION 'PIC10F222'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 10;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 3; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := 7; // ���
        cMCU_regADRES := 8; // ���
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := true; // ����� Fosc/4 �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 512; // ���������� ����� ROM (0..511)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������
        Config[0] := false; // Internal Oscillator Frequency Select bit = 4 Mhz
        Config[1] := false; // Master Clear Pull-up is disabled
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 5);
        ConfigBitsCounter := 5;
        ConfigBits[0].Name := 'IOSCFS';
        ConfigBits[0].DescriptionId := 23;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 56;
        ConfigBits[0].Value1Id := 57;
        ConfigBits[1].Name := '\MCPU';
        ConfigBits[1].DescriptionId := 24;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 58;
        ConfigBits[1].Value1Id := 59;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;
        ConfigBits[4].Name := 'MCLRE';
        ConfigBits[4].DescriptionId := 22;
        ConfigBits[4].No := 4;
        ConfigBits[4].Value0Id := 54;
        ConfigBits[4].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 13;
        GPRCount := 23;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[5] := false;
        MatrixRAM[cMCU_regSTATUS].usedbit[6] := false;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';
        MatrixRAM[cMCU_regOSCCAL].bitname[0] := 'FOSC4';
        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';
        // 7 � RAM 8 � SFR
        MatrixRAM[cMCU_regADCON0].Used := true;
        MatrixRAM[cMCU_regADCON0].SFR := true;
        MatrixRAM[cMCU_regADCON0].VirtSFR := false;
        MatrixRAM[cMCU_regADCON0].IDEName := 'ADCON0';
        MatrixRAM[cMCU_regADCON0].IDEHexaddres := '007';
        MatrixRAM[cMCU_regADCON0].IDEaddres := 8;
        MatrixRAM[cMCU_regADCON0].bitname[7] := 'ANS1';
        MatrixRAM[cMCU_regADCON0].bitname[6] := 'ANS0';
        MatrixRAM[cMCU_regADCON0].usedbit[5] := false;
        MatrixRAM[cMCU_regADCON0].usedbit[4] := false;
        MatrixRAM[cMCU_regADCON0].bitname[3] := 'CHS1';
        MatrixRAM[cMCU_regADCON0].bitname[2] := 'CHS0';
        MatrixRAM[cMCU_regADCON0].bitname[1] := 'GO/\DONE';
        MatrixRAM[cMCU_regADCON0].bitname[0] := 'ADON';
        // 8 � RAM 9 � SFR
        MatrixRAM[cMCU_regADRES].Used := true;
        MatrixRAM[cMCU_regADRES].SFR := true;
        MatrixRAM[cMCU_regADRES].VirtSFR := false;
        MatrixRAM[cMCU_regADRES].IDEName := 'ADRES';
        MatrixRAM[cMCU_regADRES].IDEHexaddres := '008';
        MatrixRAM[cMCU_regADRES].IDEaddres := 9;

        j := -1;
        // 9-31 � RAM GPR
        for Z := 9 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-255 � RAM Unimplemented
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 10;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 11;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[4] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 12;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    6: // PIC12F508
{$REGION 'PIC12F508'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 10;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 5; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := false; // ����� Fosc/4 �� �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 512; // ���������� ����� ROM (0..511)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������
        Config[0] := false; // Internal Oscillator Frequency Select bit = 4 Mhz
        Config[1] := true; // -//-
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 5);
        ConfigBitsCounter := 5;
        ConfigBits[0].Name := 'FOSC0';
        ConfigBits[0].DescriptionId := 25;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 60;
        ConfigBits[0].Value1Id := 61;
        ConfigBits[1].Name := 'FOSC1';
        ConfigBits[1].DescriptionId := 25;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 60;
        ConfigBits[1].Value1Id := 61;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;
        ConfigBits[4].Name := 'MCLRE';
        ConfigBits[4].DescriptionId := 22;
        ConfigBits[4].No := 4;
        ConfigBits[4].Value0Id := 54;
        ConfigBits[4].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 11;
        GPRCount := 25;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[5] := false;
        MatrixRAM[cMCU_regSTATUS].usedbit[6] := false; // ����� � 505!!
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].usedbit[0] := false;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';

        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].bitname[5] := 'GP5';
        MatrixRAM[cMCU_regGPIO].bitname[4] := 'GP4';
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';

        j := -1;
        // 7-31 � RAM GPR
        for Z := 7 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-255 � RAM Unimplemented
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 8;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 9;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;

        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 10;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    7: // PIC12F509
{$REGION 'PIC12F509'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 11;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 5; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := false; // ����� Fosc/4 �� �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 1024; // ���������� ����� ROM (0..1023)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������
        Config[0] := false; // Internal Oscillator Frequency Select bit = 4 Mhz
        Config[1] := true; // -//-
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;
        // ��������� ����� ������������
        SetLength(ConfigBits, 5);
        ConfigBitsCounter := 5;
        ConfigBits[0].Name := 'FOSC0';
        ConfigBits[0].DescriptionId := 25;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 60;
        ConfigBits[0].Value1Id := 61;
        ConfigBits[1].Name := 'FOSC1';
        ConfigBits[1].DescriptionId := 25;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 60;
        ConfigBits[1].Value1Id := 61;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;
        ConfigBits[4].Name := 'MCLRE';
        ConfigBits[4].DescriptionId := 22;
        ConfigBits[4].No := 4;
        ConfigBits[4].Value0Id := 54;
        ConfigBits[4].Value1Id := 55;

        // ����� ���-�� GPR u SFR
        SFRCount := 11;
        GPRCount := 41;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[6] := false; // ����� � 505!!
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[5] := 'PA0';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].usedbit[0] := false;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';

        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].bitname[5] := 'GP5';
        MatrixRAM[cMCU_regGPIO].bitname[4] := 'GP4';
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';

        j := -1;
        // 7-31 � RAM GPR
        for Z := 7 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-47 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 32 to 47 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 46-63 � RAM GPR (2-� ����)
        for Z := 48 to 63 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 64-255 � RAM Unimplemented
        for Z := 64 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 8;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 9;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;

        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 10;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    8: // PIC12F510
{$REGION 'PIC12F510'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 10;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 5; // ������� ���� GPIO
        cMCU_regCMCON := 7; // ���������� ������������
        cMCU_regADCON0 := 8; // ��� ������������
        cMCU_regADRES := 9; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := false; // ����� Fosc/4 �� �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE
        ROM_Size := 1024; // ���������� ����� ROM (0..1023)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������

        Config[0] := false; // INTOSC Select bit
        Config[1] := true; // -//-
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false; // IOSCFS = 4Mhz
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;

        // ��������� ����� ������������
        SetLength(ConfigBits, 5);
        ConfigBitsCounter := 5;
        ConfigBits[0].Name := 'FOSC0';
        ConfigBits[0].DescriptionId := 25;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 60;
        ConfigBits[0].Value1Id := 61;
        ConfigBits[1].Name := 'FOSC1';
        ConfigBits[1].DescriptionId := 25;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 60;
        ConfigBits[1].Value1Id := 61;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;
        ConfigBits[4].Name := 'MCLRE';
        ConfigBits[4].DescriptionId := 22;
        ConfigBits[4].No := 4;
        ConfigBits[4].Value0Id := 54;
        ConfigBits[4].Value1Id := 55;
        ConfigBits[5].Name := 'IOSCFS';
        ConfigBits[5].DescriptionId := 23;
        ConfigBits[5].No := 5;
        ConfigBits[5].Value0Id := 56;
        ConfigBits[5].Value1Id := 57;
        // ����� ���-�� GPR u SFR
        SFRCount := 14;
        GPRCount := 38;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[6] := 'CWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[5] := 'PA0';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].usedbit[0] := false;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';

        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].bitname[5] := 'GP5';
        MatrixRAM[cMCU_regGPIO].bitname[4] := 'GP4';
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';

        // 7 � RAM 8 � SFR
        MatrixRAM[cMCU_regCMCON].Used := true;
        MatrixRAM[cMCU_regCMCON].SFR := true;
        MatrixRAM[cMCU_regCMCON].VirtSFR := false;
        MatrixRAM[cMCU_regCMCON].IDEName := 'CM1CON0';
        MatrixRAM[cMCU_regCMCON].IDEHexaddres := '007';
        MatrixRAM[cMCU_regCMCON].IDEaddres := 8;
        MatrixRAM[cMCU_regCMCON].bitname[7] := 'C1OUT';
        MatrixRAM[cMCU_regCMCON].bitname[6] := '\C1OUTEN';
        MatrixRAM[cMCU_regCMCON].bitname[5] := 'C1POL';
        MatrixRAM[cMCU_regCMCON].bitname[4] := '\C1T0CS';
        MatrixRAM[cMCU_regCMCON].bitname[3] := 'C1ON';
        MatrixRAM[cMCU_regCMCON].bitname[2] := 'C1NREF';
        MatrixRAM[cMCU_regCMCON].bitname[1] := 'C1PREF';
        MatrixRAM[cMCU_regCMCON].bitname[0] := '\C1WU';
        // 8 � RAM 9 � SFR
        MatrixRAM[cMCU_regADCON0].Used := true;
        MatrixRAM[cMCU_regADCON0].SFR := true;
        MatrixRAM[cMCU_regADCON0].VirtSFR := false;
        MatrixRAM[cMCU_regADCON0].IDEName := 'ADCON0';
        MatrixRAM[cMCU_regADCON0].IDEHexaddres := '008';
        MatrixRAM[cMCU_regADCON0].IDEaddres := 9;
        MatrixRAM[cMCU_regADCON0].bitname[7] := 'ANS1';
        MatrixRAM[cMCU_regADCON0].bitname[6] := 'ANS0';
        MatrixRAM[cMCU_regADCON0].bitname[5] := 'ADCS1';
        MatrixRAM[cMCU_regADCON0].bitname[4] := 'ADCS0';
        MatrixRAM[cMCU_regADCON0].bitname[3] := 'CHS1';
        MatrixRAM[cMCU_regADCON0].bitname[2] := 'CHS0';
        MatrixRAM[cMCU_regADCON0].bitname[1] := 'GO/\DONE';
        MatrixRAM[cMCU_regADCON0].bitname[0] := 'ADON';
        // 9 � RAM 10 � SFR
        MatrixRAM[cMCU_regADRES].Used := true;
        MatrixRAM[cMCU_regADRES].SFR := true;
        MatrixRAM[cMCU_regADRES].VirtSFR := false;
        MatrixRAM[cMCU_regADRES].IDEName := 'ADRES';
        MatrixRAM[cMCU_regADRES].IDEHexaddres := '009';
        MatrixRAM[cMCU_regADRES].IDEaddres := 10;
        j := -1;
        // 10-31 � RAM GPR
        for Z := 10 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-47 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 32 to 47 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 48-63 � RAM GPR (2-� ����)
        for Z := 48 to 63 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 64-255 � RAM Unimplemented
        for Z := 64 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 11;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 12;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;

        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 13;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    9: // PIC12F519
{$REGION 'PIC12F519'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 11;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := 5;
        cMCU_regGPIO := 6;
        cMCU_hiGPIO := 5; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := true; // ���� GPIO �������
        cMCU_avFosc4Out := false; // ����� Fosc/4 �� �������
        cMCU_portT0CKI := 2; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 3; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := 4; // ����� ���� ������������ MCLRE

        cMCU_regEECON := 33;
        cMCU_regEEDATA := 37;
        cMCU_regEEADR := 38;

        ROM_Size := 1024; // ���������� ����� ROM (0..1023)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������

        Config[0] := false; // INTOSC Select bit
        Config[1] := true; // -//-
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false; // GP3/\MCLR Pin function is GP3
        Config[5] := false; // IOSCFS = 4Mhz
        Config[6] := true; // Code protection off (EEPROM)
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;

        // ��������� ����� ������������
        SetLength(ConfigBits, 5);
        ConfigBitsCounter := 5;
        ConfigBits[0].Name := 'FOSC0';
        ConfigBits[0].DescriptionId := 25;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 60;
        ConfigBits[0].Value1Id := 61;
        ConfigBits[1].Name := 'FOSC1';
        ConfigBits[1].DescriptionId := 25;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 60;
        ConfigBits[1].Value1Id := 61;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;
        ConfigBits[4].Name := 'MCLRE';
        ConfigBits[4].DescriptionId := 22;
        ConfigBits[4].No := 4;
        ConfigBits[4].Value0Id := 54;
        ConfigBits[4].Value1Id := 55;
        ConfigBits[5].Name := 'IOSCFS';
        ConfigBits[5].DescriptionId := 23;
        ConfigBits[5].No := 5;
        ConfigBits[5].Value0Id := 56;
        ConfigBits[5].Value1Id := 57;

        ConfigBits[6].Name := '\CPDF';
        ConfigBits[6].DescriptionId := 26;
        ConfigBits[6].No := 6;
        ConfigBits[6].Value0Id := 52;
        ConfigBits[6].Value1Id := 51;
        // ����� ���-�� GPR u SFR
        SFRCount := 14;
        GPRCount := 41;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].usedbit[6] := false; //
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'GPWUF';
        MatrixRAM[cMCU_regSTATUS].bitname[5] := 'PA0';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;

        // 5 � RAM 6 � SFR
        // OSCCAL
        MatrixRAM[cMCU_regOSCCAL].Used := true;
        MatrixRAM[cMCU_regOSCCAL].usedbit[0] := false;
        MatrixRAM[cMCU_regOSCCAL].SFR := true;
        MatrixRAM[cMCU_regOSCCAL].VirtSFR := false;
        MatrixRAM[cMCU_regOSCCAL].IDEName := 'OSCCAL';
        MatrixRAM[cMCU_regOSCCAL].IDEHexaddres := '005';
        MatrixRAM[cMCU_regOSCCAL].IDEaddres := 6;
        MatrixRAM[cMCU_regOSCCAL].bitname[7] := 'CAL6';
        MatrixRAM[cMCU_regOSCCAL].bitname[6] := 'CAL5';
        MatrixRAM[cMCU_regOSCCAL].bitname[5] := 'CAL4';
        MatrixRAM[cMCU_regOSCCAL].bitname[4] := 'CAL3';
        MatrixRAM[cMCU_regOSCCAL].bitname[3] := 'CAL2';
        MatrixRAM[cMCU_regOSCCAL].bitname[2] := 'CAL1';
        MatrixRAM[cMCU_regOSCCAL].bitname[1] := 'CAL0';

        // 6 � RAM 7 � SFR
        // GPIO
        MatrixRAM[cMCU_regGPIO].Used := true;
        MatrixRAM[cMCU_regGPIO].SFR := true;
        MatrixRAM[cMCU_regGPIO].VirtSFR := false;
        MatrixRAM[cMCU_regGPIO].IDEName := 'GPIO';
        MatrixRAM[cMCU_regGPIO].IDEHexaddres := '006';
        MatrixRAM[cMCU_regGPIO].IDEaddres := 7;
        MatrixRAM[cMCU_regGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regGPIO].usedbit[6] := false;
        MatrixRAM[cMCU_regGPIO].bitname[5] := 'GP5';
        MatrixRAM[cMCU_regGPIO].bitname[4] := 'GP4';
        MatrixRAM[cMCU_regGPIO].bitname[3] := 'GP3';
        MatrixRAM[cMCU_regGPIO].bitname[2] := 'GP2';
        MatrixRAM[cMCU_regGPIO].bitname[1] := 'GP1';
        MatrixRAM[cMCU_regGPIO].bitname[0] := 'GP0';

        // 7 � RAM 8 � SFR
        MatrixRAM[cMCU_regEECON].Used := true;
        MatrixRAM[cMCU_regEECON].SFR := true;
        MatrixRAM[cMCU_regEECON].VirtSFR := false;
        MatrixRAM[cMCU_regEECON].IDEName := 'EECON';
        MatrixRAM[cMCU_regEECON].IDEHexaddres := '021';
        MatrixRAM[cMCU_regEECON].IDEaddres := 8;
        MatrixRAM[cMCU_regEECON].usedbit[7] := false;
        MatrixRAM[cMCU_regEECON].usedbit[6] := false;
        MatrixRAM[cMCU_regEECON].usedbit[5] := false;
        MatrixRAM[cMCU_regEECON].bitname[4] := 'FREE';
        MatrixRAM[cMCU_regEECON].bitname[3] := 'WRERR';
        MatrixRAM[cMCU_regEECON].bitname[2] := 'WREN';
        MatrixRAM[cMCU_regEECON].bitname[1] := 'WR';
        MatrixRAM[cMCU_regEECON].bitname[0] := 'RD';
        // 8 � RAM 9 � SFR
        MatrixRAM[cMCU_regEEDATA].Used := true;
        MatrixRAM[cMCU_regEEDATA].SFR := true;
        MatrixRAM[cMCU_regEEDATA].VirtSFR := false;
        MatrixRAM[cMCU_regEEDATA].IDEName := 'EEDATA';
        MatrixRAM[cMCU_regEEDATA].IDEHexaddres := '025';
        MatrixRAM[cMCU_regEEDATA].IDEaddres := 9;
        MatrixRAM[cMCU_regEEDATA].bitname[7] := 'EEDATA7';
        MatrixRAM[cMCU_regEEDATA].bitname[6] := 'EEDATA6';
        MatrixRAM[cMCU_regEEDATA].bitname[5] := 'EEDATA5';
        MatrixRAM[cMCU_regEEDATA].bitname[4] := 'EEDATA4';
        MatrixRAM[cMCU_regEEDATA].bitname[3] := 'EEDATA3';
        MatrixRAM[cMCU_regEEDATA].bitname[2] := 'EEDATA2';
        MatrixRAM[cMCU_regEEDATA].bitname[1] := 'EEDATA1';
        MatrixRAM[cMCU_regEEDATA].bitname[0] := 'EEDATA0';
        // 9 � RAM 10 � SFR
        MatrixRAM[cMCU_regEEADR].Used := true;
        MatrixRAM[cMCU_regEEADR].SFR := true;
        MatrixRAM[cMCU_regEEADR].VirtSFR := false;
        MatrixRAM[cMCU_regEEADR].IDEName := 'EEADR';
        MatrixRAM[cMCU_regEEADR].IDEHexaddres := '026';
        MatrixRAM[cMCU_regEEADR].IDEaddres := 10;
        MatrixRAM[cMCU_regEEADR].usedbit[7] := false;
        MatrixRAM[cMCU_regEEADR].usedbit[6] := false;
        MatrixRAM[cMCU_regEEADR].bitname[5] := 'EEADR5';
        MatrixRAM[cMCU_regEEADR].bitname[4] := 'EEADR4';
        MatrixRAM[cMCU_regEEADR].bitname[3] := 'EEADR3';
        MatrixRAM[cMCU_regEEADR].bitname[2] := 'EEADR2';
        MatrixRAM[cMCU_regEEADR].bitname[1] := 'EEADR1';
        MatrixRAM[cMCU_regEEADR].bitname[0] := 'EEADR0';
        j := -1;
        // 7-31 � RAM GPR
        for Z := 7 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-47 (���� 33,37,38) � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 32 to 47 do
        begin
          if (Z = 33) or (Z = 37) or (Z = 38) then
            goto lblNext;

          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        lblNext:
        end;
        // 48-63 � RAM GPR (2-� ����)
        for Z := 48 to 63 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 64-255 � RAM Unimplemented
        for Z := 64 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 259-263 � RAM Unimplemented
        for Z := 259 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (33) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 11;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].bitname[7] := '\GPWU';
        MatrixRAM[cMCU_regOPTION].bitname[6] := '\GPPU';
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISGPIO (34) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISGPIO].Used := true;
        MatrixRAM[cMCU_regTRISGPIO].SFR := true;
        MatrixRAM[cMCU_regTRISGPIO].VirtSFR := true;
        MatrixRAM[cMCU_regTRISGPIO].IDEName := 'TRISGPIO';
        MatrixRAM[cMCU_regTRISGPIO].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISGPIO].IDEaddres := 12;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISGPIO].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISGPIO].usedbit[6] := false;

        MatrixRAM[cMCU_regTRISGPIO].usedbit[3] := false;

        // TMR0 Prescaler (35) � RAM 9 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 13;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    13: // PIC16F54
{$REGION 'PIC16F54'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 9;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := -1; // ����������� � ���� 5�
        cMCU_regGPIO := -1; // ����������� � ���� 5�
        cMCU_regPORTA := 5; // PortA
        cMCU_regPORTB := 6; // PortB
        cMCU_regPORTC := -1; // PortC
        cMCU_regPORTD := -1; // PortD
        cMCU_regPORTE := -1; // PortE
        cMCU_hiPORTA := 3; // Hi PortA
        cMCU_hiPORTB := 7; // Hi PortB
        cMCU_hiPORTC := -1; // Hi PortC
        cMCU_hiPORTD := -1; // Hi PortD
        cMCU_hiPORTE := -1; // Hi PortE
        cMCU_hiGPIO := -1; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := false; // ���� GPIO �� �������
        cMCU_avFosc4Out := false; // ����� Fosc/4 �� �������

        cMCU_portT0CKI := 12; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 13; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := -1; // ����� ���� ������������ MCLRE
        ROM_Size := 512; // ���������� ����� ROM (0..1023)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������

        Config[0] := false; // INTOSC Select bit (HS)
        Config[1] := true; // -//-
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false;
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;

        // ��������� ����� ������������
        SetLength(ConfigBits, 4);
        ConfigBitsCounter := 4;
        ConfigBits[0].Name := 'FOSC0';
        ConfigBits[0].DescriptionId := 25;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 60;
        ConfigBits[0].Value1Id := 61;
        ConfigBits[1].Name := 'FOSC1';
        ConfigBits[1].DescriptionId := 25;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 60;
        ConfigBits[1].Value1Id := 61;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;

        SFRCount := 12;
        GPRCount := 25;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'PA2';
        MatrixRAM[cMCU_regSTATUS].bitname[6] := 'PA1';
        MatrixRAM[cMCU_regSTATUS].bitname[5] := 'PA0';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������
        MatrixRAM[cMCU_regFSR].usedbit[6] := false;
        MatrixRAM[cMCU_regFSR].usedbit[5] := false;

        // 5 � RAM 6 � SFR
        // PORTA

        MatrixRAM[cMCU_regPORTA].Used := true;
        MatrixRAM[cMCU_regPORTA].usedbit[7] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[6] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[5] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[4] := false;
        MatrixRAM[cMCU_regPORTA].SFR := true;
        MatrixRAM[cMCU_regPORTA].VirtSFR := false;
        MatrixRAM[cMCU_regPORTA].IDEName := 'PORTA';
        MatrixRAM[cMCU_regPORTA].IDEHexaddres := '005';
        MatrixRAM[cMCU_regPORTA].IDEaddres := 6;
        MatrixRAM[cMCU_regPORTA].bitname[3] := 'PA3';
        MatrixRAM[cMCU_regPORTA].bitname[2] := 'PA2';
        MatrixRAM[cMCU_regPORTA].bitname[1] := 'PA1';
        MatrixRAM[cMCU_regPORTA].bitname[0] := 'PA0';

        // 6 � RAM 7 � SFR
        // PORTB
        MatrixRAM[cMCU_regPORTB].Used := true;
        MatrixRAM[cMCU_regPORTB].SFR := true;
        MatrixRAM[cMCU_regPORTB].VirtSFR := false;
        MatrixRAM[cMCU_regPORTB].IDEName := 'PORTB';
        MatrixRAM[cMCU_regPORTB].IDEHexaddres := '006';
        MatrixRAM[cMCU_regPORTB].IDEaddres := 7;
        MatrixRAM[cMCU_regPORTB].bitname[7] := 'PB7';
        MatrixRAM[cMCU_regPORTB].bitname[6] := 'PB6';
        MatrixRAM[cMCU_regPORTB].bitname[5] := 'PB5';
        MatrixRAM[cMCU_regPORTB].bitname[4] := 'PB4';
        MatrixRAM[cMCU_regPORTB].bitname[3] := 'PB3';
        MatrixRAM[cMCU_regPORTB].bitname[2] := 'PB2';
        MatrixRAM[cMCU_regPORTB].bitname[1] := 'PB1';
        MatrixRAM[cMCU_regPORTB].bitname[0] := 'PB0';

        j := -1;
        // 7-31 � RAM GPR
        for Z := 7 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 32-255 � RAM Unimplemented?
        for Z := 32 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 258 � RAM Unimplemented
        MatrixRAM[258].Used := false;
        MatrixRAM[258].SFR := false;
        MatrixRAM[258].VirtSFR := false;
        MatrixRAM[258].IDEName := '';
        MatrixRAM[258].IDEHexaddres := '';
        MatrixRAM[258].IDEaddres := -1;
        // 261-263 � RAM Unimplemented
        for Z := 261 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (257) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 8;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].usedbit[7] := false;
        MatrixRAM[cMCU_regOPTION].usedbit[6] := false;
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISA (259) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISA].Used := true;
        MatrixRAM[cMCU_regTRISA].SFR := true;
        MatrixRAM[cMCU_regTRISA].VirtSFR := true;
        MatrixRAM[cMCU_regTRISA].IDEName := 'TRISA';
        MatrixRAM[cMCU_regTRISA].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISA].IDEaddres := 9;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISA].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[4] := false;

        // regTRISA (259) � RAM 10 � SFR

        MatrixRAM[cMCU_regTRISB].Used := true;
        MatrixRAM[cMCU_regTRISB].SFR := true;
        MatrixRAM[cMCU_regTRISB].VirtSFR := true;
        MatrixRAM[cMCU_regTRISB].IDEName := 'TRISB';
        MatrixRAM[cMCU_regTRISB].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISB].IDEaddres := 10;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!

        // TMR0 Prescaler (35) � RAM 11 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 11;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    14: // PIC16F57
{$REGION 'PIC16F57'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 11;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := -1; // ����������� � ���� 5�
        cMCU_regGPIO := -1; // ����������� � ���� 5�
        cMCU_regPORTA := 5; // PortA
        cMCU_regPORTB := 6; // PortB
        cMCU_regPORTC := 7; // PortC
        cMCU_regPORTD := -1; // PortD
        cMCU_regPORTE := -1; // PortE
        cMCU_hiPORTA := 3; // Hi PortA
        cMCU_hiPORTB := 7; // Hi PortB
        cMCU_hiPORTC := 7; // Hi PortC
        cMCU_hiPORTD := -1; // Hi PortD
        cMCU_hiPORTE := -1; // Hi PortE
        cMCU_hiGPIO := -1; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := false; // ���� GPIO �� �������
        cMCU_avFosc4Out := false; // ����� Fosc/4 �� �������

        cMCU_portT0CKI := 20; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 21; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := -1; // ����� ���� ������������ MCLRE
        ROM_Size := 2048; // ���������� ����� ROM (0..2047)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������

        Config[0] := false; // INTOSC Select bit (HS)
        Config[1] := true; // -//-
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false;
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;

        // ��������� ����� ������������
        SetLength(ConfigBits, 4);
        ConfigBitsCounter := 4;
        ConfigBits[0].Name := 'FOSC0';
        ConfigBits[0].DescriptionId := 25;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 60;
        ConfigBits[0].Value1Id := 61;
        ConfigBits[1].Name := 'FOSC1';
        ConfigBits[1].DescriptionId := 25;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 60;
        ConfigBits[1].Value1Id := 61;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;

        SFRCount := 14;
        GPRCount := 72;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'PA2';
        MatrixRAM[cMCU_regSTATUS].bitname[6] := 'PA1';
        MatrixRAM[cMCU_regSTATUS].bitname[5] := 'PA0';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������


        // 5 � RAM 6 � SFR
        // PORTA

        MatrixRAM[cMCU_regPORTA].Used := true;
        MatrixRAM[cMCU_regPORTA].usedbit[7] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[6] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[5] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[4] := false;
        MatrixRAM[cMCU_regPORTA].SFR := true;
        MatrixRAM[cMCU_regPORTA].VirtSFR := false;
        MatrixRAM[cMCU_regPORTA].IDEName := 'PORTA';
        MatrixRAM[cMCU_regPORTA].IDEHexaddres := '005';
        MatrixRAM[cMCU_regPORTA].IDEaddres := 6;
        MatrixRAM[cMCU_regPORTA].bitname[3] := 'PA3';
        MatrixRAM[cMCU_regPORTA].bitname[2] := 'PA2';
        MatrixRAM[cMCU_regPORTA].bitname[1] := 'PA1';
        MatrixRAM[cMCU_regPORTA].bitname[0] := 'PA0';

        // 6 � RAM 7 � SFR
        // PORTB
        MatrixRAM[cMCU_regPORTB].Used := true;
        MatrixRAM[cMCU_regPORTB].SFR := true;
        MatrixRAM[cMCU_regPORTB].VirtSFR := false;
        MatrixRAM[cMCU_regPORTB].IDEName := 'PORTB';
        MatrixRAM[cMCU_regPORTB].IDEHexaddres := '006';
        MatrixRAM[cMCU_regPORTB].IDEaddres := 7;
        MatrixRAM[cMCU_regPORTB].bitname[7] := 'PB7';
        MatrixRAM[cMCU_regPORTB].bitname[6] := 'PB6';
        MatrixRAM[cMCU_regPORTB].bitname[5] := 'PB5';
        MatrixRAM[cMCU_regPORTB].bitname[4] := 'PB4';
        MatrixRAM[cMCU_regPORTB].bitname[3] := 'PB3';
        MatrixRAM[cMCU_regPORTB].bitname[2] := 'PB2';
        MatrixRAM[cMCU_regPORTB].bitname[1] := 'PB1';
        MatrixRAM[cMCU_regPORTB].bitname[0] := 'PB0';

        // 7 � RAM 8 � SFR
        // PORTC
        MatrixRAM[cMCU_regPORTC].Used := true;
        MatrixRAM[cMCU_regPORTC].SFR := true;
        MatrixRAM[cMCU_regPORTC].VirtSFR := false;
        MatrixRAM[cMCU_regPORTC].IDEName := 'PORTC';
        MatrixRAM[cMCU_regPORTC].IDEHexaddres := '007';
        MatrixRAM[cMCU_regPORTC].IDEaddres := 8;
        MatrixRAM[cMCU_regPORTC].bitname[7] := 'PC7';
        MatrixRAM[cMCU_regPORTC].bitname[6] := 'PC6';
        MatrixRAM[cMCU_regPORTC].bitname[5] := 'PC5';
        MatrixRAM[cMCU_regPORTC].bitname[4] := 'PC4';
        MatrixRAM[cMCU_regPORTC].bitname[3] := 'PC3';
        MatrixRAM[cMCU_regPORTC].bitname[2] := 'PC2';
        MatrixRAM[cMCU_regPORTC].bitname[1] := 'PC1';
        MatrixRAM[cMCU_regPORTC].bitname[0] := 'PC0';

        j := -1;
        // 8-31 � RAM GPR
        for Z := 8 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;

        // 32-47 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 32 to 47 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 48-63 � RAM GPR
        for Z := 48 to 63 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;

        // 64-79 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 64 to 79 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 80-95 � RAM GPR
        for Z := 80 to 95 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 96-111 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 96 to 111 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 112-127 � RAM GPR
        for Z := 112 to 127 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 128-255 � RAM Unimplemented?
        for Z := 128 to 255 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 258 � RAM Unimplemented
        MatrixRAM[258].Used := false;
        MatrixRAM[258].SFR := false;
        MatrixRAM[258].VirtSFR := false;
        MatrixRAM[258].IDEName := '';
        MatrixRAM[258].IDEHexaddres := '';
        MatrixRAM[258].IDEaddres := -1;
        // 262-263 � RAM Unimplemented
        for Z := 262 to 263 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;

        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (257) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 9;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].usedbit[7] := false;
        MatrixRAM[cMCU_regOPTION].usedbit[6] := false;
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISA (259) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISA].Used := true;
        MatrixRAM[cMCU_regTRISA].SFR := true;
        MatrixRAM[cMCU_regTRISA].VirtSFR := true;
        MatrixRAM[cMCU_regTRISA].IDEName := 'TRISA';
        MatrixRAM[cMCU_regTRISA].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISA].IDEaddres := 10;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISA].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[4] := false;

        // regTRISA (259) � RAM 10 � SFR

        MatrixRAM[cMCU_regTRISB].Used := true;
        MatrixRAM[cMCU_regTRISB].SFR := true;
        MatrixRAM[cMCU_regTRISB].VirtSFR := true;
        MatrixRAM[cMCU_regTRISB].IDEName := 'TRISB';
        MatrixRAM[cMCU_regTRISB].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISB].IDEaddres := 11;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISC].Used := true;
        MatrixRAM[cMCU_regTRISC].SFR := true;
        MatrixRAM[cMCU_regTRISC].VirtSFR := true;
        MatrixRAM[cMCU_regTRISC].IDEName := 'TRISC';
        MatrixRAM[cMCU_regTRISC].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISC].IDEaddres := 12;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        // TMR0 Prescaler (35) � RAM 11 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 13;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
    15: // PIC16F59
{$REGION 'PIC16F59'}
      begin
        // ������� ������ ��-���������
        rtCrystalFreq := 4000000; // 4 ���
        cMCU_pcLen := 11;
        // ������� ������� ����. ����������� ���������
        cMCU_regOSCCAL := -1; // ����������� � ���� 5�
        cMCU_regGPIO := -1; // ����������� � ���� 5�
        cMCU_regPORTA := 5; // PortA
        cMCU_regPORTB := 6; // PortB
        cMCU_regPORTC := 7; // PortC
        cMCU_regPORTD := 8; // PortD
        cMCU_regPORTE := 9; // PortE
        cMCU_hiPORTA := 3; // Hi PortA
        cMCU_hiPORTB := 7; // Hi PortB
        cMCU_hiPORTC := 7; // Hi PortC
        cMCU_hiPORTD := 7; // Hi PortD
        cMCU_hiPORTE := 7; // Hi PortE
        cMCU_hiGPIO := -1; // ������� ���� GPIO
        cMCU_regCMCON := -1; // ���������� �����������
        cMCU_regADCON0 := -1; // ��� �����������
        cMCU_regADRES := -1; // ��� �����������
        cMCU_avGPIO := false; // ���� GPIO �� �������
        cMCU_avFosc4Out := false; // ����� Fosc/4 �� �������

        cMCU_portT0CKI := 32; // ����� ����� ��� ������ T0CKI
        cMCU_portMCLR := 33; // ����� ����� ��� ������ MCLR
        cMCU_cfgWDTE := 2; // ����� ���� ������������ WDTE
        cMCU_cfgMCLRE := -1; // ����� ���� ������������ MCLRE
        ROM_Size := 2048; // ���������� ����� ROM (0..2047)
        SetLength(ROM, ROM_Size);
        SetLength(ROM_BP, ROM_Size + 1);
        SetLength(ROM_Str_No, ROM_Size);
        SetLength(ROM_Str_No_from, ROM_Size);
        SetLength(ROM_Str_No_to, ROM_Size);
        // ���� ������������ ��-���������

        Config[0] := false; // INTOSC Select bit (HS)
        Config[1] := true; // -//-
        Config[2] := false; // Watchdog timer is disabled
        Config[3] := true; // Code protection off
        Config[4] := false;
        Config[5] := false;
        Config[6] := false;
        Config[7] := false;
        Config[8] := false;
        Config[9] := false;
        Config[10] := false;
        Config[11] := false;

        // ��������� ����� ������������
        SetLength(ConfigBits, 4);
        ConfigBitsCounter := 4;
        ConfigBits[0].Name := 'FOSC0';
        ConfigBits[0].DescriptionId := 25;
        ConfigBits[0].No := 0;
        ConfigBits[0].Value0Id := 60;
        ConfigBits[0].Value1Id := 61;
        ConfigBits[1].Name := 'FOSC1';
        ConfigBits[1].DescriptionId := 25;
        ConfigBits[1].No := 1;
        ConfigBits[1].Value0Id := 60;
        ConfigBits[1].Value1Id := 61;
        ConfigBits[2].Name := 'WDTE';
        ConfigBits[2].DescriptionId := 20;
        ConfigBits[2].No := 2;
        ConfigBits[2].Value0Id := 50;
        ConfigBits[2].Value1Id := 53;
        ConfigBits[3].Name := '\CP';
        ConfigBits[3].DescriptionId := 21;
        ConfigBits[3].No := 3;
        ConfigBits[3].Value0Id := 52;
        ConfigBits[3].Value1Id := 51;

        SFRCount := 18;
        GPRCount := 134;

        // 3 � RAM 4 � SFR
        // STATUS
        MatrixRAM[cMCU_regSTATUS].Used := true;
        MatrixRAM[cMCU_regSTATUS].SFR := true;
        MatrixRAM[cMCU_regSTATUS].VirtSFR := false;
        MatrixRAM[cMCU_regSTATUS].IDEName := 'STATUS';
        MatrixRAM[cMCU_regSTATUS].IDEHexaddres := '003';
        MatrixRAM[cMCU_regSTATUS].IDEaddres := 4;
        MatrixRAM[cMCU_regSTATUS].bitname[7] := 'PA2';
        MatrixRAM[cMCU_regSTATUS].bitname[6] := 'PA1';
        MatrixRAM[cMCU_regSTATUS].bitname[5] := 'PA0';
        MatrixRAM[cMCU_regSTATUS].bitname[4] := '\TO';
        MatrixRAM[cMCU_regSTATUS].bitname[3] := '\PD';
        MatrixRAM[cMCU_regSTATUS].bitname[2] := 'Z';
        MatrixRAM[cMCU_regSTATUS].bitname[1] := 'DC';
        MatrixRAM[cMCU_regSTATUS].bitname[0] := 'C';

        // 4 � RAM 5 � SFR
        // MatrixRAM[cMCU_regFSR].usedbit[7] := false; // !Port � ���-�� �� ������


        // 5 � RAM 6 � SFR
        // PORTA

        MatrixRAM[cMCU_regPORTA].Used := true;
        MatrixRAM[cMCU_regPORTA].usedbit[7] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[6] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[5] := false;
        MatrixRAM[cMCU_regPORTA].usedbit[4] := false;
        MatrixRAM[cMCU_regPORTA].SFR := true;
        MatrixRAM[cMCU_regPORTA].VirtSFR := false;
        MatrixRAM[cMCU_regPORTA].IDEName := 'PORTA';
        MatrixRAM[cMCU_regPORTA].IDEHexaddres := '005';
        MatrixRAM[cMCU_regPORTA].IDEaddres := 6;
        MatrixRAM[cMCU_regPORTA].bitname[3] := 'PA3';
        MatrixRAM[cMCU_regPORTA].bitname[2] := 'PA2';
        MatrixRAM[cMCU_regPORTA].bitname[1] := 'PA1';
        MatrixRAM[cMCU_regPORTA].bitname[0] := 'PA0';

        // 6 � RAM 7 � SFR
        // PORTB
        MatrixRAM[cMCU_regPORTB].Used := true;
        MatrixRAM[cMCU_regPORTB].SFR := true;
        MatrixRAM[cMCU_regPORTB].VirtSFR := false;
        MatrixRAM[cMCU_regPORTB].IDEName := 'PORTB';
        MatrixRAM[cMCU_regPORTB].IDEHexaddres := '006';
        MatrixRAM[cMCU_regPORTB].IDEaddres := 7;
        MatrixRAM[cMCU_regPORTB].bitname[7] := 'PB7';
        MatrixRAM[cMCU_regPORTB].bitname[6] := 'PB6';
        MatrixRAM[cMCU_regPORTB].bitname[5] := 'PB5';
        MatrixRAM[cMCU_regPORTB].bitname[4] := 'PB4';
        MatrixRAM[cMCU_regPORTB].bitname[3] := 'PB3';
        MatrixRAM[cMCU_regPORTB].bitname[2] := 'PB2';
        MatrixRAM[cMCU_regPORTB].bitname[1] := 'PB1';
        MatrixRAM[cMCU_regPORTB].bitname[0] := 'PB0';

        // 7 � RAM 8 � SFR
        // PORTC
        MatrixRAM[cMCU_regPORTC].Used := true;
        MatrixRAM[cMCU_regPORTC].SFR := true;
        MatrixRAM[cMCU_regPORTC].VirtSFR := false;
        MatrixRAM[cMCU_regPORTC].IDEName := 'PORTC';
        MatrixRAM[cMCU_regPORTC].IDEHexaddres := '007';
        MatrixRAM[cMCU_regPORTC].IDEaddres := 8;
        MatrixRAM[cMCU_regPORTC].bitname[7] := 'PC7';
        MatrixRAM[cMCU_regPORTC].bitname[6] := 'PC6';
        MatrixRAM[cMCU_regPORTC].bitname[5] := 'PC5';
        MatrixRAM[cMCU_regPORTC].bitname[4] := 'PC4';
        MatrixRAM[cMCU_regPORTC].bitname[3] := 'PC3';
        MatrixRAM[cMCU_regPORTC].bitname[2] := 'PC2';
        MatrixRAM[cMCU_regPORTC].bitname[1] := 'PC1';
        MatrixRAM[cMCU_regPORTC].bitname[0] := 'PC0';

        // 8 � RAM 9 � SFR
        // PORTD
        MatrixRAM[cMCU_regPORTD].Used := true;
        MatrixRAM[cMCU_regPORTD].SFR := true;
        MatrixRAM[cMCU_regPORTD].VirtSFR := false;
        MatrixRAM[cMCU_regPORTD].IDEName := 'PORTD';
        MatrixRAM[cMCU_regPORTD].IDEHexaddres := '008';
        MatrixRAM[cMCU_regPORTD].IDEaddres := 9;
        MatrixRAM[cMCU_regPORTD].bitname[7] := 'PD7';
        MatrixRAM[cMCU_regPORTD].bitname[6] := 'PD6';
        MatrixRAM[cMCU_regPORTD].bitname[5] := 'PD5';
        MatrixRAM[cMCU_regPORTD].bitname[4] := 'PD4';
        MatrixRAM[cMCU_regPORTD].bitname[3] := 'PD3';
        MatrixRAM[cMCU_regPORTD].bitname[2] := 'PD2';
        MatrixRAM[cMCU_regPORTD].bitname[1] := 'PD1';
        MatrixRAM[cMCU_regPORTD].bitname[0] := 'PD0';

        // 9 � RAM 10 � SFR
        // PORTE
        MatrixRAM[cMCU_regPORTE].Used := true;
        MatrixRAM[cMCU_regPORTE].SFR := true;
        MatrixRAM[cMCU_regPORTE].VirtSFR := false;
        MatrixRAM[cMCU_regPORTE].IDEName := 'PORTE';
        MatrixRAM[cMCU_regPORTE].IDEHexaddres := '009';
        MatrixRAM[cMCU_regPORTE].IDEaddres := 10;
        MatrixRAM[cMCU_regPORTE].bitname[7] := 'PE7';
        MatrixRAM[cMCU_regPORTE].bitname[6] := 'PE6';
        MatrixRAM[cMCU_regPORTE].bitname[5] := 'PE5';
        MatrixRAM[cMCU_regPORTE].bitname[4] := 'PE4';
        MatrixRAM[cMCU_regPORTE].usedbit[3] := false;
        MatrixRAM[cMCU_regPORTE].usedbit[2] := false;
        MatrixRAM[cMCU_regPORTE].usedbit[1] := false;
        MatrixRAM[cMCU_regPORTE].usedbit[0] := false;

        j := -1;
        // 10-31 � RAM GPR
        for Z := 10 to 31 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;

        // 32-47 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 32 to 47 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 48-63 � RAM GPR
        for Z := 48 to 63 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;

        // 64-79 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 64 to 79 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 80-95 � RAM GPR
        for Z := 80 to 95 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 96-111 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 96 to 111 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 112-127 � RAM GPR
        for Z := 112 to 127 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 128-143 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 128 to 143 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 144-159 � RAM GPR
        for Z := 144 to 159 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 160-175 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 160 to 175 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 176-191 � RAM GPR
        for Z := 176 to 191 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 192-207 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 192 to 207 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 208-223 � RAM GPR
        for Z := 208 to 223 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;
        // 224-239 � RAM Unimplemented? (��������� ������������������ � 1 ����, ��� ������ ����������� �����)
        for Z := 224 to 239 do
        begin
          MatrixRAM[Z].Used := false;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := '';
          MatrixRAM[Z].IDEaddres := -1;
        end;
        // 240-255 � RAM GPR
        for Z := 240 to 255 do
        begin
          inc(j);
          MatrixRAM[Z].Used := true;
          MatrixRAM[Z].SFR := false;
          MatrixRAM[Z].VirtSFR := false;
          MatrixRAM[Z].IDEName := '';
          MatrixRAM[Z].IDEHexaddres := DecTo3Hex(Z);
          MatrixRAM[Z].IDEaddres := SFRCount + j;
        end;

        // 258 � RAM Unimplemented
        MatrixRAM[258].Used := false;
        MatrixRAM[258].SFR := false;
        MatrixRAM[258].VirtSFR := false;
        MatrixRAM[258].IDEName := '';
        MatrixRAM[258].IDEHexaddres := '';
        MatrixRAM[258].IDEaddres := -1;


        // REGW (32) � RAM 0 � SFR

        MatrixRAM[cMCU_regW].Used := true;
        MatrixRAM[cMCU_regW].SFR := true;
        MatrixRAM[cMCU_regW].VirtSFR := true;
        MatrixRAM[cMCU_regW].IDEName := 'W';
        MatrixRAM[cMCU_regW].IDEHexaddres := 'W';
        MatrixRAM[cMCU_regW].IDEaddres := 0;
        // regOPTION (257) � RAM 8 � SFR

        MatrixRAM[cMCU_regOPTION].Used := true;
        MatrixRAM[cMCU_regOPTION].SFR := true;
        MatrixRAM[cMCU_regOPTION].VirtSFR := true;
        MatrixRAM[cMCU_regOPTION].IDEName := 'OPTION';
        MatrixRAM[cMCU_regOPTION].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regOPTION].IDEaddres := 11;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regOPTION].usedbit[7] := false;
        MatrixRAM[cMCU_regOPTION].usedbit[6] := false;
        MatrixRAM[cMCU_regOPTION].bitname[5] := 'T0CS';
        MatrixRAM[cMCU_regOPTION].bitname[4] := 'T0SE';
        MatrixRAM[cMCU_regOPTION].bitname[3] := 'PSA';
        MatrixRAM[cMCU_regOPTION].bitname[2] := 'PS2';
        MatrixRAM[cMCU_regOPTION].bitname[1] := 'PS1';
        MatrixRAM[cMCU_regOPTION].bitname[0] := 'PS0';


        // regTRISA (259) � RAM 9 � SFR

        MatrixRAM[cMCU_regTRISA].Used := true;
        MatrixRAM[cMCU_regTRISA].SFR := true;
        MatrixRAM[cMCU_regTRISA].VirtSFR := true;
        MatrixRAM[cMCU_regTRISA].IDEName := 'TRISA';
        MatrixRAM[cMCU_regTRISA].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISA].IDEaddres := 12;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISA].usedbit[7] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[6] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[5] := false;
        MatrixRAM[cMCU_regTRISA].usedbit[4] := false;

        // regTRISA (259) � RAM 10 � SFR

        MatrixRAM[cMCU_regTRISB].Used := true;
        MatrixRAM[cMCU_regTRISB].SFR := true;
        MatrixRAM[cMCU_regTRISB].VirtSFR := true;
        MatrixRAM[cMCU_regTRISB].IDEName := 'TRISB';
        MatrixRAM[cMCU_regTRISB].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISB].IDEaddres := 13;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISC].Used := true;
        MatrixRAM[cMCU_regTRISC].SFR := true;
        MatrixRAM[cMCU_regTRISC].VirtSFR := true;
        MatrixRAM[cMCU_regTRISC].IDEName := 'TRISC';
        MatrixRAM[cMCU_regTRISC].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISC].IDEaddres := 14;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISD].Used := true;
        MatrixRAM[cMCU_regTRISD].SFR := true;
        MatrixRAM[cMCU_regTRISD].VirtSFR := true;
        MatrixRAM[cMCU_regTRISD].IDEName := 'TRISD';
        MatrixRAM[cMCU_regTRISD].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISD].IDEaddres := 15;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        MatrixRAM[cMCU_regTRISE].Used := true;
        MatrixRAM[cMCU_regTRISE].SFR := true;
        MatrixRAM[cMCU_regTRISE].VirtSFR := true;
        MatrixRAM[cMCU_regTRISE].IDEName := 'TRISE';
        MatrixRAM[cMCU_regTRISE].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTRISE].IDEaddres := 16;
        MatrixRAM[cMCU_regTRISE].usedbit[0] := false;
        MatrixRAM[cMCU_regTRISE].usedbit[1] := false;
        MatrixRAM[cMCU_regTRISE].usedbit[2] := false;
        MatrixRAM[cMCU_regTRISE].usedbit[3] := false;

        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
        // TMR0 Prescaler (35) � RAM 11 � SFR

        MatrixRAM[cMCU_regTMR0P].Used := true;
        MatrixRAM[cMCU_regTMR0P].SFR := true;
        MatrixRAM[cMCU_regTMR0P].VirtSFR := true;
        MatrixRAM[cMCU_regTMR0P].IDEName := 'TMR0 Prescaler';
        MatrixRAM[cMCU_regTMR0P].IDEHexaddres := 'n/a';
        MatrixRAM[cMCU_regTMR0P].IDEaddres := 17;
        // !!!! ��� ��������� ���-�� SFR, ��������� ���� �����!
      end;
{$ENDREGION}
  end;
{$REGION '����� �������� ��� ���� ����������� BASELINE'}
  // 0 � RAM 1 � SFR
  // INDF
  MatrixRAM[0].Used := true;
  MatrixRAM[0].SFR := true;
  MatrixRAM[0].VirtSFR := false;
  MatrixRAM[0].IDEName := 'INDF';
  MatrixRAM[0].IDEHexaddres := '000';
  MatrixRAM[0].IDEaddres := 1;
  // 1 � RAM 2 � SFR
  // TMR0
  MatrixRAM[1].Used := true;
  MatrixRAM[1].SFR := true;
  MatrixRAM[1].VirtSFR := false;
  MatrixRAM[1].IDEName := 'TMR0';
  MatrixRAM[1].IDEHexaddres := '001';
  MatrixRAM[1].IDEaddres := 2;

  // 2 � RAM 3 � SFR
  // PCL
  MatrixRAM[2].Used := true;
  MatrixRAM[2].SFR := true;
  MatrixRAM[2].VirtSFR := false;
  MatrixRAM[2].IDEName := 'PCL';
  MatrixRAM[2].IDEHexaddres := '002';
  MatrixRAM[2].IDEaddres := 3;
  // 4 � RAM 5 � SFR
  // FSR
  MatrixRAM[cMCU_regFSR].Used := true;
  MatrixRAM[cMCU_regFSR].SFR := true;
  MatrixRAM[cMCU_regFSR].VirtSFR := false;
  MatrixRAM[cMCU_regFSR].IDEName := 'FSR';
  MatrixRAM[cMCU_regFSR].IDEHexaddres := '004';
  MatrixRAM[cMCU_regFSR].IDEaddres := 5;
{$ENDREGION}
  // Popa POR;
  SetLength(bSt[0], cMCU_pcLen); // ������ ������ ����� ������ PC
  SetLength(bSt[1], cMCU_pcLen); // ������ ������ ����� ������ PC
  SetLength(PC, cMCU_pcLen);
  generateSimAdress();

end;

procedure ByteToBinInCD(X: byte);

var
  a1, a2, a3, a4, a5, a6, a7, y: byte;
begin
  a7 := X div 128;
  if a7 = 0 then
    �hangeData[7] := false
  else
    �hangeData[7] := true;
  y := X - (a7 * 128);

  a6 := y div 64;
  if a6 = 0 then
    �hangeData[6] := false
  else
    �hangeData[6] := true;
  y := y - (a6 * 64);

  a5 := y div 32;
  if a5 = 0 then
    �hangeData[5] := false
  else
    �hangeData[5] := true;
  y := y - (a5 * 32);

  a4 := y div 16;
  if a4 = 0 then
    �hangeData[4] := false
  else
    �hangeData[4] := true;
  y := y - (a4 * 16);

  a3 := y div 8;
  if a3 = 0 then
    �hangeData[3] := false
  else
    �hangeData[3] := true;
  y := y - (a3 * 8);

  a2 := y div 4;
  if a2 = 0 then
    �hangeData[2] := false
  else
    �hangeData[2] := true;
  y := y - (a2 * 4);

  a1 := y div 2;
  if a1 = 0 then
    �hangeData[1] := false
  else
    �hangeData[1] := true;
  y := y - (a1 * 2);

  if y = 0 then
    �hangeData[0] := false
  else
    �hangeData[0] := true;

end;

procedure TRun.Execute;
label 1, 10, 11, 15, 20, lINCFSZ1, lDECFSZ1, lINCF1, lDECF1, WakeUpPinCh,
  WakeUpCM, Next0, Next1;
var

  // ��������� ���������� ��� ��������� ASM �������, ����� �������������� � �����, ������ �����������, ���� ����������
  tmpByte1, tmpByte2, tmpByte3: byte;
  tmpAByte, tmpBByte: array [0 .. 7] of boolean;
  tmpW1, tmpW2: Word;
  tmpWA: array [0 .. 7] of byte;
  tmpBit1, tmpBit2, tmpBit3: boolean;
  First_End: boolean;
  // �������� ���� ���������� � ���, ��� ���� ������� ������� - ���������, � ����������� � ������ ���, �� ������ ���� ������ (�.�. ������ � �� ����������� MOVLW 00h �� ������ 255 ��� PIC10F200
  Last_Level_T0CKI: boolean;
  // ���������� ��� ������������ ��������� �� ����� T0CKI
  Two_MC: boolean; // True, ���� ����������� ���������� ����������� �� 2 �.�.
  tmpInt, tmpInt2, tmpInt3, tmpInt4, tmpI: integer;
  tmpSingle, tmpSingle2: Single;
  tmpBoolean: boolean;
  procedure incTMR0();
  // ��������� ���������� ������� TMR0 � ������ ������������
  begin
    // ����� �������� � TMR0
    tmpInt := rtTMR0 div rtKTMR0;
    if tmpInt > 255 then
    begin
      tmpInt := tmpInt - 256;
      rtTMR0 := rtTMR0 - (256 * rtKTMR0);
    end;
    ChangeAddr := cMCU_regTMR0;
    ByteToBinInCD(tmpInt);
    ChangeDataNotInstruction := true;
    // ���������� ���������, ��� �� �����. ���������� �������
    ChangeRAMByte;
    ChangeAddr := cMCU_regTMR0P;
    ByteToBinInCD(rtTMR0 - (tmpInt * rtKTMR0));
    ChangeDataNotInstruction := true;
    // ���������� ���������, ��� �� �����. ���������� �������
    ChangeRAMByte;

  end;

begin

  // ����� ����������������� �������
  UserTimer := 0;
1: // ????
  // ����� ���������
  rtexStep := true;
  First_End := true;
  Two_MC := false;
  I := ROM_Size - 1;
  for tmpInt4 := 0 to cMCU_pcLen - 1 do
    PC[tmpInt4] := true;

  IC := 0;
  MC := 0;

  // ����� WDT
  TaktsWDT := 0;
  // ����� Timer0
  rtTMR0 := 0;
  Last_Level_T0CKI := false;
  // ���������� ������ "���"
  SleepMode := false;
  // ��� ������ step-by-step
  rtexStep := true;
  // ����� �����
  for tmpByte1 := 0 to stMax do
    St[tmpByte1] := 0;
  StC := 0;
  // ����� �������� ��������� ������
  ChangeDataNotInstruction := false;
  // ������� �������� �������������
  rtSyncroTMP := readTSC;
  // ���������� ��������

10:
  // ������� ��� ���-��� ��������� � �����������, ��� ��� ����������
  for tmpI := Low(BackTactDevices) to High(BackTactDevices) do
    BackTactDevices[tmpI].BackTact(MC);

  // ��������, � �� ����������� �� ��������?
  if I > (ROM_Size - 1) then
  begin
    // � ����� ��� ������ ������, � �������
    if First_End then
    begin
      First_End := false;
      I := 0;
      for tmpInt4 := 0 to cMCU_pcLen - 1 do
        PC[tmpInt4] := false;
    end
    else
    begin
      // ����� �������� ���, ������� �����, ���� ������� ����� ��������� ���-�� ����� ROM - ����������� �����, �...
      I := ROM_Size - 1;
      for tmpInt4 := 0 to cMCU_pcLen - 1 do
        PC[tmpInt4] := true;

      // ���, ����� ��������� ������ ������ ��������� ������� � ������� �����
      TReturnNextMethod(StopSimulation_METOD);;
      // ������� ��� ������ � �������� ���������
      exit;
    end;
  end;
  // ��� �������� BreakPoints �� ������ ����
  if ROM_BP[I] then
  begin
    // ��������� ������
    rtPause := true;
  end;

11:
  // � ������ �������� ��?

  if not rtRunning then
    exit;

  // Pause
  if rtPause then
  begin
    rtPaused:=true;
    sleep(10);
    // ������� �������� �������������
    rtSyncroTMP := readTSC;
    goto 11;
  end;
   rtPaused:=false;
  // � ����������� �� ������
  // Step-By-Step
  if rtStepByStep then
  begin
    if not rtexStep then
    begin
      sleep(10);

      goto 11;
    end
    else if rtRefreshComplete then
    begin
      { if rtstepbystep then } rtRefreshComplete := false;
      rtexStep := false;
    end
    else
      goto 11;
  end;

  // Delay
  if rtWithDelay then
  begin
    sleep(rtDelayMS);
  15:
    if not rtWithDelay then
      goto 11; // ��� ����� ���������� �� ����, ����� �� ������ � ���������

    sleep(1);
    if not rtRefreshComplete then
      goto 15
    else
      rtRefreshComplete := false;

  end;
  // �������������
  if rtWithSyncro then
  begin
    if readTSC - rtSyncroTMP < rtCyclPerCycMK * rtSyncro then
      goto 11
    else
    begin
      rtSyncroTMP := trunc(rtSyncroTMP + (rtCyclPerCycMK / rtSyncro));

    end;

  end;

  // \MCLR

  if (cMCU_cfgMCLRE = -1) or (Config[cMCU_cfgMCLRE]) then // MCLR MODE ON
  begin
    // ������ � �����
    tmpSingle := TD.Port[cMCU_portMCLR].Node.GetLevel;
    if isNan(tmpSingle) then
    begin
      // NAN - ������ �� ����������, ����� ����� ���� ������� ������ ������
    end
    else if (tmpSingle <= MaxLowLevelVoltage) then
    begin
      OtherReset(true, false);
      // goto 1
      // ���� ������ ������ - �� ����� ���� ����� ������
      First_End := true;
      I := ROM_Size - 1;
      for tmpInt4 := 0 to cMCU_pcLen - 1 do
        PC[tmpInt4] := true;
      TaktsWDT := 0;
      goto 10;
    end;
  end;

  // ADC
  // � ���� �� �� ������ � ��?
  if cMCU_regADCON0 > -1 then // ����
    // � ������� �� ��?
    if RAM[cMCU_regADCON0, 0] then // �������
      // � �������� �� ��������������?
      if RAM[cMCU_regADCON0, 1] then // ��
      begin
        if Two_MC then
          rtTaktsADC := rtTaktsADC + 2
        else
          rtTaktsADC := rtTaktsADC + 1;
        if rtTaktsADC >= 13 then // ������ 13 ������ ��������������.
        begin

          // �������, ����� ����� ���� �������������
          if RAM[cMCU_regADCON0, 3] then
          begin // 0,6V absolute voltage reference
            // �.�. VDD � ��� 5 �����, �� � ���-�� ����� 30:
            ChangeAddr := cMCU_regADRES;
            �hangeData[7] := false;
            �hangeData[6] := false;
            �hangeData[5] := false;
            �hangeData[4] := true;
            �hangeData[3] := true;
            �hangeData[2] := true;
            �hangeData[1] := true;
            �hangeData[0] := false;
            ChangeRAMByte();
          end
          else
          begin // �����-�� �� ������� �� �������
            if RAM[cMCU_regADCON0, 2] then
            begin // ����� 1 GP1/AN1
              tmpSingle := TD.Port[1].Node.GetLevel()
            end
            else
            begin // ����� 0 GP0/AN0
              tmpSingle := TD.Port[0].Node.GetLevel()
            end;
            // �.�. Vdd � ��� 5 �����, �� ����� ����������� �������:
            tmpInt := trunc(tmpSingle / 0.0196078431372549);
            if tmpInt > 255 then
              tmpInt := 255;
            if tmpInt < 0 then
              tmpInt := 0;

            ByteToBinInCD(tmpInt);
            ChangeAddr := cMCU_regADRES;
            ChangeRAMByte();
          end;

          // ������� ��� GO/\DONE
          ChangeBitAddr := cMCU_regADCON0;
          ChangeBitNo := 1;
          ChangeBitData := false;
          ChangeRAMBit();

          rtTaktsADC := 0; // ����� �������� � �������, ����� ����.
        end;
      end;

  // comparator
  // � ���� �� �� ������ � ��?
  if cMCU_regCMCON > -1 then // ����
    // � ������� �� ��?
    if RAM[cMCU_regCMCON, 3] then // �������
    begin
      // ���������  CIN-
      if RAM[cMCU_regCMCON, 2] then
        tmpSingle := TD.Port[1].Node.GetLevel()
      else
        tmpSingle := 0.6;
      // ��������� CIN+
      if RAM[cMCU_regCMCON, 1] then
        tmpSingle2 := TD.Port[0].Node.GetLevel()
      else
        tmpSingle2 := TD.Port[1].Node.GetLevel();
      // ����������� ���������
      if (tmpSingle > tmpSingle2) xor RAM[cMCU_regCMCON, 6] then
        RAM[cMCU_regCMCON, 7] := true
      else
        RAM[cMCU_regCMCON, 7] := false;

    end;

  // WDT
  if Config[cMCU_cfgWDTE] then // WDT �������
  begin
    // ��������, � ��������� �� ������������
    if RAM[cMCU_regOPTION, 3] then
    begin // ������������ ��������� � WDT
      // ���������� ������������ �������
      rtKWDT := 1;
      if RAM[cMCU_regOPTION, 2] then
        rtKWDT := rtKWDT * 16;
      if RAM[cMCU_regOPTION, 1] then
        rtKWDT := rtKWDT * 4;
      if RAM[cMCU_regOPTION, 0] then
        rtKWDT := rtKWDT * 2;
      // ����������� WDT �� 1 �������� ������ (��� 2, � ����������� �� ���� �� ������� �.�. ����������� ����������)
      if Two_MC then
        TaktsWDT := TaktsWDT + (2 / rtKWDT)
      else
        TaktsWDT := TaktsWDT + (1 / rtKWDT);
    end
    else
    begin // ������������ �� ��������� � WDT
      // ����������� WDT �� 1 �������� ������ (��� 2, � ����������� �� ���� �� ������� �.�. ����������� ����������)
      if Two_MC then
        TaktsWDT := TaktsWDT + 2
      else
        TaktsWDT := TaktsWDT + 1;
    end;
    // �������� �� ������������ WDT
    if TaktsWDT > rtTaktsWDT then
    begin // ��������� ������������ WDT
      // �������
      OtherReset(false, true);
      // ���� ������ ������ - �� ����� ���� ����� ������
      First_End := true;
      I := ROM_Size - 1;
      for tmpInt4 := 0 to cMCU_pcLen - 1 do
        PC[tmpInt4] := true;
      TaktsWDT := 0;
      goto 10;
    end;
  end;
  // SleepMode
  if SleepMode then
  begin
    // ��������, � �������� �� "����������" �� ��������� �� ������? ����������� � ���� �� ������ ������ ����������
    if cMCU_regCMCON > -1 then
      // ���������� ����
      if RAM[cMCU_regCMCON, 3] then
        // ���������� �������
        if RAM[cMCU_regCMCON, 0] then
        // ���������� �� ����������� ���
        begin
          ByteNo := cMCU_regCMCON;
          BitNo := 7;
          if sleepCM <> ReadRAM() then
            goto WakeUpCM;
        end;
    goto Next0;
  WakeUpCM:

    begin // ���������
      // ���������
      OtherReset(false, false, false, true);
      // ���� ������ ������ - �� ����� ���� ����� ������
      First_End := true;
      I := ROM_Size - 1;
      for tmpInt4 := 0 to cMCU_pcLen - 1 do
        PC[tmpInt4] := true;
      TaktsWDT := 0;
      goto 10;
    end;

  Next0:
    // ��������, � �������� �� "����������" �� ��������� �� ������ GP0,GP1,GP3? (������, ��� ��� GP2)
    if cMCU_avGPIO and
    // ���� � �� ������ ���� GPIO (� � ����, � ���� ���� ��� �������� ��������� � ��� OPTION,7 - /GPWU)
      (RAM[cMCU_regOPTION, 7] = false) then
    begin // ��������
      // ��������, � �� ��������� �� ���-������
      ByteNo := 6;
      BitNo := 0;
      if (sleepRegGPIO[0] <> ReadRAM()) then
        goto WakeUpPinCh;
      ByteNo := 6;
      BitNo := 1;
      if (sleepRegGPIO[1] <> ReadRAM()) then
        goto WakeUpPinCh;
      ByteNo := 6;
      BitNo := 2;
      if (sleepRegGPIO[2] <> ReadRAM()) then
        goto WakeUpPinCh;
      ByteNo := 6;
      BitNo := 3;
      if (sleepRegGPIO[3] <> ReadRAM()) then
        goto WakeUpPinCh;
      goto Next1;
    WakeUpPinCh:

      begin // ���������
        // ���������
        OtherReset(false, false, true);
        // ���� ������ ������ - �� ����� ���� ����� ������
        First_End := true;
        I := ROM_Size - 1;
        for tmpInt4 := 0 to cMCU_pcLen - 1 do
          PC[tmpInt4] := true;
        TaktsWDT := 0;
        goto 10;
      end;
    Next1:
    end;

    goto 10;

  end;

  // ������ ������� Timer0
  // ������ - ���������� ������������
  // ������������ = 1 (����� ��������)
  rtKTMR0 := 1;
  // ��������, ����� ��� ��������� ������������
  if RAM[cMCU_regOPTION, 3] = false then
  // ������������ ����� TMR0
  begin
    // ���������� ������������ �������
    rtKTMR0 := 2;
    if RAM[cMCU_regOPTION, 2] then
      rtKTMR0 := rtKTMR0 * 16;
    if RAM[cMCU_regOPTION, 1] then
      rtKTMR0 := rtKTMR0 * 4;
    if RAM[cMCU_regOPTION, 0] then
      rtKTMR0 := rtKTMR0 * 2;
  end;
  // �������� ������, ��� ����� ������ �� ��������� � TMR0 ���������� ��������� 2 ��
  // �������� ������� ���������� �������
  // ������� ��������, ���� �� ����������
  if cMCU_regCMCON > -1 then // ����
  begin
    // � ������� �� ��?
    if RAM[cMCU_regCMCON, 3] then // �������
      // � �������� �� ��� ����� �� ���� ���������� �������
      if RAM[cMCU_regCMCON, 4] = false then
      // ��������
      begin
        tmpBoolean := RAM[cMCU_regCMCON, 7];
        if not(Last_Level_T0CKI = tmpBoolean) then
        begin // ������� ������� �� ����� T0CKI ��������� � ���������� ����
          Last_Level_T0CKI := tmpBoolean;
          if tmpBoolean xor RAM[cMCU_regOPTION, 4] then
          begin
            rtTMR0 := rtTMR0 + 1;
            incTMR0();
          end;

        end;
      end;
  end
  else // �������� ������ ������� ���������� �������
    if (RAM[cMCU_regOPTION, 5] = false) or
      (cMCU_avFosc4Out and (RAM[cMCU_regOPTION, 5] and RAM[5, 0])) then
    // ���������� �� ��������� �������
    begin
      // ��������� �������� ������� Timer0
      if Two_MC then
        rtTMR0 := rtTMR0 + 2
      else
        rtTMR0 := rtTMR0 + 1;
      incTMR0();
    end
    else
    // ���������� �� �������� �������
    begin
      // ������ � �����
      tmpSingle := TD.Port[cMCU_portT0CKI].Node.GetLevel;
      if isNan(tmpSingle) then
        tmpBoolean := Last_Level_T0CKI // ���� tmpBoolean := true, �������� 30.03.2016, ����� ��� ����� �����
      else if (tmpSingle <= MaxLowLevelVoltage) then
        tmpBoolean := false
      else
        tmpBoolean := true;
      if not(Last_Level_T0CKI = tmpBoolean) then
      begin // ������� ������� �� ����� T0CKI ��������� � ���������� ����
        Last_Level_T0CKI := tmpBoolean;
        if tmpBoolean xor RAM[cMCU_regOPTION, 4] then
        begin
          rtTMR0 := rtTMR0 + 1;
          incTMR0();
        end;

      end;

    end;

  IC := IC + 1;
  MC := MC + 1;
  Two_MC := false;

  CurrentCommand[0] := ROM[I, 0];
  CurrentCommand[1] := ROM[I, 1];
  CurrentCommand[2] := ROM[I, 2];
  CurrentCommand[3] := ROM[I, 3];
  CurrentCommand[4] := ROM[I, 4];
  CurrentCommand[5] := ROM[I, 5];
  CurrentCommand[6] := ROM[I, 6];
  CurrentCommand[7] := ROM[I, 7];
  CurrentCommand[8] := ROM[I, 8];
  CurrentCommand[9] := ROM[I, 9];
  CurrentCommand[10] := ROM[I, 10];
  CurrentCommand[11] := ROM[I, 11];
20:

  begin
    //

    if CurrentCommand[11] then // 1XXXXXXXXXXX
    begin
      if CurrentCommand[10] then // 11XXXXXXXXXX
      begin
        if CurrentCommand[9] then // 111XXXXXXXXX
        begin
          if CurrentCommand[8] then // 1111XXXXXXXX
          begin
            // bXORLW

            ChangeBitData := true;
            // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            // ����� ���� �������� XOR �-� ���������� � ��������� W. ���-� � W. ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
            �hangeData[0] := RAM[cMCU_regW, 0] XOR CurrentCommand[0];
            if �hangeData[0] then
              ChangeBitData := false;
            �hangeData[1] := RAM[cMCU_regW, 1] XOR CurrentCommand[1];
            if �hangeData[1] then
              ChangeBitData := false;
            �hangeData[2] := RAM[cMCU_regW, 2] XOR CurrentCommand[2];
            if �hangeData[2] then
              ChangeBitData := false;
            �hangeData[3] := RAM[cMCU_regW, 3] XOR CurrentCommand[3];
            if �hangeData[3] then
              ChangeBitData := false;
            �hangeData[4] := RAM[cMCU_regW, 4] XOR CurrentCommand[4];
            if �hangeData[4] then
              ChangeBitData := false;
            �hangeData[5] := RAM[cMCU_regW, 5] XOR CurrentCommand[5];
            if �hangeData[5] then
              ChangeBitData := false;
            �hangeData[6] := RAM[cMCU_regW, 6] XOR CurrentCommand[6];
            if �hangeData[6] then
              ChangeBitData := false;
            �hangeData[7] := RAM[cMCU_regW, 7] XOR CurrentCommand[7];
            if �hangeData[7] then
              ChangeBitData := false;
            // �������� RAM �� ������ � ������������ � �������
            ChangeAddr := cMCU_regW;
            ChangeRAMByte();
            // �������� ���� Z � Status
            ChangeBitAddr := 3;
            ChangeBitNo := 2;
            ChangeRAMBit;
            // ��������� ������� �������, � ��������� ��. ��������.
            I := I + 1;
            PCLpp();
            goto 10;
          end
          else // 1110XXXXXXXX
          begin
            // bANDLW
            ChangeBitData := true;
            // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            // ����� ���� �������� AND �-� ���������� � ��������� W. ���-� � W. ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
            �hangeData[0] := RAM[cMCU_regW, 0] AND CurrentCommand[0];
            if �hangeData[0] then
              ChangeBitData := false;
            �hangeData[1] := RAM[cMCU_regW, 1] AND CurrentCommand[1];
            if �hangeData[1] then
              ChangeBitData := false;
            �hangeData[2] := RAM[cMCU_regW, 2] AND CurrentCommand[2];
            if �hangeData[2] then
              ChangeBitData := false;
            �hangeData[3] := RAM[cMCU_regW, 3] AND CurrentCommand[3];
            if �hangeData[3] then
              ChangeBitData := false;
            �hangeData[4] := RAM[cMCU_regW, 4] AND CurrentCommand[4];
            if �hangeData[4] then
              ChangeBitData := false;
            �hangeData[5] := RAM[cMCU_regW, 5] AND CurrentCommand[5];
            if �hangeData[5] then
              ChangeBitData := false;
            �hangeData[6] := RAM[cMCU_regW, 6] AND CurrentCommand[6];
            if �hangeData[6] then
              ChangeBitData := false;
            �hangeData[7] := RAM[cMCU_regW, 7] AND CurrentCommand[7];
            if �hangeData[7] then
              ChangeBitData := false;
            // �������� RAM �� ������ � ������������ � �������
            ChangeAddr := cMCU_regW;
            ChangeRAMByte();
            // �������� ���� Z � Status
            ChangeBitAddr := 3;
            ChangeBitNo := 2;
            ChangeRAMBit;
            // ��������� ������� �������, � ��������� ��. ��������.
            I := I + 1;
            PCLpp();
            goto 10;
          end;
        end
        else // 110XXXXXXXXX
        begin
          if CurrentCommand[8] then // 1101XXXXXXXX
          begin
            // bIORLW
            ChangeBitData := true;
            // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            // ����� ���� �������� OR �-� ���������� � ��������� W. ���-� � W. ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
            �hangeData[0] := RAM[cMCU_regW, 0] OR CurrentCommand[0];
            if �hangeData[0] then
              ChangeBitData := false;
            �hangeData[1] := RAM[cMCU_regW, 1] OR CurrentCommand[1];
            if �hangeData[1] then
              ChangeBitData := false;
            �hangeData[2] := RAM[cMCU_regW, 2] OR CurrentCommand[2];
            if �hangeData[2] then
              ChangeBitData := false;
            �hangeData[3] := RAM[cMCU_regW, 3] OR CurrentCommand[3];
            if �hangeData[3] then
              ChangeBitData := false;
            �hangeData[4] := RAM[cMCU_regW, 4] OR CurrentCommand[4];
            if �hangeData[4] then
              ChangeBitData := false;
            �hangeData[5] := RAM[cMCU_regW, 5] OR CurrentCommand[5];
            if �hangeData[5] then
              ChangeBitData := false;
            �hangeData[6] := RAM[cMCU_regW, 6] OR CurrentCommand[6];
            if �hangeData[6] then
              ChangeBitData := false;
            �hangeData[7] := RAM[cMCU_regW, 7] OR CurrentCommand[7];
            if �hangeData[7] then
              ChangeBitData := false;
            // �������� RAM �� ������ � ������������ � �������
            ChangeAddr := cMCU_regW;
            ChangeRAMByte();
            // �������� ���� Z � Status
            ChangeBitAddr := 3;
            ChangeBitNo := 2;
            ChangeRAMBit;
            // ��������� ������� �������, � ��������� ��. ��������.
            I := I + 1;
            PCLpp();
            goto 10;

          end
          else // 1100XXXXXXXX
          begin
            // bMOVLW
            �hangeData[0] := CurrentCommand[0];
            �hangeData[1] := CurrentCommand[1];
            �hangeData[2] := CurrentCommand[2];
            �hangeData[3] := CurrentCommand[3];
            �hangeData[4] := CurrentCommand[4];
            �hangeData[5] := CurrentCommand[5];
            �hangeData[6] := CurrentCommand[6];
            �hangeData[7] := CurrentCommand[7];
            // �������� RAM �� ������ � ������������ � �������
            ChangeAddr := cMCU_regW;
            ChangeRAMByte();
            // ��������� ������� �������, PCL � ��������� ��. ��������.
            I := I + 1;
            PCLpp();
            goto 10;
          end;

        end;
      end
      else // 10XXXXXXXXXX
        if CurrentCommand[9] then // 101XXXXXXXXX
        begin
          // GOTO
          // ������� ������� �������� �� ����� � ���������
          I := 0;
          if CurrentCommand[0] = true then
            I := I + 1;
          if CurrentCommand[1] = true then
            I := I + 2;
          if CurrentCommand[2] = true then
            I := I + 4;
          if CurrentCommand[3] = true then
            I := I + 8;
          if CurrentCommand[4] = true then
            I := I + 16;
          if CurrentCommand[5] = true then
            I := I + 32;
          if CurrentCommand[6] = true then
            I := I + 64;
          if CurrentCommand[7] = true then
            I := I + 128;
          if CurrentCommand[8] = true then
            I := I + 256;
          if cMCU_pcLen > 9 then
            if RAM[cMCU_regSTATUS, 5] then
            begin
              PC[9] := true;
              I := I + 512;
            end
            else
              PC[9] := false;
          if cMCU_pcLen > 10 then
            if RAM[cMCU_regSTATUS, 6] then
            begin
              PC[10] := true;
              I := I + 1024;
            end
            else
              PC[10] := false;

          // ���  ������ ������ � PCL
          �hangeData[0] := CurrentCommand[0];
          �hangeData[1] := CurrentCommand[1];
          �hangeData[2] := CurrentCommand[2];
          �hangeData[3] := CurrentCommand[3];
          �hangeData[4] := CurrentCommand[4];
          �hangeData[5] := CurrentCommand[5];
          �hangeData[6] := CurrentCommand[6];
          �hangeData[7] := CurrentCommand[7];
          // �������� RAM �� ������ � ������������ � �������
          ChangeAddr := 2;
          ChangeDataNotInstruction := true;
          // ��� �� ����� ��� �������, ����� �� ����� I
          ChangeRAMByte();
          // �.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
          rtSyncroTMP := trunc(rtSyncroTMP + (rtCyclPerCycMK / rtSyncro));
          MC := MC + 1;
          Two_MC := true;

          goto 10;

        end
        else // 100XXXXXXXXX
        begin
          if CurrentCommand[8] then // 1001XXXXXXXX
          begin
            // ���
            // CALL
            // ������� ������� �������� �� ����� � ���������
            if StC = 2 then
            begin
              // ��� ����� ����� �������� ���������� ������ - ������������ �����, � ��� ����� ��. ���
            end;
            if StC = 1 then
            begin
              StC := StC + 1;
            end;
            if StC = 0 then
            begin
              StC := StC + 1;
            end;
            St[1] := St[0];
            for tmpByte1 := 0 to cMCU_pcLen - 1 do
              bSt[1, tmpByte1] := bSt[0, tmpByte1];
            I := I + 1;
            PCLpp();
            for tmpByte1 := 0 to cMCU_pcLen - 1 do
              bSt[0, tmpByte1] := PC[tmpByte1];

            St[0] := I;
            I := 0;
            if CurrentCommand[0] = true then
              I := I + 1;
            if CurrentCommand[1] = true then
              I := I + 2;
            if CurrentCommand[2] = true then
              I := I + 4;
            if CurrentCommand[3] = true then
              I := I + 8;
            if CurrentCommand[4] = true then
              I := I + 16;
            if CurrentCommand[5] = true then
              I := I + 32;
            if CurrentCommand[6] = true then
              I := I + 64;
            if CurrentCommand[7] = true then
              I := I + 128;
            if cMCU_pcLen > 9 then
              if RAM[cMCU_regSTATUS, 5] then
                I := I + 512;
            if cMCU_pcLen > 10 then
              if RAM[cMCU_regSTATUS, 6] then
                I := I + 1024;
            // ���  ������ ������ � PCL
            �hangeData[0] := CurrentCommand[0];
            �hangeData[1] := CurrentCommand[1];
            �hangeData[2] := CurrentCommand[2];
            �hangeData[3] := CurrentCommand[3];
            �hangeData[4] := CurrentCommand[4];
            �hangeData[5] := CurrentCommand[5];
            �hangeData[6] := CurrentCommand[6];
            �hangeData[7] := CurrentCommand[7];
            // �������� RAM �� ������ � ������������ � �������
            ChangeDataNotInstruction := true;
            // ��� �� ����� ��� �������, ����� �� ����� I
            ChangeAddr := 2;
            ChangeRAMByte();
            // �.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
            rtSyncroTMP := trunc(rtSyncroTMP + (rtCyclPerCycMK / rtSyncro));
            MC := MC + 1;
            Two_MC := true;
            goto 10

          end
          else
          begin // 1000XXXXXXXX
            // bRETLW
            // ����������� ��������� � ������� W
            �hangeData[0] := CurrentCommand[0];
            �hangeData[1] := CurrentCommand[1];
            �hangeData[2] := CurrentCommand[2];
            �hangeData[3] := CurrentCommand[3];
            �hangeData[4] := CurrentCommand[4];
            �hangeData[5] := CurrentCommand[5];
            �hangeData[6] := CurrentCommand[6];
            �hangeData[7] := CurrentCommand[7];
            // �������� RAM �� ������ � ������������ � �������
            ChangeAddr := cMCU_regW;
            ChangeRAMByte();

            // ����� �������, �� ������� ����� ����, � ��������� ��� ���������� � I
            if StC = 0 then
            begin

            end;
            if StC = 1 then
            begin
              StC := 0;

            end;
            if StC = 2 then
            begin
              StC := 1;

            end;
            I := St[0];
            �hangeData[0] := bSt[0, 0];
            �hangeData[1] := bSt[0, 1];
            �hangeData[2] := bSt[0, 2];
            �hangeData[3] := bSt[0, 3];
            �hangeData[4] := bSt[0, 4];
            �hangeData[5] := bSt[0, 5];
            �hangeData[6] := bSt[0, 6];
            �hangeData[7] := bSt[0, 7];
            // �������� RAM �� ������ � ������������ � �������
            ChangeDataNotInstruction := true;
            // ��� �� ����� ��� �������, ����� �� ����� I
            ChangeAddr := 2;
            ChangeRAMByte();
            for tmpByte1 := 0 to cMCU_pcLen - 1 do
              PC[tmpByte1] := bSt[0, tmpByte1];

            St[0] := St[1];
            for tmpByte1 := 0 to 7 do
              bSt[0, tmpByte1] := bSt[1, tmpByte1];



            // �.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
            rtSyncroTMP := trunc(rtSyncroTMP + (rtCyclPerCycMK / rtSyncro));
            MC := MC + 1;
            Two_MC := true;

            goto 10
          end;
        end;
    end
    else
    begin // 0XXXXXXXXXXX
      if CurrentCommand[10] then
      begin // 01XXXXXXXXXX
        if CurrentCommand[9] then
        begin // 011XXXXXXXXX
          if CurrentCommand[8] then
          begin // 0111XXXXXXXX
            // bBTFSS  0111bbbfffff
            // �������������� fffff � ����� ������
            tmpByte1 := 0;
            if CurrentCommand[0] then
              tmpByte1 := tmpByte1 + 1;
            if CurrentCommand[1] then
              tmpByte1 := tmpByte1 + 2;
            if CurrentCommand[2] then
              tmpByte1 := tmpByte1 + 4;
            if CurrentCommand[3] then
              tmpByte1 := tmpByte1 + 8;
            if CurrentCommand[4] then
              tmpByte1 := tmpByte1 + 16;
            // �������������� bbb � ����� ����
            tmpByte2 := 0;
            if CurrentCommand[5] then
              tmpByte2 := tmpByte2 + 1;
            if CurrentCommand[6] then
              tmpByte2 := tmpByte2 + 2;
            if CurrentCommand[7] then
              tmpByte2 := tmpByte2 + 4;
            // �.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
            ByteNo := tmpByte1;
            BitNo := tmpByte2;
            if ReadRAM() then
            begin
              // ��������� ������� �������, PCL � ��������� ��. ��������.
              I := I + 1;
              PCLpp();
              I := I + 1;
              PCLpp();
              // �.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
              rtSyncroTMP := trunc(rtSyncroTMP + (rtCyclPerCycMK / rtSyncro));
              MC := MC + 1;
              Two_MC := true;
              goto 10;
            end
            else
            begin
              I := I + 1;
              PCLpp();
              goto 10;
            end;

          end
          else
          begin // 0110XXXXXXXX
            // bBTFSC 0110bbbfffff
            // �������������� fffff � ����� ������
            tmpByte1 := 0;
            if CurrentCommand[0] then
              tmpByte1 := tmpByte1 + 1;
            if CurrentCommand[1] then
              tmpByte1 := tmpByte1 + 2;
            if CurrentCommand[2] then
              tmpByte1 := tmpByte1 + 4;
            if CurrentCommand[3] then
              tmpByte1 := tmpByte1 + 8;
            if CurrentCommand[4] then
              tmpByte1 := tmpByte1 + 16;
            // �������������� bbb � ����� ����
            tmpByte2 := 0;
            if CurrentCommand[5] then
              tmpByte2 := tmpByte2 + 1;
            if CurrentCommand[6] then
              tmpByte2 := tmpByte2 + 2;
            if CurrentCommand[7] then
              tmpByte2 := tmpByte2 + 4;
            // �.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
            ByteNo := tmpByte1;
            BitNo := tmpByte2;
            if ReadRAM() then
            begin
              // ��������� ������� �������, PCL � ��������� ��. ��������.
              I := I + 1;
              PCLpp();
              goto 10;

            end
            else
            begin
              I := I + 1;
              PCLpp();
              I := I + 1;
              PCLpp();
              // �.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
              rtSyncroTMP := trunc(rtSyncroTMP + (rtCyclPerCycMK / rtSyncro));
              MC := MC + 1;
              Two_MC := true;
              goto 10;
            end;
          end;
        end
        else
        begin // 010XXXXXXXXX
          if CurrentCommand[8] then
          begin // 0101XXXXXXXX
            // bBSF
            // �������������� fffff � ����� ������
            tmpByte1 := 0;
            if CurrentCommand[0] then
              tmpByte1 := tmpByte1 + 1;
            if CurrentCommand[1] then
              tmpByte1 := tmpByte1 + 2;
            if CurrentCommand[2] then
              tmpByte1 := tmpByte1 + 4;
            if CurrentCommand[3] then
              tmpByte1 := tmpByte1 + 8;
            if CurrentCommand[4] then
              tmpByte1 := tmpByte1 + 16;
            // �������������� bbb � ����� ����
            tmpByte2 := 0;
            if CurrentCommand[5] then
              tmpByte2 := tmpByte2 + 1;
            if CurrentCommand[6] then
              tmpByte2 := tmpByte2 + 2;
            if CurrentCommand[7] then
              tmpByte2 := tmpByte2 + 4;
            // �.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
            // �������� �������� ��������
            ChangeBitData := true;
            // �������� ����
            ChangeBitAddr := tmpByte1;
            ChangeBitNo := tmpByte2;
            ChangeRAMBit;
            // ��������� ������� �������, PCL � ��������� ��. ��������.
            I := I + 1;
            PCLpp();
            goto 10;
          end
          else
          begin // 0100XXXXXXXX
            // bBCF
            // �������������� fffff � ����� ������
            tmpByte1 := 0;
            if CurrentCommand[0] then
              tmpByte1 := tmpByte1 + 1;
            if CurrentCommand[1] then
              tmpByte1 := tmpByte1 + 2;
            if CurrentCommand[2] then
              tmpByte1 := tmpByte1 + 4;
            if CurrentCommand[3] then
              tmpByte1 := tmpByte1 + 8;
            if CurrentCommand[4] then
              tmpByte1 := tmpByte1 + 16;
            // �������������� bbb � ����� ����
            tmpByte2 := 0;
            if CurrentCommand[5] then
              tmpByte2 := tmpByte2 + 1;
            if CurrentCommand[6] then
              tmpByte2 := tmpByte2 + 2;
            if CurrentCommand[7] then
              tmpByte2 := tmpByte2 + 4;
            // �.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
            // �������� �������� ��������
            ChangeBitData := false;
            // �������� ����
            ChangeBitAddr := tmpByte1;
            ChangeBitNo := tmpByte2;
            ChangeRAMBit;
            // ��������� ������� �������, PCL � ��������� ��. ��������.
            I := I + 1;
            PCLpp();
            goto 10;
          end;
        end;

      end
      else
      begin // 00XXXXXXXXXX
        if CurrentCommand[9] then
        begin // 001XXXXXXXXX
          if CurrentCommand[8] then
          begin // 0011XXXXXXXX
            if CurrentCommand[7] then
            begin // 00111XXXXXXX
              if CurrentCommand[6] then
              begin // 001111XXXXXX
                // bINCFSZ
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();
                // �������������� ��������� ������
                if tmpAByte[0] = false then
                begin
                  tmpAByte[0] := true;
                  goto lINCFSZ1;
                end
                else
                begin
                  tmpAByte[0] := false;
                  if tmpAByte[1] = false then
                  begin
                    tmpAByte[1] := true;
                    goto lINCFSZ1;
                  end
                  else
                  begin
                    tmpAByte[1] := false;
                    if tmpAByte[2] = false then
                    begin
                      tmpAByte[2] := true;
                      goto lINCFSZ1;
                    end
                    else
                    begin
                      tmpAByte[2] := false;
                      if tmpAByte[3] = false then
                      begin
                        tmpAByte[3] := true;
                        goto lINCFSZ1;
                      end
                      else
                      begin
                        tmpAByte[3] := false;
                        if tmpAByte[4] = false then
                        begin
                          tmpAByte[4] := true;
                          goto lINCFSZ1;
                        end
                        else
                        begin
                          tmpAByte[4] := false;
                          if tmpAByte[5] = false then
                          begin
                            tmpAByte[5] := true;
                            goto lINCFSZ1;
                          end
                          else
                          begin
                            tmpAByte[5] := false;
                            if tmpAByte[6] = false then
                            begin
                              tmpAByte[6] := true;
                              goto lINCFSZ1;
                            end
                            else
                            begin
                              tmpAByte[6] := false;
                              if tmpAByte[7] = false then
                              begin
                                tmpAByte[7] := true;
                                goto lINCFSZ1;
                              end
                              else
                              begin
                                tmpAByte[7] := false;
                                // ��� ��� ��� ���������� ���, ��� ��������� ����� ����� �� 0
                                // ��������������, ���������� ��� �� 1 �.�.(���� ���� 2 �.�., �� ��� ��� ����� GOTO)
                                I := I + 1;
                                // �.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
                                rtSyncroTMP :=
                                  trunc(rtSyncroTMP +
                                  (rtCyclPerCycMK / rtSyncro));
                                MC := MC + 1;
                                Two_MC := true;
                                PCLpp();
                                goto lINCFSZ1;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;

              lINCFSZ1:
                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // ���������� (���) ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;

              end
              else
              begin // 001110XXXXXX
                // aSWAPF
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();
                // ����������, ���� ���� ��������� (��������� �� ��������� ������ B)
                tmpBByte[0] := tmpAByte[4];
                tmpBByte[1] := tmpAByte[5];
                tmpBByte[2] := tmpAByte[6];
                tmpBByte[3] := tmpAByte[7];
                tmpBByte[4] := tmpAByte[0];
                tmpBByte[5] := tmpAByte[1];
                tmpBByte[6] := tmpAByte[2];
                tmpBByte[7] := tmpAByte[3];

                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;

              end;

            end
            else
            begin // 00110XXXXXXX
              if CurrentCommand[6] then
              begin // 001101XXXXXX
                // aRLF
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();
                // ����������, ���� ���� ��������� (��������� �� ��������� ������ B � ������� �� � STATUS,0 - ���� C)
                tmpBByte[0] := RAM[3, 0];
                tmpBByte[1] := tmpAByte[0];
                tmpBByte[2] := tmpAByte[1];
                tmpBByte[3] := tmpAByte[2];
                tmpBByte[4] := tmpAByte[3];
                tmpBByte[5] := tmpAByte[4];
                tmpBByte[6] := tmpAByte[5];
                tmpBByte[7] := tmpAByte[6];
                ChangeBitData := tmpAByte[7];
                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f

                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� C � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 0;
                ChangeRAMBit;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;
              end
              else
              begin // 001100XXXXXX
                // aRRF
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();
                // ����������, ���� ���� ��������� (��������� �� ��������� ������ B � ������� �� � STATUS,0 - ���� C)
                tmpBByte[7] := RAM[3, 0];
                tmpBByte[6] := tmpAByte[7];
                tmpBByte[5] := tmpAByte[6];
                tmpBByte[4] := tmpAByte[5];
                tmpBByte[3] := tmpAByte[4];
                tmpBByte[2] := tmpAByte[3];
                tmpBByte[1] := tmpAByte[2];
                tmpBByte[0] := tmpAByte[1];
                ChangeBitData := tmpAByte[0];
                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();;
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� C � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 0;
                ChangeRAMBit;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;
              end;
            end;

          end
          else
          begin // 0010XXXXXXXX
            if CurrentCommand[7] then
            begin // 00101XXXXXXX
              if CurrentCommand[6] then
              begin // 001011XXXXXX
                // a!DECFSZ  - ������� �������� ��������� �������������
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();

                // �������������� ��������� ������
                if tmpAByte[0] = true then
                begin
                  tmpAByte[0] := false;
                  goto lDECFSZ1;
                end
                else
                begin
                  tmpAByte[0] := true;

                  if tmpAByte[1] = true then
                  begin
                    tmpAByte[1] := false;
                    goto lDECFSZ1;
                  end
                  else
                  begin
                    tmpAByte[1] := true;

                    if tmpAByte[2] = true then
                    begin
                      tmpAByte[2] := false;
                      goto lDECFSZ1;
                    end
                    else
                    begin
                      tmpAByte[2] := true;

                      if tmpAByte[3] = true then
                      begin
                        tmpAByte[3] := false;
                        goto lDECFSZ1;
                      end
                      else
                      begin
                        tmpAByte[3] := true;

                        if tmpAByte[4] = true then
                        begin
                          tmpAByte[4] := false;
                          goto lDECFSZ1;
                        end
                        else
                        begin
                          tmpAByte[4] := true;

                          if tmpAByte[5] = true then
                          begin
                            tmpAByte[5] := false;
                            goto lDECFSZ1;
                          end
                          else
                          begin
                            tmpAByte[5] := true;

                            if tmpAByte[6] = true then
                            begin
                              tmpAByte[6] := false;
                              goto lDECFSZ1;
                            end
                            else
                            begin
                              tmpAByte[6] := true;

                              if tmpAByte[7] = true then
                              begin
                                tmpAByte[7] := false;
                                goto lDECFSZ1;
                              end
                              else
                              begin
                                tmpAByte[7] := true;

                                goto lDECFSZ1;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;

              lDECFSZ1:

                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();;
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // ���������, � �� ����� �� �������� ��������� ����?
                if not �hangeData[0] and not �hangeData[1] and
                  not �hangeData[2] and not �hangeData[3] and
                  not �hangeData[4] and not �hangeData[5] and
                  not �hangeData[6] and not �hangeData[7] then
                begin
                  // ��� ��� ��� ���������� ���, ��� ��������� ����� ����� �� 0
                  // ��������������, ���������� ��� �� 1 �.�.(���� ���� 2 �.�., �� ��� ��� ����� GOTO)
                  I := I + 1;
                  // �.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
                  rtSyncroTMP :=
                    trunc(rtSyncroTMP + (rtCyclPerCycMK / rtSyncro));
                  MC := MC + 1;
                  Two_MC := true;
                  PCLpp();
                end;
                // ���������� (���) ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;
              end
              else
              begin // 001010XXXXXX
                // a!INCF   - ����������� ��������� ��������� ����� Z
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();
                ChangeBitData := false;
                // ������ Z �����, �� ������ ���� ���-� �������� �� ����� ����� 0
                // �������������� ��������� ������
                if tmpAByte[0] = false then
                begin
                  tmpAByte[0] := true;
                  goto lINCF1;
                end
                else
                begin
                  tmpAByte[0] := false;
                  if tmpAByte[1] = false then
                  begin
                    tmpAByte[1] := true;
                    goto lINCF1;
                  end
                  else
                  begin
                    tmpAByte[1] := false;
                    if tmpAByte[2] = false then
                    begin
                      tmpAByte[2] := true;
                      goto lINCF1;
                    end
                    else
                    begin
                      tmpAByte[2] := false;
                      if tmpAByte[3] = false then
                      begin
                        tmpAByte[3] := true;
                        goto lINCF1;
                      end
                      else
                      begin
                        tmpAByte[3] := false;
                        if tmpAByte[4] = false then
                        begin
                          tmpAByte[4] := true;
                          goto lINCF1;
                        end
                        else
                        begin
                          tmpAByte[4] := false;
                          if tmpAByte[5] = false then
                          begin
                            tmpAByte[5] := true;
                            goto lINCF1;
                          end
                          else
                          begin
                            tmpAByte[5] := false;
                            if tmpAByte[6] = false then
                            begin
                              tmpAByte[6] := true;
                              goto lINCF1;
                            end
                            else
                            begin
                              tmpAByte[6] := false;
                              if tmpAByte[7] = false then
                              begin
                                tmpAByte[7] := true;
                                goto lINCF1;
                              end
                              else
                              begin
                                tmpAByte[7] := false;
                                // ��� ��� ��� ���������� ���, ��� ��������� ����� ����� �� 0
                                // ������������� ���� Z
                                ChangeBitData := true;
                                goto lINCF1;
                              end;
                            end;
                          end;
                        end;
                      end;
                    end;
                  end;
                end;

              lINCF1:
                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();;
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // C�������� ���������� - �� ������� ���������
                I := I + 1;
                PCLpp();
                goto 10;
              end
            end
            else
            begin // 00100XXXXXXX
              if CurrentCommand[6] then
              begin // 001001XXXXXX
                // aCOMF
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();
                ChangeBitData := true;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                // ����������, ���� ��������
                if tmpAByte[0] then
                begin
                  tmpBByte[0] := false;
                end
                else
                begin
                  tmpBByte[0] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                if tmpAByte[1] then
                begin
                  tmpBByte[1] := false;
                end
                else
                begin
                  tmpBByte[1] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                if tmpAByte[2] then
                begin
                  tmpBByte[2] := false;
                end
                else
                begin
                  tmpBByte[2] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                if tmpAByte[3] then
                begin
                  tmpBByte[3] := false;
                end
                else
                begin
                  tmpBByte[3] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                if tmpAByte[4] then
                begin
                  tmpBByte[4] := false;
                end
                else
                begin
                  tmpBByte[4] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                if tmpAByte[5] then
                begin
                  tmpBByte[5] := false;
                end
                else
                begin
                  tmpBByte[5] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                if tmpAByte[6] then
                begin
                  tmpBByte[6] := false;
                end
                else
                begin
                  tmpBByte[6] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                if tmpAByte[7] then
                begin
                  tmpBByte[7] := false;
                end
                else
                begin
                  tmpBByte[7] := true;
                  ChangeBitData := false; // ������ Z �����
                end;
                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;

              end
              else
              begin // 001000XXXXXX
                // aMOVF
                // ����������� � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ��������� f �� ��������� ������
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpAByte[0] := ReadRAM();
                BitNo := 1;
                tmpAByte[1] := ReadRAM();
                BitNo := 2;
                tmpAByte[2] := ReadRAM();
                BitNo := 3;
                tmpAByte[3] := ReadRAM();
                BitNo := 4;
                tmpAByte[4] := ReadRAM();
                BitNo := 5;
                tmpAByte[5] := ReadRAM();
                BitNo := 6;
                tmpAByte[6] := ReadRAM();
                BitNo := 7;
                tmpAByte[7] := ReadRAM();
                ChangeBitData := true;;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                // �������� �� ���� Z
                if tmpAByte[0] = true then
                  ChangeBitData := false;;
                if tmpAByte[1] = true then
                  ChangeBitData := false;;
                if tmpAByte[2] = true then
                  ChangeBitData := false;;
                if tmpAByte[3] = true then
                  ChangeBitData := false;;
                if tmpAByte[4] = true then
                  ChangeBitData := false;;
                if tmpAByte[5] = true then
                  ChangeBitData := false;;
                if tmpAByte[6] = true then
                  ChangeBitData := false;;
                if tmpAByte[7] = true then
                  ChangeBitData := false;;

                // �������� ��� � ����� ����������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpAByte[0];
                  �hangeData[1] := tmpAByte[1];
                  �hangeData[2] := tmpAByte[2];
                  �hangeData[3] := tmpAByte[3];
                  �hangeData[4] := tmpAByte[4];
                  �hangeData[5] := tmpAByte[5];
                  �hangeData[6] := tmpAByte[6];
                  �hangeData[7] := tmpAByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;

              end;
            end;
          end;

        end
        else
        begin // 000XXXXXXXXX
          if CurrentCommand[8] then
          begin // 0001XXXXXXXX
            if CurrentCommand[7] then
            begin // 00011XXXXXXX
              if CurrentCommand[6] then
              begin // 000111XXXXXX
                // aADDWF   - ��� ���� �������� ��������� W � f
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ���� ��������� ��������
                tmpBit1 := true;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                tmpByte2 := 0;
                if RAM[cMCU_regW, 0] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 0;

                if ReadRAM() then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[0] := false;
                  tmpAByte[0] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[0] := true;
                  tmpAByte[0] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[0] := false;
                  tmpAByte[0] := true;
                end
                else
                begin
                  tmpBByte[0] := true;
                  tmpAByte[0] := true;
                  tmpBit1 := false;
                end;
                tmpByte2 := 0;
                if RAM[cMCU_regW, 1] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 1;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[0] then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[1] := false;
                  tmpAByte[1] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[1] := true;
                  tmpAByte[1] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[1] := false;
                  tmpAByte[1] := true;
                end
                else
                begin
                  tmpBByte[1] := true;
                  tmpAByte[1] := true;
                  tmpBit1 := false;
                end;
                tmpByte2 := 0;
                if RAM[cMCU_regW, 2] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 2;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[1] then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[2] := false;
                  tmpAByte[2] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[2] := true;
                  tmpAByte[2] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[2] := false;
                  tmpAByte[2] := true;
                end
                else
                begin
                  tmpBByte[2] := true;
                  tmpAByte[2] := true;
                  tmpBit1 := false;
                end;
                tmpByte2 := 0;
                if RAM[cMCU_regW, 3] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 3;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[2] then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[3] := false;
                  tmpAByte[3] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[3] := true;
                  tmpAByte[3] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[3] := false;
                  tmpAByte[3] := true;
                end
                else
                begin
                  tmpBByte[3] := true;
                  tmpAByte[3] := true;
                  tmpBit1 := false;
                end;
                tmpByte2 := 0;
                if RAM[cMCU_regW, 4] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 4;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[3] then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[4] := false;
                  tmpAByte[4] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[4] := true;
                  tmpAByte[4] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[4] := false;
                  tmpAByte[4] := true;
                end
                else
                begin
                  tmpBByte[4] := true;
                  tmpAByte[4] := true;
                  tmpBit1 := false;
                end;
                tmpByte2 := 0;
                if RAM[cMCU_regW, 5] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 5;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[4] then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[5] := false;
                  tmpAByte[5] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[5] := true;
                  tmpAByte[5] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[5] := false;
                  tmpAByte[5] := true;
                end
                else
                begin
                  tmpBByte[5] := true;
                  tmpAByte[5] := true;
                  tmpBit1 := false;
                end;
                tmpByte2 := 0;
                if RAM[cMCU_regW, 6] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 6;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[5] then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[6] := false;
                  tmpAByte[6] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[6] := true;
                  tmpAByte[6] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[6] := false;
                  tmpAByte[6] := true;
                end
                else
                begin
                  tmpBByte[6] := true;
                  tmpAByte[6] := true;
                  tmpBit1 := false;
                end;
                tmpByte2 := 0;
                if RAM[cMCU_regW, 7] then
                  inc(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 7;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[6] then
                  inc(tmpByte2);
                if tmpByte2 = 0 then
                begin
                  tmpBByte[7] := false;
                  tmpAByte[7] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[7] := true;
                  tmpAByte[7] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpBByte[7] := false;
                  tmpAByte[7] := true;
                end
                else
                begin
                  tmpBByte[7] := true;
                  tmpAByte[7] := true;
                  tmpBit1 := false;
                end;

                // ��������� �������� �����������, ������ ��������� ����� �� ����� ��������
                tmpBit2 := tmpAByte[7]; // ������� ����� C
                tmpBit3 := tmpAByte[3]; // ������� ����� DC
                // ������ ��������� ���������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // ������� ���� Z
                ChangeBitData := tmpBit1;
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // ������� ���� C
                ChangeBitData := tmpBit2;
                ChangeBitAddr := 3;
                ChangeBitNo := 0;
                ChangeRAMBit;
                // ������� ���� DC
                ChangeBitData := tmpBit3;
                ChangeBitAddr := 3;
                ChangeBitNo := 1;
                ChangeRAMBit;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;
              end
              else
              begin // 000110XXXXXX
                // aXORWF
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                ChangeBitData := true;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                // ����� ���� �������� XOR �-� ��������� f � ��������� W.  ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpBByte[0] := RAM[cMCU_regW, 0] XOR ReadRAM();
                if tmpBByte[0] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 1;
                tmpBByte[1] := RAM[cMCU_regW, 1] XOR ReadRAM();
                if tmpBByte[1] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 2;
                tmpBByte[2] := RAM[cMCU_regW, 2] XOR ReadRAM();
                if tmpBByte[2] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 3;
                tmpBByte[3] := RAM[cMCU_regW, 3] XOR ReadRAM();
                if tmpBByte[3] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 4;
                tmpBByte[4] := RAM[cMCU_regW, 4] XOR ReadRAM();
                if tmpBByte[4] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 5;
                tmpBByte[5] := RAM[cMCU_regW, 5] XOR ReadRAM();
                if tmpBByte[5] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 6;
                tmpBByte[6] := RAM[cMCU_regW, 6] XOR ReadRAM();
                if tmpBByte[6] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 7;
                tmpBByte[7] := RAM[cMCU_regW, 7] XOR ReadRAM();
                if tmpBByte[7] then
                  ChangeBitData := false;
                // ������ ��������� ���������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // ��������� ������� �������, � ��������� ��. ��������.
                I := I + 1;
                PCLpp();
                goto 10;
              end;
            end
            else
            begin // 00010XXXXXXX
              if CurrentCommand[6] then
              begin // 000101XXXXXX
                // aANDWF
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                ChangeBitData := true;;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                // ����� ���� �������� XOR �-� ��������� f � ��������� W.  ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpBByte[0] := RAM[cMCU_regW, 0] AND ReadRAM();
                if tmpBByte[0] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 1;
                tmpBByte[1] := RAM[cMCU_regW, 1] AND ReadRAM();
                if tmpBByte[1] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 2;
                tmpBByte[2] := RAM[cMCU_regW, 2] AND ReadRAM();
                if tmpBByte[2] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 3;
                tmpBByte[3] := RAM[cMCU_regW, 3] AND ReadRAM();
                if tmpBByte[3] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 4;
                tmpBByte[4] := RAM[cMCU_regW, 4] AND ReadRAM();
                if tmpBByte[4] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 5;
                tmpBByte[5] := RAM[cMCU_regW, 5] AND ReadRAM();
                if tmpBByte[5] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 6;
                tmpBByte[6] := RAM[cMCU_regW, 6] AND ReadRAM();
                if tmpBByte[6] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 7;
                tmpBByte[7] := RAM[cMCU_regW, 7] AND ReadRAM();
                if tmpBByte[7] then
                  ChangeBitData := false;
                // ������ ��������� ���������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // ��������� ������� �������, � ��������� ��. ��������.
                I := I + 1;
                PCLpp();
                goto 10;
              end
              else
              begin // 000100XXXXXX
                // aIORWF
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                ChangeBitData := true;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                // ����� ���� �������� XOR �-� ��������� f � ��������� W.  ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
                ByteNo := tmpByte1;
                BitNo := 0;
                tmpBByte[0] := RAM[cMCU_regW, 0] OR ReadRAM();
                if tmpBByte[0] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 1;
                tmpBByte[1] := RAM[cMCU_regW, 1] OR ReadRAM();
                if tmpBByte[1] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 2;
                tmpBByte[2] := RAM[cMCU_regW, 2] OR ReadRAM();
                if tmpBByte[2] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 3;
                tmpBByte[3] := RAM[cMCU_regW, 3] OR ReadRAM();
                if tmpBByte[3] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 4;
                tmpBByte[4] := RAM[cMCU_regW, 4] OR ReadRAM();
                if tmpBByte[4] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 5;
                tmpBByte[5] := RAM[cMCU_regW, 5] OR ReadRAM();
                if tmpBByte[5] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 6;
                tmpBByte[6] := RAM[cMCU_regW, 6] OR ReadRAM();
                if tmpBByte[6] then
                  ChangeBitData := false;
                ByteNo := tmpByte1;
                BitNo := 7;
                tmpBByte[7] := RAM[cMCU_regW, 7] OR ReadRAM();
                if tmpBByte[7] then
                  ChangeBitData := false;
                // ������ ��������� ���������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // ��������� ������� �������, � ��������� ��. ��������.
                I := I + 1;
                PCLpp();
                goto 10;
              end;
            end;

          end
          else
          begin // 0000XXXXXXXX
            if CurrentCommand[7] then
            begin // 00001XXXXXXX
              if CurrentCommand[6] then
              begin // 000011XXXXXX
                // aDECF
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ���� ��������� ���������
                ChangeBitData := true;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                tmpByte2 := 1;
                ByteNo := tmpByte1;
                BitNo := 0;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpByte2 = 2 then
                begin
                  tmpAByte[0] := false;
                  tmpBByte[0] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[0] := true;
                  tmpAByte[0] := true;
                  ChangeBitData := false;
                end;
                tmpByte2 := 2;
                ByteNo := tmpByte1;
                BitNo := 1;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[0] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[1] := true;
                  tmpAByte[1] := false;
                  ChangeBitData := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[1] := false;
                  tmpBByte[1] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[1] := true;
                  tmpAByte[1] := true;
                  ChangeBitData := false;
                end;
                tmpByte2 := 2;
                ByteNo := tmpByte1;
                BitNo := 2;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[1] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[2] := true;
                  tmpAByte[2] := false;
                  ChangeBitData := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[2] := false;
                  tmpBByte[2] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[2] := true;
                  tmpAByte[2] := true;
                  ChangeBitData := false;
                end;
                tmpByte2 := 2;
                ByteNo := tmpByte1;
                BitNo := 3;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[2] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[3] := true;
                  tmpAByte[3] := false;
                  ChangeBitData := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[3] := false;
                  tmpBByte[3] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[3] := true;
                  tmpAByte[3] := true;
                  ChangeBitData := false;
                end;
                tmpByte2 := 2;
                ByteNo := tmpByte1;
                BitNo := 4;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[3] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[4] := true;
                  tmpAByte[4] := false;
                  ChangeBitData := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[4] := false;
                  tmpBByte[4] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[4] := true;
                  tmpAByte[4] := true;
                  ChangeBitData := false;
                end;
                tmpByte2 := 2;
                ByteNo := tmpByte1;
                BitNo := 5;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[4] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[5] := true;
                  tmpAByte[5] := false;
                  ChangeBitData := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[5] := false;
                  tmpBByte[5] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[5] := true;
                  tmpAByte[5] := true;
                  ChangeBitData := false;
                end;
                tmpByte2 := 2;
                ByteNo := tmpByte1;
                BitNo := 6;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[5] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[6] := true;
                  tmpAByte[6] := false;
                  ChangeBitData := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[6] := false;
                  tmpBByte[6] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[6] := true;
                  tmpAByte[6] := true;
                  ChangeBitData := false;
                end;
                tmpByte2 := 2;
                ByteNo := tmpByte1;
                BitNo := 7;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[6] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[7] := true;
                  tmpAByte[7] := false;
                  ChangeBitData := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[7] := false;
                  tmpBByte[7] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[7] := true;
                  tmpAByte[7] := true;
                  ChangeBitData := false;
                end;
                // ������ ��������� ���������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;
              end
              else
              begin // 000010XXXXXX
                // bSUBWF
                // �������������� fffff � ����� ������
                tmpByte1 := 0;
                if CurrentCommand[0] then
                  tmpByte1 := tmpByte1 + 1;
                if CurrentCommand[1] then
                  tmpByte1 := tmpByte1 + 2;
                if CurrentCommand[2] then
                  tmpByte1 := tmpByte1 + 4;
                if CurrentCommand[3] then
                  tmpByte1 := tmpByte1 + 8;
                if CurrentCommand[4] then
                  tmpByte1 := tmpByte1 + 16;
                // ���� ��������� ���������
                tmpBit1 := true;
                // ��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
                tmpByte2 := 2;
                if RAM[cMCU_regW, 0] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 0;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[0] := true;
                  tmpAByte[0] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[0] := false;
                  tmpBByte[0] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[0] := true;
                  tmpAByte[0] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[0] := false;
                  tmpAByte[0] := true;
                end;
                tmpByte2 := 2;
                if RAM[cMCU_regW, 1] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 1;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[0] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[1] := true;
                  tmpAByte[1] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[1] := false;
                  tmpBByte[1] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[1] := true;
                  tmpAByte[1] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[1] := false;
                  tmpAByte[1] := true;
                end;
                tmpByte2 := 2;
                if RAM[cMCU_regW, 2] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 2;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[1] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[2] := true;
                  tmpAByte[2] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[2] := false;
                  tmpBByte[2] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[2] := true;
                  tmpAByte[2] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[2] := false;
                  tmpAByte[2] := true;
                end;
                tmpByte2 := 2;
                if RAM[cMCU_regW, 3] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 3;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[2] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[3] := true;
                  tmpAByte[3] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[3] := false;
                  tmpBByte[3] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[3] := true;
                  tmpAByte[3] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[3] := false;
                  tmpAByte[3] := true;
                end;
                tmpByte2 := 2;
                if RAM[cMCU_regW, 4] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 4;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[3] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[4] := true;
                  tmpAByte[4] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[4] := false;
                  tmpBByte[4] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[4] := true;
                  tmpAByte[4] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[4] := false;
                  tmpAByte[4] := true;
                end;
                tmpByte2 := 2;
                if RAM[cMCU_regW, 5] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 5;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[4] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[5] := true;
                  tmpAByte[5] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[5] := false;
                  tmpBByte[5] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[5] := true;
                  tmpAByte[5] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[5] := false;
                  tmpAByte[5] := true;
                end;
                tmpByte2 := 2;
                if RAM[cMCU_regW, 6] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 6;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[5] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[6] := true;
                  tmpAByte[6] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[6] := false;
                  tmpBByte[6] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[6] := true;
                  tmpAByte[6] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[6] := false;
                  tmpAByte[6] := true;
                end;
                tmpByte2 := 2;
                if RAM[cMCU_regW, 7] then
                  Dec(tmpByte2);
                ByteNo := tmpByte1;
                BitNo := 7;
                if ReadRAM() then
                  inc(tmpByte2);
                if tmpAByte[6] then
                  Dec(tmpByte2);
                if tmpByte2 = 3 then
                begin
                  tmpBByte[7] := true;
                  tmpAByte[7] := false;
                  tmpBit1 := false;
                end
                else if tmpByte2 = 2 then
                begin
                  tmpAByte[7] := false;
                  tmpBByte[7] := false;
                end
                else if tmpByte2 = 1 then
                begin
                  tmpBByte[7] := true;
                  tmpAByte[7] := true;
                  tmpBit1 := false;
                end
                else
                begin
                  tmpBByte[7] := false;
                  tmpAByte[7] := true;
                end;

                // ��������� ������ �����������, ������ ��������� ����� �� ����� ��������
                tmpBit2 := not tmpAByte[7]; // ������� ����� C
                // �� � ����� DC
                tmpBit3 := not tmpAByte[3]; // ������� ����� DC
                // ������ ��������� ���������
                if CurrentCommand[5] then
                begin // ��� ������ � ������� f
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                end
                else
                begin // ��� ������ � ������� W
                  �hangeData[0] := tmpBByte[0];
                  �hangeData[1] := tmpBByte[1];
                  �hangeData[2] := tmpBByte[2];
                  �hangeData[3] := tmpBByte[3];
                  �hangeData[4] := tmpBByte[4];
                  �hangeData[5] := tmpBByte[5];
                  �hangeData[6] := tmpBByte[6];
                  �hangeData[7] := tmpBByte[7];

                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                end;
                // �������� ���� Z � Status
                ChangeBitData := tmpBit1;
                ChangeBitAddr := 3;
                ChangeBitNo := 2;
                ChangeRAMBit;
                // �������� ���� C � Status
                ChangeBitData := tmpBit2;
                ChangeBitAddr := 3;
                ChangeBitNo := 0;
                ChangeRAMBit;
                // �������� ���� DC � Status
                ChangeBitData := tmpBit3;
                ChangeBitAddr := 3;
                ChangeBitNo := 1;
                ChangeRAMBit;
                // ����������  ��� �� 1 �.�.
                I := I + 1;
                PCLpp();
                goto 10;
              end;

            end
            else
            begin // 00000XXXXXXX
              if CurrentCommand[6] then
              begin // 000001XXXXXX
                if CurrentCommand[5] then
                begin // 0000011XXXXX
                  // aCLRF
                  // �������������� fffff � ����� ������
                  tmpByte1 := 0;
                  if CurrentCommand[0] then
                    tmpByte1 := tmpByte1 + 1;
                  if CurrentCommand[1] then
                    tmpByte1 := tmpByte1 + 2;
                  if CurrentCommand[2] then
                    tmpByte1 := tmpByte1 + 4;
                  if CurrentCommand[3] then
                    tmpByte1 := tmpByte1 + 8;
                  if CurrentCommand[4] then
                    tmpByte1 := tmpByte1 + 16;
                  // ���� ��������� �������
                  ChangeBitData := true;
                  // ��������� Z �����, ������ ����� ���������� � ���� ����
                  �hangeData[0] := false;
                  �hangeData[1] := false;
                  �hangeData[2] := false;
                  �hangeData[3] := false;
                  �hangeData[4] := false;
                  �hangeData[5] := false;
                  �hangeData[6] := false;
                  �hangeData[7] := false;
                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                  // �������� ���� Z � Status
                  ChangeBitAddr := 3;
                  ChangeBitNo := 2;
                  ChangeRAMBit;
                  // ����������  ��� �� 1 �.�.
                  I := I + 1;
                  PCLpp();
                  goto 10;
                end
                else
                begin // 0000010XXXXX
                  // aCLRW
                  ChangeBitData := true;
                  // ��������� Z �����, ������ ����� ���������� � ���� ����
                  �hangeData[0] := false;
                  �hangeData[1] := false;
                  �hangeData[2] := false;
                  �hangeData[3] := false;
                  �hangeData[4] := false;
                  �hangeData[5] := false;
                  �hangeData[6] := false;
                  �hangeData[7] := false;
                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := cMCU_regW;
                  ChangeRAMByte();
                  // �������� ���� Z � Status
                  ChangeBitAddr := 3;
                  ChangeBitNo := 2;
                  ChangeRAMBit;
                  // ����������  ��� �� 1 �.�.
                  I := I + 1;
                  PCLpp();
                  goto 10;
                end;
              end
              else
              begin // 000000XXXXXX
                if CurrentCommand[5] then
                begin // 0000001XXXXX
                  // aMOVWF
                  // �������������� fffff � ����� ������
                  tmpByte1 := 0;
                  if CurrentCommand[0] then
                    tmpByte1 := tmpByte1 + 1;
                  if CurrentCommand[1] then
                    tmpByte1 := tmpByte1 + 2;
                  if CurrentCommand[2] then
                    tmpByte1 := tmpByte1 + 4;
                  if CurrentCommand[3] then
                    tmpByte1 := tmpByte1 + 8;
                  if CurrentCommand[4] then
                    tmpByte1 := tmpByte1 + 16;
                  // ���� ��������� �������� W->f
                  �hangeData[0] := RAM[cMCU_regW, 0];
                  �hangeData[1] := RAM[cMCU_regW, 1];
                  �hangeData[2] := RAM[cMCU_regW, 2];
                  �hangeData[3] := RAM[cMCU_regW, 3];
                  �hangeData[4] := RAM[cMCU_regW, 4];
                  �hangeData[5] := RAM[cMCU_regW, 5];
                  �hangeData[6] := RAM[cMCU_regW, 6];
                  �hangeData[7] := RAM[cMCU_regW, 7];
                  // �������� RAM �� ������ � ������������ � �������
                  ChangeAddr := tmpByte1;
                  ChangeRAMByte();
                  // ����������  ��� �� 1 �.�.
                  I := I + 1;
                  PCLpp();
                  goto 10;
                end
                else
                begin // 0000000XXXXX
                  if CurrentCommand[4] then
                  begin // 00000001XXXX
                    // Unknow command
                    // ����������  ��� �� 1 �.�.
                    I := I + 1;
                    PCLpp();
                    goto 10;
                  end
                  else
                  begin // 00000000XXXX
                    if CurrentCommand[3] then
                    begin // 000000001XXX
                      if CurrentCommand[2] then
                      begin // 0000000011XX
                        // Unknow command
                        // ����������  ��� �� 1 �.�.
                        I := I + 1;
                        PCLpp();
                        goto 10;
                      end
                      else
                      begin // 0000000010XX
                        if CurrentCommand[1] then
                        begin // 00000000101X
                          // Unknow command
                          // ����������  ��� �� 1 �.�.
                          I := I + 1;
                          PCLpp();
                          goto 10;
                        end
                        else
                        begin // 00000000100X
                          if CurrentCommand[0] then
                          begin // 000000001001
                            // TRIS 9 TRIS PORTE
                            if not cMCU_avGPIO then
                            // ���� ��� GPIO, ������ ����� ���� �����
                              for tmpInt3 := 0 to cMCU_hiPORTE do
                              begin
                                tmpBit1 := RAM[cMCU_regW, tmpInt3];
                                // �������� �����
                                ChangeBitData := tmpBit1;
                                ChangeBitAddr := cMCU_regTRISE;
                                ChangeBitNo := tmpInt3;
                                ChangeRAMBit;
                              end;
                            // � ����� ������, ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end
                          else
                          begin // 000000001000
                            // TRIS 8 TRIS PORTD
                            if not cMCU_avGPIO then
                            // ���� ��� GPIO, ������ ����� ���� �����
                              for tmpInt3 := 0 to cMCU_hiPORTD do
                              begin
                                tmpBit1 := RAM[cMCU_regW, tmpInt3];
                                // �������� �����
                                ChangeBitData := tmpBit1;
                                ChangeBitAddr := cMCU_regTRISD;
                                ChangeBitNo := tmpInt3;
                                ChangeRAMBit;
                              end;
                            // � ����� ������, ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end;
                        end;
                      end;
                    end
                    else
                    begin // 000000000XXX
                      if CurrentCommand[2] then
                      begin // 0000000001XX
                        if CurrentCommand[1] then
                        begin // 00000000011X
                          if CurrentCommand[0] then
                          begin // 000000000111
                            // !TRIS 7
                            if not cMCU_avGPIO then
                            // ���� ��� GPIO, ������ ����� ���� �����
                              for tmpInt3 := 0 to cMCU_hiPORTC do
                              begin
                                tmpBit1 := RAM[cMCU_regW, tmpInt3];
                                // �������� �����
                                ChangeBitData := tmpBit1;
                                ChangeBitAddr := cMCU_regTRISC;
                                ChangeBitNo := tmpInt3;
                                ChangeRAMBit;
                              end;

                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end
                          else
                          begin // 000000000110
                            if not cMCU_avGPIO then
                            // ���� ��� GPIO, ������ ����� ���� �����

                              if cMCU_hiPORTB = 5 then
                              begin // ������ ��� PIC16F505/506/526 (������ �������)
                                tmpBit1 := RAM[cMCU_regW, 0];
                                tmpBit2 := RAM[cMCU_regW, 1];
                                tmpBit3 := RAM[cMCU_regW, 2];
                                // �������� �����
                                ChangeBitData := tmpBit1;
                                ChangeBitAddr := cMCU_regPORTB;
                                ChangeBitNo := 0;
                                ChangeRAMBit;
                                ChangeBitData := tmpBit2;
                                ChangeBitAddr := cMCU_regPORTB;
                                ChangeBitNo := 1;
                                ChangeRAMBit;
                                ChangeBitData := tmpBit3;
                                ChangeBitAddr := cMCU_regPORTB;
                                ChangeBitNo := 2;
                                ChangeRAMBit;
                                tmpBit1 := RAM[cMCU_regW, 4];
                                tmpBit2 := RAM[cMCU_regW, 5];
                                // �������� �����
                                ChangeBitData := tmpBit1;
                                ChangeBitAddr := cMCU_regPORTB;
                                ChangeBitNo := 4;
                                ChangeRAMBit;
                                ChangeBitData := tmpBit2;
                                ChangeBitAddr := cMCU_regPORTB;
                                ChangeBitNo := 5;
                                ChangeRAMBit;
                              end
                              else
                              begin // ��� PIC16F5X
                                for tmpInt3 := 0 to cMCU_hiPORTB do
                                begin
                                  tmpBit1 := RAM[cMCU_regW, tmpInt3];
                                  // �������� �����
                                  ChangeBitData := tmpBit1;
                                  ChangeBitAddr := cMCU_regTRISB;
                                  ChangeBitNo := tmpInt3;
                                  ChangeRAMBit;
                                end;
                              end
                            else
                            begin // ����� GPIO
                              // aTRIS 6
                              tmpBit1 := RAM[cMCU_regW, 0];
                              tmpBit2 := RAM[cMCU_regW, 1];
                              tmpBit3 := RAM[cMCU_regW, 2];
                              // �������� �����
                              ChangeBitData := tmpBit1;
                              ChangeBitAddr := cMCU_regTRISGPIO;
                              ChangeBitNo := 0;
                              ChangeRAMBit;
                              ChangeBitData := tmpBit2;
                              ChangeBitAddr := cMCU_regTRISGPIO;
                              ChangeBitNo := 1;
                              ChangeRAMBit;
                              ChangeBitData := tmpBit3;
                              ChangeBitAddr := cMCU_regTRISGPIO;
                              ChangeBitNo := 2;
                              ChangeRAMBit;
                              for tmpInt3 := 4 to cMCU_hiGPIO do
                              begin // ���������� ��� PIC12FXXX, � ���. 6 GPIO
                                tmpBit1 := RAM[cMCU_regW, tmpInt3];
                                // �������� �����
                                ChangeBitData := tmpBit1;
                                ChangeBitAddr := cMCU_regTRISGPIO;
                                ChangeBitNo := tmpInt3;
                                ChangeRAMBit;
                              end;
                            end;
                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end;
                        end
                        else
                        begin // 00000000010X
                          if CurrentCommand[0] then
                          begin // 000000000101
                            // !TRIS 5 - PORTA
                            if not cMCU_avGPIO then
                            // ���� ��� GPIO, ������ ����� ���� �����
                              for tmpInt3 := 0 to cMCU_hiPORTA do
                              begin
                                tmpBit1 := RAM[cMCU_regW, tmpInt3];
                                // �������� �����
                                ChangeBitData := tmpBit1;
                                ChangeBitAddr := cMCU_regTRISA;
                                ChangeBitNo := tmpInt3;
                                ChangeRAMBit;
                              end;
                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end
                          else
                          begin // 000000000100
                            // !CLRWDT
                            // �������� WDT
                            CLRWDT();
                            // �� ������! ��� ����������� � ��� ��. ��������

                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end;

                        end;

                      end
                      else
                      begin // 0000000000XX
                        if CurrentCommand[1] then
                        begin // 00000000001X
                          if CurrentCommand[0] then
                          Begin // 000000000011
                            // !Sleep

                            // ��������� ������ "���"
                            SleepMode := true;
                            // �������� WDT � ���������� ����� ��� SLEEP
                            CLRWDT();
                            // �������� ��������� ������� GPIO
                            ByteNo := 6;
                            BitNo := 0;
                            sleepRegGPIO[0] := ReadRAM();
                            ByteNo := 6;
                            BitNo := 1;
                            sleepRegGPIO[1] := ReadRAM();
                            ByteNo := 6;
                            BitNo := 2;
                            sleepRegGPIO[2] := ReadRAM();
                            ByteNo := 6;
                            BitNo := 3;
                            sleepRegGPIO[3] := ReadRAM();
                            // �������� ��������� ���� ����������� (���� �� ���� � �������
                            if cMCU_regCMCON > -1 then
                              // ���������� ����
                              if RAM[cMCU_regCMCON, 3] then
                              // ���������� �������
                              begin
                                ByteNo := cMCU_regCMCON;
                                BitNo := 7;
                                sleepCM := ReadRAM();
                              end;
                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          End
                          else
                          begin // 000000000010
                            // aOPTION
                            �hangeData[0] := RAM[cMCU_regW, 0];
                            �hangeData[1] := RAM[cMCU_regW, 1];
                            �hangeData[2] := RAM[cMCU_regW, 2];
                            �hangeData[3] := RAM[cMCU_regW, 3];
                            �hangeData[4] := RAM[cMCU_regW, 4];
                            �hangeData[5] := RAM[cMCU_regW, 5];
                            �hangeData[6] := RAM[cMCU_regW, 6];
                            �hangeData[7] := RAM[cMCU_regW, 7];
                            // �������� RAM �� ������ � ������������ � �������
                            ChangeAddr := cMCU_regOPTION;
                            ChangeRAMByte();
                            // ��������, � �� ��������� �� ������������ ����� TMR0
                            // ��� ���� BASELINE
                            if RAM[cMCU_regOPTION, 3] = false then
                            begin // ���������
                              // �������� ��� �������� TMR0 prescaler
                              par[0] := RAM[cMCU_regOPTION, 0];
                              par[1] := RAM[cMCU_regOPTION, 1];
                              par[2] := RAM[cMCU_regOPTION, 2];
                              par[3] := false;
                              par[4] := false;
                              par[5] := false;
                              par[6] := false;
                              par[7] := false;
                              tmpInt2 := BinToDec() + 1;
                              for tmpInt := tmpInt2 to 7 do
                              begin
                                MatrixRAM[cMCU_regTMR0P].usedbit
                                  [tmpInt] := false;
                                RAM[cMCU_regTMR0P, tmpInt] := false;
                              end;
                              tmpInt2 := tmpInt2 - 1;
                              for tmpInt := 0 to tmpInt2 do
                              begin
                                MatrixRAM[cMCU_regTMR0P].usedbit
                                  [tmpInt] := true;
                                RAM[cMCU_regTMR0P, tmpInt] := false;
                              end;
                            end
                            else
                            begin // �� ���������
                              // �������� ��� �������� TMR0 prescaler (�������)
                              for tmpInt := 0 to 7 do
                              begin
                                MatrixRAM[cMCU_regTMR0P].usedbit
                                  [tmpInt] := false;
                                RAM[cMCU_regTMR0P, tmpInt] := false;
                              end;
                            end;

                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end;

                        end
                        else
                        begin // 00000000000X
                          if CurrentCommand[0] then
                          Begin // 000000000001
                            // Unknow command
                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          End
                          else
                          begin // 000000000000
                            // aNOP
                            // ����������  ��� �� 1 �.�.
                            I := I + 1;
                            PCLpp();
                            goto 10;
                          end;
                        end;
                      end;
                    end;

                  end;

                end;
              end;
            end;

          end;
        end;
      end;
    end;
  end;

end;

Function Get_family_mc(): PChar; stdcall;
begin
  result := PChar('Microchip PIC Baseline');
end;

Function Get_SystemCommandCounter(): integer; stdcall;
begin
  Get_SystemCommandCounter := SystemCommandCounter;
end;

{
  Function Get_ConfigBitsCounter(): Integer; stdcall;
  begin
  Get_ConfigBitsCounter := ConfigBitsCounter;
  end;

  Function Get_ConfigBitsHI(): Integer; stdcall;
  begin
  Get_ConfigBitsHI := high(Config);
  end; }

Function Get_rtRunning(): boolean; stdcall;
begin
  Get_rtRunning := rtRunning;
end;

Procedure Set_rtRunning(val: boolean); stdcall;
begin
  rtRunning := val;
end;

Function Get_UserTimer(): Extended; stdcall;
begin
  Get_UserTimer := UserTimer;
end;

Procedure Set_UserTimer(val: Extended); stdcall;
begin
  UserTimer := val;
end;

Procedure Get_MCandCF(var vMC: int64; var vCF: integer); stdcall;
begin
  vMC := MC;
  vCF := rtCrystalFreq;
end;

Function Get_RAM(val1, val2: integer): boolean; stdcall;
begin
  Get_RAM := RAM[val1, val2];
end;

Procedure Set_RAM(val1, val2: integer; val3: boolean); stdcall;
var tmpPause:boolean;

label lbl1;

begin
//��� ���� ����� ��� ������������� � �������, �.�. ���������� "�����", �������� ����� ����� ��� ����������� ��������� changeRamBit;
tmpPause:=rtPause;
rtPause:=true;
rtRefreshComplete:=true;   //������� 3.04.2016 ��� ������ �����
lbl1:
  if not rtPaused then
    begin
      application.ProcessMessages;
      goto lbl1;
    end;

  ChangeDataNotInstruction:=false;
  ChangeBitAddr:=Val1;
  ChangeBitNo:=Val2;
  ChangeBitData:=Val3;
  ChangeRamBit;
//  RAM[val1, val2] := val3; //��� ���� �� 30.03.2016, �� ������ ��-������� ��-�� TMR0,  ��� ��������� ��������� �����
rtPause:=tmpPause;

end;

Function Get_ROM(val1, val2: integer): boolean; stdcall;
begin
  Get_ROM := ROM[val1, val2];
end;

Procedure Set_ROM(val1, val2: integer; val3: boolean); stdcall;
begin
  ROM[val1, val2] := val3;
end;

Function Get_SFRcount(): Word; stdcall;
begin
  Get_SFRcount := SFRCount;
end;

Procedure CurrentToParCommand(); stdcall;
begin
  parCommand[0] := CurrentCommand[0];
  parCommand[1] := CurrentCommand[1];
  parCommand[2] := CurrentCommand[2];
  parCommand[3] := CurrentCommand[3];
  parCommand[4] := CurrentCommand[4];
  parCommand[5] := CurrentCommand[5];
  parCommand[6] := CurrentCommand[6];
  parCommand[7] := CurrentCommand[7];
  parCommand[8] := CurrentCommand[8];
  parCommand[9] := CurrentCommand[9];
  parCommand[10] := CurrentCommand[10];
  parCommand[11] := CurrentCommand[11];
end;

Procedure RomToParCommand(tmp: integer); stdcall;
begin
  parCommand[0] := ROM[tmp, 0];
  parCommand[1] := ROM[tmp, 1];
  parCommand[2] := ROM[tmp, 2];
  parCommand[3] := ROM[tmp, 3];
  parCommand[4] := ROM[tmp, 4];
  parCommand[5] := ROM[tmp, 5];
  parCommand[6] := ROM[tmp, 6];
  parCommand[7] := ROM[tmp, 7];
  parCommand[8] := ROM[tmp, 8];
  parCommand[9] := ROM[tmp, 9];
  parCommand[10] := ROM[tmp, 10];
  parCommand[11] := ROM[tmp, 11];
end;

function Get_I(): integer; stdcall;
begin
  Get_I := I;
end;

function Get_ROM_Size(): integer; stdcall;
begin
  Get_ROM_Size := ROM_Size;
end;

function Get_GPRCount(): integer; stdcall;
begin
  Get_GPRCount := GPRCount;
end;

function Get_rtPause(): boolean; stdcall;
begin
  Get_rtPause := rtPause;
end;

procedure Set_rtPause(val: boolean); stdcall;
begin
  rtPause := val;
end;

procedure Set_RT_parametrs(WithSyncro, StepByStep, WithDelay: boolean;
  delayMS: integer; Syncro: real); stdcall;
begin
  rtWithSyncro := WithSyncro;
  rtStepByStep := StepByStep;
  rtWithDelay := WithDelay;
  rtDelayMS := delayMS;
  rtSyncro := Syncro;
  rtexStep := false;
end;

procedure Get_RT_parametrs(var WithSyncro, StepByStep, WithDelay: boolean;
  var delayMS: integer; var Syncro: real); stdcall;
begin

  WithSyncro := rtWithSyncro;
  StepByStep := rtStepByStep;
  WithDelay := rtWithDelay;
  delayMS := rtDelayMS;
  Syncro := rtSyncro;

end;

function Get_rtRefreshComplete(): boolean; stdcall;
begin
  Get_rtRefreshComplete := rtRefreshComplete;
end;

procedure Set_rtRefreshComplete(val: boolean); stdcall;
begin
  rtRefreshComplete := val;
end;

procedure Calculate_CuclPerCycMK_AndRun(ReturnCallback_stop: pointer;
  Devices: TDevices); stdcall;
var
  H, L: integer;

begin
  rtCyclPerCycMK := DimensionCPUCyclesPerSecond div (rtCrystalFreq div 4);
  rtSyncroTMP := 0;
  StopSimulation_METOD := ReturnCallback_stop;

  // �������� ������ ���������, ������� ����� �������� ����� ������ ����
  L := 0;
  SetLength(BackTactDevices, L);
  for H := Low(Devices) to High(Devices) do

    if Devices[H].AssignedBackTact then
    begin
      L := L + 1;
      SetLength(BackTactDevices, L);
      BackTactDevices[L - 1] := Devices[H];
    end;

  // �������� ������ PIC10F200
  CO := TRun.Create(true);

  Set_rtRunning(false);
  POR;

  Set_rtRunning(true);
  CO.FreeOnTerminate := false; // ������� 23.04.2014
  CO.Priority := tpNormal;
  CO.Start;

end;

Procedure DrawVoltage(Sender: TObject; X: integer; y: integer; value: Single;
  dap: integer = 0);
label l1, l2, l3, lv;
var
  dbp: integer; // ����� �� �������
  dotst: boolean; // ����� �� ��� �����
  dotn: integer; // ������� �������� ��� �����
  sv: Single;
begin
  dotst := false;
  dotn := 0;
  if value < 0 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, Bmp_minus);
    X := X + Bmp_minus.Width;
    value := abs(value);
  end;

  dbp := 0;
l1:
  if value >= 10 then
  begin
    value := value / 10;
    inc(dbp);
    goto l1;
  end;
l2:
  if value < 1 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_0);
    X := X + bmp_0.Width;
    sv := 0;
    goto l3;
  end;
  if value < 2 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_1);
    X := X + bmp_1.Width;
    sv := 1;
    goto l3;
  end;
  if value < 3 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_2);
    X := X + bmp_2.Width;
    sv := 2;
    goto l3;
  end;
  if value < 4 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_3);
    X := X + bmp_3.Width;
    sv := 3;
    goto l3;
  end;
  if value < 5 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_4);
    X := X + bmp_4.Width;
    sv := 4;
    goto l3;
  end;
  if value < 6 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_5);
    X := X + bmp_5.Width;
    sv := 5;
    goto l3;
  end;
  if value < 7 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_6);
    X := X + bmp_6.Width;
    sv := 6;
    goto l3;
  end;
  if value < 8 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_7);
    X := X + bmp_7.Width;
    sv := 7;
    goto l3;
  end;
  if value < 9 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_8);
    X := X + bmp_8.Width;
    sv := 8;
    goto l3;
  end;
  (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_9);
  X := X + bmp_9.Width;
  sv := 9;
  goto l3;

l3:
  if dotst then
    inc(dotn);
  if dotn >= dap then
    goto lv;

  if dbp = 0 then
  begin
    (Sender as TDevice).Image.Canvas.Draw(X, y, bmp_dot);
    X := X + bmp_dot.Width;
    dotst := true;
  end;

  dbp := dbp - 1;
  value := (value - sv) * 10;
  goto l2;

lv:
  (Sender as TDevice).Image.Canvas.Draw(X, y, Bmp_V);

end;

function Get_SystemCommand_CommandName(val: integer): shortstring; stdcall;
begin
  Get_SystemCommand_CommandName := SystemCommand[val].CommandName;
end;

function Get_parGOTOaddr(): integer; stdcall;
begin
  Get_parGOTOaddr := parGOTOaddr;
end;

function Get_config(val: integer): boolean; stdcall;
begin
  Get_config := Config[val];
end;

procedure set_config(val: integer; val1: boolean); stdcall;
begin
  Config[val] := val1;
  if val1 = true then
    TD.SaveData[val] := '1'
  else
    TD.SaveData[val] := '0';
end;

Function Get_MatrixRAM_ToClearDelta(val1: integer): boolean; stdcall;
begin
  Get_MatrixRAM_ToClearDelta := MatrixRAM[val1].ToClearDelta;
end;

Procedure Set_MatrixRAM_ToClearDelta(val1: integer; val2: boolean); stdcall;
begin
  MatrixRAM[val1].ToClearDelta := val2;
end;

Function Get_MatrixRAM_SIMadress(val1: integer): Word; stdcall;
begin
  Get_MatrixRAM_SIMadress := MatrixRAM[val1].SIMadress;
end;

Procedure Set_MatrixRAM_SIMadress(val1: integer; val2: Word); stdcall;
begin
  MatrixRAM[val1].SIMadress := val2;
end;

Function Get_MatrixRAM_BreakPoint(val1: integer): boolean; stdcall;
begin
  Get_MatrixRAM_BreakPoint := MatrixRAM[val1].BreakPoint;
end;

Procedure Set_MatrixRAM_BreakPoint(val1: integer; val2: boolean); stdcall;
begin
  MatrixRAM[val1].BreakPoint := val2;
end;

Function Get_MatrixRAM_GreenBP(val1: integer): boolean; stdcall;
begin
  Get_MatrixRAM_GreenBP := MatrixRAM[val1].GreenBP;
end;

Procedure Set_MatrixRAM_GreenBP(val1: integer; val2: boolean); stdcall;
begin
  MatrixRAM[val1].GreenBP := val2;
end;

Function Get_MatrixRAM_IDEHexaddres(val1: integer): shortstring; stdcall;
begin
  Get_MatrixRAM_IDEHexaddres := MatrixRAM[val1].IDEHexaddres;
end;

Function Get_MatrixRAM_IDEName(val1: integer): shortstring; stdcall;
begin
  Get_MatrixRAM_IDEName := MatrixRAM[val1].IDEName;
end;

Function Get_MatrixRAM_delta(val1: integer): boolean; stdcall;
begin
  Get_MatrixRAM_delta := MatrixRAM[val1].delta;
end;

Procedure Set_MatrixRAM_delta(val1: integer; val2: boolean); stdcall;
begin
  MatrixRAM[val1].delta := val2;
end;

Function Get_MatrixRAM_greenDelta(val1: integer): boolean; stdcall;
begin
  Get_MatrixRAM_greenDelta := MatrixRAM[val1].greenDelta;
end;

Procedure Set_MatrixRAM_greenDelta(val1: integer; val2: boolean); stdcall;
begin
  MatrixRAM[val1].greenDelta := val2;
end;

Function Get_MatrixRAM_deltabit(val1: integer; val2: byte): boolean; stdcall;
begin
  Get_MatrixRAM_deltabit := MatrixRAM[val1].deltabit[val2];
end;

Procedure Set_MatrixRAM_deltabit(val1: integer; val2: byte;
  val3: boolean); stdcall;
begin
  MatrixRAM[val1].deltabit[val2] := val3;
end;

Function Get_MatrixRAM_usedbit(val1: integer; val2: byte): boolean; stdcall;
begin
  Get_MatrixRAM_usedbit := MatrixRAM[val1].usedbit[val2];
end;

Procedure Set_MatrixRAM_usedbit(val1: integer; val2: byte;
  val3: boolean); stdcall;
begin
  MatrixRAM[val1].usedbit[val2] := val3;
end;

Function Get_MatrixRAM_bitname(val1: integer; val2: byte): shortstring; stdcall;
begin
  Get_MatrixRAM_bitname := MatrixRAM[val1].bitname[val2];
end;

Procedure Set_MatrixRAM_bitname(val1: integer; val2: byte;
  val3: shortstring); stdcall;
begin
  MatrixRAM[val1].bitname[val2] := val3;
end;

Function Get_StackCounter(): byte; stdcall;
begin
  Get_StackCounter := StC;
end;

function Get_IC(): int64; stdcall;
begin
  Get_IC := IC;
end;

Function Get_stack(val: byte): TResStack; stdcall;
var
  hz: integer;
  R: TResStack;
begin
  SetLength(R, cMCU_pcLen);
  for hz := 0 to cMCU_pcLen - 1 do
    R[hz] := bSt[val, hz];
  result := R;

  { val1 := bSt[val, 1];
    val2 := bSt[val, 2];
    val3 := bSt[val, 3];
    val4 := bSt[val, 4];
    val5 := bSt[val, 5];
    val6 := bSt[val, 6];
    val7 := bSt[val, 7]; }
end;

Function Get_PC(): TResStack; stdcall;
var
  hz: integer;
  R: TResStack;
begin
  SetLength(R, cMCU_pcLen);
  for hz := 0 to cMCU_pcLen - 1 do
    R[hz] := PC[hz];
  result := R;

  { val1 := bSt[val, 1];
    val2 := bSt[val, 2];
    val3 := bSt[val, 3];
    val4 := bSt[val, 4];
    val5 := bSt[val, 5];
    val6 := bSt[val, 6];
    val7 := bSt[val, 7]; }
end;

procedure Get_TaktsWDT(var valTaktsWDT, valrtTaktsWDT: real); stdcall;
begin
  valTaktsWDT := TaktsWDT;
  valrtTaktsWDT := rtTaktsWDT;
end;

function Get_StackMax(): byte; stdcall;
begin
  Get_StackMax := stMax;
end;

procedure Set_rtexStep(val: boolean); stdcall;
begin
  rtexStep := val;
end;

function Get_ROM_Str_No_from(val: integer): integer; stdcall;
begin
  Get_ROM_Str_No_from := ROM_Str_No_from[val];
end;

function Get_ROM_Str_No_to(val: integer): integer; stdcall;
begin
  Get_ROM_Str_No_to := ROM_Str_No_to[val];
end;

function Get_ROM_Str_No(val: integer): integer; stdcall;
begin
  Get_ROM_Str_No := ROM_Str_No[val];
end;

procedure Set_ROM_Str_No_from(val: integer; val2: integer); stdcall;
begin
  ROM_Str_No_from[val] := val2;
end;

procedure Set_ROM_Str_No_to(val: integer; val2: integer); stdcall;
begin
  ROM_Str_No_to[val] := val2;
end;

procedure Set_ROM_Str_No(val: integer; val2: integer); stdcall;
begin
  ROM_Str_No[val] := val2;
end;

procedure Set_ROM_BP(val: integer; val2: boolean); stdcall;
begin
  ROM_BP[val] := val2;
end;

function Get_PC_Len(): integer; stdcall;
begin
  Get_PC_Len := cMCU_pcLen;
end;

{ procedure Get_ConfigBits(val: Integer; var Name,  Value0,
  Value1: shortstring; var No: Integer); stdcall;
  begin
  Name := ConfigBits[val].Name;

  // Value0 := ConfigBits[val].Value0;
  // Value1 := ConfigBits[val].Value1;
  No := ConfigBits[val].No;

  end; }

procedure Destroy_CO(); stdcall;
begin
  // co.Destroy;
end;
// ��������� � �������, ��������� � �������������





// Call-Back ������

procedure BackProcDraw(Sender: TObject; isRunning: boolean;
  RunningTime: Extended); stdcall;
var
  s: integer;
  tmpSingle: Single;
label
  lbl510GP0, lbl510GP1, lbl510GP2;
begin
  // ������� Image
 // (Sender as TDevice).Image.Picture.CleanupInstance;
  if NOT isRunning then
  begin
    CASE rtMCId of
      0:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp200);
      1:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp202);
      2:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp204);
      3:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp206);
      4:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp220);
      5:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp222);
      6:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp508);
      7:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp509);
      8:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp510);
      9:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp519);
      10:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp505);
      11:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp506);
      12:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp526);
      13:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp54);
      14:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp57);
      15:
        (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp59);
  END;
  exit;
end;

// ��������� ����
CASE rtMCId of
  0:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp200_free);
  1:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp202_free);
  2:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp204_free);
  3:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp206_free);
  4:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp220_free);
  5:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp222_free);
  6:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp508_free);
  7:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp509_free);
  8:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp510_free);
  9:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp519_free);
  10:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp505_free);
  11:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp506_free);
  12:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp526_free);
  13:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp54_free);
  14:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp57_free);
  15:
    (Sender as TDevice).Image.Canvas.Draw(0, 0, Bmp59_free);
END;
// ��������� ��������

{ ��������!
  ������ ���� ��������� ���������� ��������� ������ � ������ � ����

  �������, ����� ���������� ����, ����� ������ � � ���������.
  � ��������!
}

if rtMCId <= 5 then // ���� ���� ������ ��� PIC10F200/202/204/206/220/222
{$REGION 'for PIC10F20X/22X'}
begin
  // ����� ������ ����� GP0 (������ � 10F200/202) � �������� �����, ��� CIN+ (������ 10F204/206)
  // ��� � ������ AN0 (10F220/222)
  if (cMCU_regADCON0 > -1) and (RAM[cMCU_regADCON0, 6] = true) then // ����� AN0
  begin
    (Sender as TDevice).Image.Canvas.Draw(63, 68, Bmp_AN0);
    (Sender as TDevice).Image.Canvas.Draw(86, 66, Bmp_In);
    tmpSingle := TD.Port[0].Node.GetLevel();
    if isNan(tmpSingle) then
      tmpSingle := 0;
    DrawVoltage(Sender, 92, 68, tmpSingle, 2);
  end
  else if (cMCU_regCMCON > -1) and (RAM[cMCU_regCMCON, 3] = true) then
  // ����� CIN+
  begin
    (Sender as TDevice).Image.Canvas.Draw(63, 68, Bmp_CINp);
    (Sender as TDevice).Image.Canvas.Draw(86, 66, Bmp_In);
    tmpSingle := TD.Port[0].Node.GetLevel();
    if isNan(tmpSingle) then
      tmpSingle := 0;
    DrawVoltage(Sender, 92, 68, tmpSingle, 2);
  end
  else // ����� - GP0
  begin
    (Sender as TDevice).Image.Canvas.Draw(64, 68, Bmp_GP0);
    if RAM[cMCU_regTRISGPIO, 0] then
    begin
      (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_In);
      tmpSingle := TD.Port[0].Node.GetLevel();
      if isNan(tmpSingle) then
        (Sender as TDevice).Image.Canvas.Draw(99, 66, bmp_r3)
      else if (tmpSingle >= MinHighLevelVoltage) and
        (tmpSingle <= MaxHighLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r1)
      else if (tmpSingle >= MinLowLevelVoltage) and
        (tmpSingle <= MaxLowLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r0)
      else
        (Sender as TDevice).Image.Canvas.Draw(99, 66, bmp_r3);
    end
    else
    begin
      (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_Out);
      if RAM[cMCU_regGPIO, 0] then
        (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r1)
      else
        (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r0);
    end;
  end;

  // ����� ������ ����� GP1 (������ � 10F200/202) � �������� �����, ��� CIN-(������ 10F204/206)
  // ��� � ������ AN1 (10F220/222)
  if (cMCU_regADCON0 > -1) and (RAM[cMCU_regADCON0, 7] = true) then // ����� AN1
  begin
    (Sender as TDevice).Image.Canvas.Draw(33, 68, Bmp_AN1);
    (Sender as TDevice).Image.Canvas.Draw(17, 66, Bmp_In2);
    tmpSingle := TD.Port[1].Node.GetLevel();
    if isNan(tmpSingle) then
      tmpSingle := 0;
    DrawVoltage(Sender, 0, 68, tmpSingle, 2);
  end
  else if (cMCU_regCMCON > -1) and (RAM[cMCU_regCMCON, 3] = true) then
  // ����� CIN-
  begin
    (Sender as TDevice).Image.Canvas.Draw(33, 68, Bmp_CINn);
    (Sender as TDevice).Image.Canvas.Draw(17, 66, Bmp_In2);
    tmpSingle := TD.Port[1].Node.GetLevel();
    if isNan(tmpSingle) then
      tmpSingle := 0;
    DrawVoltage(Sender, 0, 68, tmpSingle, 2);
  end
  else // ����� - GP1
  begin
    (Sender as TDevice).Image.Canvas.Draw(33, 68, Bmp_GP1);
    if RAM[cMCU_regTRISGPIO, 1] then
    begin
      (Sender as TDevice).Image.Canvas.Draw(14, 66, Bmp_In2);
      tmpSingle := TD.Port[1].Node.GetLevel();
      if isNan(tmpSingle) then
        (Sender as TDevice).Image.Canvas.Draw(5, 66, bmp_r3)
      else if (tmpSingle >= MinHighLevelVoltage) and
        (tmpSingle <= MaxHighLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r1)
      else if (tmpSingle >= MinLowLevelVoltage) and
        (tmpSingle <= MaxLowLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r0)
      else
        (Sender as TDevice).Image.Canvas.Draw(5, 66, bmp_r3);
    end
    else
    begin
      (Sender as TDevice).Image.Canvas.Draw(14, 66, Bmp_Out2);
      if RAM[cMCU_regGPIO, 1] then
        (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r1)
      else
        (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r0);
    end;
  end;

  // ����� ������ ����� GP2
  if (cMCU_regCMCON > -1) and ((RAM[cMCU_regCMCON, 3] = true) and
    (RAM[cMCU_regCMCON, 6] = false)) then // ����� COUT
  begin
    (Sender as TDevice).Image.Canvas.Draw(33, 50, Bmp_cout);
    (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_Out2);
    if RAM[cMCU_regCMCON, 7] then
      (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r0);
  end
  else
    // ��������� ����� ������ ����� GP2 (�� ����� �� COUT)
    if cMCU_avFosc4Out and RAM[cMCU_regOSCCAL, 0] then
      // ������ ������ � �������� OSCCAL,0 <FOSC4>
      (Sender as TDevice).Image.Canvas.Draw(33, 50, Bmp_Fosc4) // ����� OSC/4
    else if RAM[cMCU_regOPTION, 5] then
    begin
      (Sender as TDevice).Image.Canvas.Draw(33, 50, Bmp_T0CKI); // ���� TOCKI
      (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_In2);
      // ��� ������, ��� �� ����
      tmpSingle := TD.Port[2].Node.GetLevel(); // ������� �������
      if isNan(tmpSingle) then
        (Sender as TDevice).Image.Canvas.Draw(5, 48, bmp_r3)
      else if (tmpSingle >= MinHighLevelVoltage) and
        (tmpSingle <= MaxHighLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r1)
      else if (tmpSingle >= MinLowLevelVoltage) and
        (tmpSingle <= MaxLowLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r0)
      else
        (Sender as TDevice).Image.Canvas.Draw(5, 48, bmp_r3);
      // ����� ����������
      if RAM[cMCU_regOPTION, 4] then
        (Sender as TDevice).Image.Canvas.Draw(0, 48, bmp_HiToLo)
      else
        (Sender as TDevice).Image.Canvas.Draw(0, 48, bmp_LoToHi);
    end
    else
    begin
      (Sender as TDevice).Image.Canvas.Draw(33, 50, Bmp_GP2);
      if RAM[cMCU_regTRISGPIO, 2] then
      begin
        (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_In2);
        tmpSingle := TD.Port[2].Node.GetLevel();
        if isNan(tmpSingle) then
          (Sender as TDevice).Image.Canvas.Draw(5, 48, bmp_r3)
        else if (tmpSingle >= MinHighLevelVoltage) and
          (tmpSingle <= MaxHighLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r1)
        else if (tmpSingle >= MinLowLevelVoltage) and
          (tmpSingle <= MaxLowLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r0)
        else
          (Sender as TDevice).Image.Canvas.Draw(5, 48, bmp_r3);
      end
      else
      begin
        (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_Out2);
        if RAM[cMCU_regGPIO, 2] then
          (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r1)
        else
          (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r0);
      end;
    end;

  // ��������� ����� ����� GP3 (�� �������� ������ �� ����)
  if Config[4] = true then
    // �� ������ ���������������� � ���� ������������ (������ ��� pic10f200-222)
    (Sender as TDevice).Image.Canvas.Draw(60, 12, Bmp_MCLR) // ����� - /MCLR
  else
    (Sender as TDevice).Image.Canvas.Draw(64, 14, Bmp_GP3); // ����� - GP3
  // �.�. ���� �������� ������ ���� �� ����
  tmpSingle := TD.Port[3].Node.GetLevel();
  if isNan(tmpSingle) then
    (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3)
  else if (tmpSingle >= MinHighLevelVoltage) and
    (tmpSingle <= MaxHighLevelVoltage) then
    (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r1)
  else if (tmpSingle >= MinLowLevelVoltage) and (tmpSingle <= MaxLowLevelVoltage)
  then
    (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r0)
  else
    (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3);
  exit;
end;
{$ENDREGION}
if rtMCId <= 9 then // ���� ���� ������ ��� PIC12F508/509/510/519
{$REGION 'for PIC12F5XX'}
begin

  // GP0
  // ��������, �� ���������� � ��� �� ����� (� ������ ������� �� 4-� �� �� ������ � 510-�)
  if rtMCId = 8 then
  begin
    if RAM[cMCU_regCMCON, 3] then
      if RAM[cMCU_regADCON0, 7] then
      begin // � ���������� �������, � � ��� ��������� �����
        (Sender as TDevice).Image.Canvas.Draw(58, 28, bmp_AN0C1INp);
        (Sender as TDevice).Image.Canvas.Draw(86, 30, Bmp_In);
        tmpSingle := TD.Port[0].Node.GetLevel();
        if isNan(tmpSingle) then
          tmpSingle := 0;
        DrawVoltage(Sender, 92, 32, tmpSingle, 2);
      end
      else
      begin // ������ ���������� �������, � � ��� ����� �� ���������
        (Sender as TDevice).Image.Canvas.Draw(63, 32, Bmp_CINp);
        (Sender as TDevice).Image.Canvas.Draw(86, 30, Bmp_In);
        tmpSingle := TD.Port[0].Node.GetLevel();
        if isNan(tmpSingle) then
          tmpSingle := 0;
        DrawVoltage(Sender, 92, 32, tmpSingle, 2);

      end
    else if RAM[cMCU_regADCON0, 7] then
    begin // ������ � ��� ��������� �����
      (Sender as TDevice).Image.Canvas.Draw(63, 32, Bmp_AN0);
      (Sender as TDevice).Image.Canvas.Draw(86, 30, Bmp_In);
      tmpSingle := TD.Port[0].Node.GetLevel();
      if isNan(tmpSingle) then
        tmpSingle := 0;
      DrawVoltage(Sender, 92, 32, tmpSingle, 2);
    end
    else
      goto lbl510GP0;

  end
  else
  lbl510GP0:
    // ����� - GP0
    begin //
      (Sender as TDevice).Image.Canvas.Draw(64, 32, Bmp_GP0);
      if RAM[cMCU_regTRISGPIO, 0] then
      begin
        (Sender as TDevice).Image.Canvas.Draw(89, 30, Bmp_In);
        tmpSingle := TD.Port[0].Node.GetLevel();
        if isNan(tmpSingle) then
          (Sender as TDevice).Image.Canvas.Draw(99, 30, bmp_r3)
        else if (tmpSingle >= MinHighLevelVoltage) and
          (tmpSingle <= MaxHighLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(99, 30, Bmp_r1)
        else if (tmpSingle >= MinLowLevelVoltage) and
          (tmpSingle <= MaxLowLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(99, 30, Bmp_r0)
        else
          (Sender as TDevice).Image.Canvas.Draw(99, 30, bmp_r3);
      end
      else
      begin
        (Sender as TDevice).Image.Canvas.Draw(89, 30, Bmp_Out);
        if RAM[cMCU_regGPIO, 0] then
          (Sender as TDevice).Image.Canvas.Draw(99, 30, Bmp_r1)
        else
          (Sender as TDevice).Image.Canvas.Draw(99, 30, Bmp_r0);
      end;
    end; // ����� ������ begina

  // GP1
  // ��������, �� ���������� � ��� �� ����� (� ������ ������� �� 4-� �� �� ������ � 510-�)
  if rtMCId = 8 then
  begin
    if RAM[cMCU_regCMCON, 3] then
      if RAM[cMCU_regADCON0, 7] and RAM[cMCU_regADCON0, 6] then
      begin // � ���������� �������, � � ��� ����� ���������
        (Sender as TDevice).Image.Canvas.Draw(60, 45, bmp_AN1C1INn);
        (Sender as TDevice).Image.Canvas.Draw(86, 48, Bmp_In);
        tmpSingle := TD.Port[1].Node.GetLevel();
        if isNan(tmpSingle) then
          tmpSingle := 0;
        DrawVoltage(Sender, 92, 50, tmpSingle, 2);
      end
      else
      begin // ������ ���������� �������
        (Sender as TDevice).Image.Canvas.Draw(63, 50, Bmp_CINn);
        (Sender as TDevice).Image.Canvas.Draw(86, 48, Bmp_In);
        tmpSingle := TD.Port[1].Node.GetLevel();
        if isNan(tmpSingle) then
          tmpSingle := 0;
        DrawVoltage(Sender, 92, 50, tmpSingle, 2);

      end
    else if RAM[cMCU_regADCON0, 7] and RAM[cMCU_regADCON0, 6] then
    begin // ������ � ��� ��������� �����
      (Sender as TDevice).Image.Canvas.Draw(63, 50, Bmp_AN1);
      (Sender as TDevice).Image.Canvas.Draw(86, 48, Bmp_In);
      tmpSingle := TD.Port[1].Node.GetLevel();
      if isNan(tmpSingle) then
        tmpSingle := 0;
      DrawVoltage(Sender, 92, 50, tmpSingle, 2);
    end
    else
      goto lbl510GP1;

  end
  else
  lbl510GP1:
    // ����� - GP1
    begin //
      (Sender as TDevice).Image.Canvas.Draw(64, 50, Bmp_GP1);
      if RAM[cMCU_regTRISGPIO, 1] then
      begin
        (Sender as TDevice).Image.Canvas.Draw(89, 48, Bmp_In);
        tmpSingle := TD.Port[1].Node.GetLevel();
        if isNan(tmpSingle) then
          (Sender as TDevice).Image.Canvas.Draw(99, 48, bmp_r3)
        else if (tmpSingle >= MinHighLevelVoltage) and
          (tmpSingle <= MaxHighLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(99, 48, Bmp_r1)
        else if (tmpSingle >= MinLowLevelVoltage) and
          (tmpSingle <= MaxLowLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(99, 48, Bmp_r0)
        else
          (Sender as TDevice).Image.Canvas.Draw(99, 48, bmp_r3);
      end
      else
      begin
        (Sender as TDevice).Image.Canvas.Draw(89, 48, Bmp_Out);
        if RAM[cMCU_regGPIO, 1] then
          (Sender as TDevice).Image.Canvas.Draw(99, 48, Bmp_r1)
        else
          (Sender as TDevice).Image.Canvas.Draw(99, 48, Bmp_r0);
      end;
    end; // ����� ������ begina

  // GP2
  // ��������, �� ���������� � ��� �� ����� (� ������ ������� �� 4-� �� �� ������ � 510-�)
  if rtMCId = 8 then
  begin

    if RAM[cMCU_regADCON0, 7] or RAM[cMCU_regADCON0, 6] then
    // ��������, ����� OR, ��� ������ ����
    begin // � ��� ����� ���������, ���������� ���������
      (Sender as TDevice).Image.Canvas.Draw(62, 68, bmp_AN2);
      (Sender as TDevice).Image.Canvas.Draw(86, 66, Bmp_In);
      tmpSingle := TD.Port[1].Node.GetLevel();
      if isNan(tmpSingle) then
        tmpSingle := 0;
      DrawVoltage(Sender, 92, 68, tmpSingle, 2);
    end
    else
    begin
      if (RAM[cMCU_regCMCON, 3]) and (RAM[cMCU_regCMCON, 6] = false) then
      begin // ����� ����������� ��������� � ������ C1OUT (��������)
        (Sender as TDevice).Image.Canvas.Draw(55, 68, bmp_C1OUT);
        (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_Out);
        if RAM[cMCU_regCMCON, 7] then
          (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r1)
        else
          (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r0);
      end
      else
        goto lbl510GP2;
    end;
  end
  else

  lbl510GP2:

    // ����� - GP2/T0CKI
    begin
      if RAM[cMCU_regOPTION, 5] then // ��������, �� ��������� ���� T0CS
      begin
        (Sender as TDevice).Image.Canvas.Draw(59, 68, Bmp_T0CKI);
        // ���� TOCKI
        (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_In);
        // ��� ������, ��� �� ����
        tmpSingle := TD.Port[2].Node.GetLevel(); // ������� �������
        if isNan(tmpSingle) then
          (Sender as TDevice).Image.Canvas.Draw(99, 66, bmp_r3)
        else if (tmpSingle >= MinHighLevelVoltage) and
          (tmpSingle <= MaxHighLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r1)
        else if (tmpSingle >= MinLowLevelVoltage) and
          (tmpSingle <= MaxLowLevelVoltage) then
          (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r0)
        else
          (Sender as TDevice).Image.Canvas.Draw(99, 66, bmp_r3);
        // ����� ����������
        if RAM[cMCU_regOPTION, 4] then // ��������, �� ��������� ���� T0SE
          (Sender as TDevice).Image.Canvas.Draw(105, 66, bmp_HiToLo)
        else
          (Sender as TDevice).Image.Canvas.Draw(105, 66, bmp_LoToHi);
      end
      else
      begin
        (Sender as TDevice).Image.Canvas.Draw(64, 68, Bmp_GP2);
        if RAM[cMCU_regTRISGPIO, 2] then
        begin
          (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_In);
          tmpSingle := TD.Port[2].Node.GetLevel();
          if isNan(tmpSingle) then
            (Sender as TDevice).Image.Canvas.Draw(99, 66, bmp_r3)
          else if (tmpSingle >= MinHighLevelVoltage) and
            (tmpSingle <= MaxHighLevelVoltage) then
            (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r1)
          else if (tmpSingle >= MinLowLevelVoltage) and
            (tmpSingle <= MaxLowLevelVoltage) then
            (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r0)
          else
            (Sender as TDevice).Image.Canvas.Draw(99, 66, bmp_r3);
        end
        else
        begin
          (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_Out);
          if RAM[cMCU_regGPIO, 2] then
            (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r1)
          else
            (Sender as TDevice).Image.Canvas.Draw(99, 66, Bmp_r0);
        end;
      end;
    end;

  // GP3/\MCLR
  // ��������� ����� ����� GP3 (�� �������� ������ �� ����)
  if Config[4] = true then
    // �� ������ ���������������� � ���� ������������
    (Sender as TDevice).Image.Canvas.Draw(33, 66, Bmp_MCLR) // ����� - /MCLR
  else
    (Sender as TDevice).Image.Canvas.Draw(33, 68, Bmp_GP3); // ����� - GP3
  // �.�. ���� �������� ������ ���� �� ����
  tmpSingle := TD.Port[3].Node.GetLevel();
  if isNan(tmpSingle) then
    (Sender as TDevice).Image.Canvas.Draw(5, 66, bmp_r3)
  else if (tmpSingle >= MinHighLevelVoltage) and
    (tmpSingle <= MaxHighLevelVoltage) then
    (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r1)
  else if (tmpSingle >= MinLowLevelVoltage) and (tmpSingle <= MaxLowLevelVoltage)
  then
    (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r0)
  else
    (Sender as TDevice).Image.Canvas.Draw(5, 66, bmp_r3);

  // GP4/OSC2
  // ��������� ����� ������ ����� GP4
  if (Config[0] = false) and (Config[1] = true) then
  // �� ������ ���������������� � ���� ������������
  begin // GP4
    (Sender as TDevice).Image.Canvas.Draw(33, 50, Bmp_GP4);
    if RAM[cMCU_regTRISGPIO, 4] then
    begin
      (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_In2);
      tmpSingle := TD.Port[4].Node.GetLevel();
      if isNan(tmpSingle) then
        (Sender as TDevice).Image.Canvas.Draw(5, 48, bmp_r3)
      else if (tmpSingle >= MinHighLevelVoltage) and
        (tmpSingle <= MaxHighLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r1)
      else if (tmpSingle >= MinLowLevelVoltage) and
        (tmpSingle <= MaxLowLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r0)
      else
        (Sender as TDevice).Image.Canvas.Draw(5, 48, bmp_r3);
    end
    else
    begin
      (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_Out2);
      if RAM[cMCU_regGPIO, 4] then
        (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r1)
      else
        (Sender as TDevice).Image.Canvas.Draw(5, 48, Bmp_r0);
    end
  end
  else
  begin // OSC2
    (Sender as TDevice).Image.Canvas.Draw(33, 50, Bmp_OSC2);
  end;

  // GP5/OSC1
  // ��������� ����� ������ ����� GP5
  if (Config[0] = false) and (Config[1] = true) then
  // �� ������ ���������������� � ���� ������������
  begin // GP5
    (Sender as TDevice).Image.Canvas.Draw(33, 32, Bmp_GP5);
    if RAM[cMCU_regTRISGPIO, 5] then
    begin
      (Sender as TDevice).Image.Canvas.Draw(14, 30, Bmp_In2);
      tmpSingle := TD.Port[5].Node.GetLevel();
      if isNan(tmpSingle) then
        (Sender as TDevice).Image.Canvas.Draw(5, 30, bmp_r3)
      else if (tmpSingle >= MinHighLevelVoltage) and
        (tmpSingle <= MaxHighLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 30, Bmp_r1)
      else if (tmpSingle >= MinLowLevelVoltage) and
        (tmpSingle <= MaxLowLevelVoltage) then
        (Sender as TDevice).Image.Canvas.Draw(5, 30, Bmp_r0)
      else
        (Sender as TDevice).Image.Canvas.Draw(5, 30, bmp_r3);
    end
    else
    begin
      (Sender as TDevice).Image.Canvas.Draw(14, 30, Bmp_Out2);
      if RAM[cMCU_regGPIO, 5] then
        (Sender as TDevice).Image.Canvas.Draw(5, 30, Bmp_r1)
      else
        (Sender as TDevice).Image.Canvas.Draw(5, 30, Bmp_r0);
    end
  end
  else
  begin // OSC1
    (Sender as TDevice).Image.Canvas.Draw(33, 32, Bmp_OSC1);
  end;

  exit;

end;
{$ENDREGION}
if (rtMCId = 13) then // ���� ���� ������ ��� PIC16F54
{$REGION 'for PIC16F54'}
begin
  // PORTA,0
  if RAM[cMCU_regTRISA, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 30, Bmp_In);
    tmpSingle := TD.Port[0].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 29, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 29, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 30, Bmp_Out);
    if RAM[cMCU_regPORTA, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r0);
  end;
  // PORTA,1
  if RAM[cMCU_regTRISA, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 12, Bmp_In);
    tmpSingle := TD.Port[1].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 12, Bmp_Out);
    if RAM[cMCU_regPORTA, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r0);
  end;
  // PORTA,2
  if RAM[cMCU_regTRISA, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 12, Bmp_In2);
    tmpSingle := TD.Port[2].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 11, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 12, Bmp_Out2);
    if RAM[cMCU_regPORTA, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r0);
  end;
  // PORTA,3
  if RAM[cMCU_regTRISA, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 30, Bmp_In2);
    tmpSingle := TD.Port[3].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 29, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 29, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 30, Bmp_Out2);
    if RAM[cMCU_regPORTA, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r0);
  end;
  // PORTB,0
  if RAM[cMCU_regTRISB, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 102, Bmp_In2);
    tmpSingle := TD.Port[4].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 101, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 102, Bmp_Out2);
    if RAM[cMCU_regPORTB, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r0);
  end;
  // PORTB,1
  if RAM[cMCU_regTRISB, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 120, Bmp_In2);
    tmpSingle := TD.Port[5].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 119, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 120, Bmp_Out2);
    if RAM[cMCU_regPORTB, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r0);
  end;
  // PORTB,2
  if RAM[cMCU_regTRISB, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 138, Bmp_In2);
    tmpSingle := TD.Port[6].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 137, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 138, Bmp_Out2);
    if RAM[cMCU_regPORTB, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r0);
  end;
  // PORTB,3
  if RAM[cMCU_regTRISB, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 156, Bmp_In2);
    tmpSingle := TD.Port[7].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 155, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 156, Bmp_Out2);
    if RAM[cMCU_regPORTB, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r0);
  end;
  // PORTB,4
  if RAM[cMCU_regTRISB, 4] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 156, Bmp_In);
    tmpSingle := TD.Port[8].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 155, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 156, Bmp_Out);
    if RAM[cMCU_regPORTB, 4] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r0);
  end;
  // PORTB,5
  if RAM[cMCU_regTRISB, 5] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 138, Bmp_In);
    tmpSingle := TD.Port[9].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 137, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 137, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 138, Bmp_Out);
    if RAM[cMCU_regPORTB, 5] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r0);
  end;
  // PORTB,6
  if RAM[cMCU_regTRISB, 6] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 120, Bmp_In);
    tmpSingle := TD.Port[10].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 119, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 119, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 120, Bmp_Out);
    if RAM[cMCU_regPORTB, 6] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r0);
  end;
  // PORTB,7
  if RAM[cMCU_regTRISB, 7] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 102, Bmp_In);
    tmpSingle := TD.Port[11].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 101, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 101, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 102, Bmp_Out);
    if RAM[cMCU_regPORTB, 7] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r0);
  end;
  // T0CKI
  if RAM[cMCU_regOPTION, 5] then // ��������, �� ��������� ���� T0CS
  begin
    (Sender as TDevice).Image.Canvas.Draw(33, 50, Bmp_T0CKI);
    // ���� TOCKI
    (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_In2);
    // ��� ������, ��� �� ����
    tmpSingle := TD.Port[12].Node.GetLevel(); // ������� �������
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 47, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 47, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 47, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 47, bmp_r3);
    // ����� ����������
    if RAM[cMCU_regOPTION, 4] then // ��������, �� ��������� ���� T0SE
      (Sender as TDevice).Image.Canvas.Draw(0, 47, bmp_HiToLo)
    else
      (Sender as TDevice).Image.Canvas.Draw(0, 47, bmp_LoToHi);
  end;
  // \MCLR
  // �.�. ���� �������� ������ ���� �� ����
  tmpSingle := TD.Port[13].Node.GetLevel();
  if isNan(tmpSingle) then
    (Sender as TDevice).Image.Canvas.Draw(5, 66, bmp_r3)
  else if (tmpSingle >= MinHighLevelVoltage) and
    (tmpSingle <= MaxHighLevelVoltage) then
    (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r1)
  else if (tmpSingle >= MinLowLevelVoltage) and (tmpSingle <= MaxLowLevelVoltage)
  then
    (Sender as TDevice).Image.Canvas.Draw(5, 66, Bmp_r0)
  else
    (Sender as TDevice).Image.Canvas.Draw(5, 66, bmp_r3);
  exit;
end;
{$ENDREGION}
if (rtMCId = 14) then // ���� ���� ������ ��� PIC16F57
{$REGION 'for PIC16F57'}
begin
  // PORTA,0
  if RAM[cMCU_regTRISA, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 102, Bmp_In2);
    tmpSingle := TD.Port[0].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 101, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 102, Bmp_Out2);
    if RAM[cMCU_regPORTA, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r0);
  end;
  // PORTA,1
  if RAM[cMCU_regTRISA, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 120, Bmp_In2);
    tmpSingle := TD.Port[1].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 119, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 120, Bmp_Out2);
    if RAM[cMCU_regPORTA, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r0);
  end;
  // PORTA,2
  if RAM[cMCU_regTRISA, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 138, Bmp_In2);
    tmpSingle := TD.Port[2].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 137, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 138, Bmp_Out2);
    if RAM[cMCU_regPORTA, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r0);
  end;
  // PORTA,3
  if RAM[cMCU_regTRISA, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 156, Bmp_In2);
    tmpSingle := TD.Port[3].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 155, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 156, Bmp_Out2);
    if RAM[cMCU_regPORTA, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r0);
  end;
  // PORTB,0
  if RAM[cMCU_regTRISB, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 174, Bmp_In2);
    tmpSingle := TD.Port[4].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 173, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 173, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 174, Bmp_Out2);
    if RAM[cMCU_regPORTB, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r0);
  end;
  // PORTB,1
  if RAM[cMCU_regTRISB, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 192, Bmp_In2);
    tmpSingle := TD.Port[5].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 191, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 191, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 192, Bmp_Out2);
    if RAM[cMCU_regPORTB, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r0);
  end;
  // PORTB,2
  if RAM[cMCU_regTRISB, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 210, Bmp_In2);
    tmpSingle := TD.Port[6].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 209, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 209, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 210, Bmp_Out2);
    if RAM[cMCU_regPORTB, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r0);
  end;
  // PORTB,3
  if RAM[cMCU_regTRISB, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 228, Bmp_In2);
    tmpSingle := TD.Port[7].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 227, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 227, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 228, Bmp_Out2);
    if RAM[cMCU_regPORTB, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r0);
  end;
  // PORTB,4
  if RAM[cMCU_regTRISB, 4] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 246, Bmp_In2);
    tmpSingle := TD.Port[8].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 245, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 245, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 245, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 245, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 246, Bmp_Out2);
    if RAM[cMCU_regPORTB, 4] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 245, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 245, Bmp_r0);
  end;
  // PORTB,5
  if RAM[cMCU_regTRISB, 5] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 246, Bmp_In);
    tmpSingle := TD.Port[9].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 245, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 245, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 246, Bmp_Out);
    if RAM[cMCU_regPORTB, 5] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r0);
  end;
  // PORTB,6
  if RAM[cMCU_regTRISB, 6] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 228, Bmp_In);
    tmpSingle := TD.Port[10].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 227, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 227, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 228, Bmp_Out);
    if RAM[cMCU_regPORTB, 6] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r0);
  end;
  // PORTB,7
  if RAM[cMCU_regTRISB, 7] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 210, Bmp_In);
    tmpSingle := TD.Port[11].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 209, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 209, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 210, Bmp_Out);
    if RAM[cMCU_regPORTB, 7] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r0);
  end;
  // PORTC,0
  if RAM[cMCU_regTRISC, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 192, Bmp_In);
    tmpSingle := TD.Port[12].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 191, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 191, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 192, Bmp_Out);
    if RAM[cMCU_regPORTC, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r0);
  end;
  // PORTC,1
  if RAM[cMCU_regTRISC, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 174, Bmp_In);
    tmpSingle := TD.Port[13].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 173, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 173, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 174, Bmp_Out);
    if RAM[cMCU_regPORTC, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r0);
  end;
  // PORTC,2
  if RAM[cMCU_regTRISC, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 156, Bmp_In);
    tmpSingle := TD.Port[14].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 155, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 156, Bmp_Out);
    if RAM[cMCU_regPORTC, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r0);
  end;
  // PORTC,3
  if RAM[cMCU_regTRISC, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 138, Bmp_In);
    tmpSingle := TD.Port[15].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 137, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 137, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 138, Bmp_Out);
    if RAM[cMCU_regPORTC, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 137, Bmp_r0);
  end;
  // PORTC,4
  if RAM[cMCU_regTRISC, 4] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 120, Bmp_In);
    tmpSingle := TD.Port[16].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 119, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 119, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 120, Bmp_Out);
    if RAM[cMCU_regPORTC, 4] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 119, Bmp_r0);
  end;
  // PORTC,5
  if RAM[cMCU_regTRISC, 5] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 102, Bmp_In);
    tmpSingle := TD.Port[17].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 101, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 101, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 102, Bmp_Out);
    if RAM[cMCU_regPORTC, 5] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 101, Bmp_r0);
  end;
  // PORTC,6
  if RAM[cMCU_regTRISC, 6] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 84, Bmp_In);
    tmpSingle := TD.Port[18].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 83, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 83, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 84, Bmp_Out);
    if RAM[cMCU_regPORTC, 6] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r0);
  end;
  // PORTC,7
  if RAM[cMCU_regTRISC, 7] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_In);
    tmpSingle := TD.Port[19].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 65, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 65, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_Out);
    if RAM[cMCU_regPORTC, 7] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r0);
  end;
  // T0CKI
  if RAM[cMCU_regOPTION, 5] then // ��������, �� ��������� ���� T0CS
  begin
    (Sender as TDevice).Image.Canvas.Draw(33, 14, Bmp_T0CKI);
    // ���� TOCKI
    (Sender as TDevice).Image.Canvas.Draw(14, 11, Bmp_In2);
    // ��� ������, ��� �� ����
    tmpSingle := TD.Port[20].Node.GetLevel(); // ������� �������
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 11, bmp_r3);
    // ����� ����������
    if RAM[cMCU_regOPTION, 4] then // ��������, �� ��������� ���� T0SE
      (Sender as TDevice).Image.Canvas.Draw(0, 11, bmp_HiToLo)
    else
      (Sender as TDevice).Image.Canvas.Draw(0, 11, bmp_LoToHi);
  end;
  // \MCLR
  // �.�. ���� �������� ������ ���� �� ����
  tmpSingle := TD.Port[21].Node.GetLevel();
  if isNan(tmpSingle) then
    (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3)
  else if (tmpSingle >= MinHighLevelVoltage) and
    (tmpSingle <= MaxHighLevelVoltage) then
    (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r1)
  else if (tmpSingle >= MinLowLevelVoltage) and (tmpSingle <= MaxLowLevelVoltage)
  then
    (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r0)
  else
    (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3);
  exit;
end;
{$ENDREGION}
if (rtMCId = 15) then // ���� ���� ������ ��� PIC16F59
{$REGION 'for PIC16F59'}
begin
  // PORTA,0
  if RAM[cMCU_regTRISA, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 12, Bmp_In2);
    tmpSingle := TD.Port[0].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 11, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 12, Bmp_Out2);
    if RAM[cMCU_regPORTA, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 11, Bmp_r0);
  end;
  // PORTA,1
  if RAM[cMCU_regTRISA, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 30, Bmp_In2);
    tmpSingle := TD.Port[1].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 29, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 29, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 30, Bmp_Out2);
    if RAM[cMCU_regPORTA, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 29, Bmp_r0);
  end;
  // PORTA,2
  if RAM[cMCU_regTRISA, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_In2);
    tmpSingle := TD.Port[2].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 47, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 47, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 47, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 47, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 48, Bmp_Out2);
    if RAM[cMCU_regPORTA, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 47, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 47, Bmp_r0);
  end;
  // PORTA,3
  if RAM[cMCU_regTRISA, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 66, Bmp_In2);
    tmpSingle := TD.Port[3].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 65, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 65, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 65, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 65, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 66, Bmp_Out2);
    if RAM[cMCU_regPORTA, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 65, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 65, Bmp_r0);
  end;
  // PORTB,0
  if RAM[cMCU_regTRISB, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 102, Bmp_In2);
    tmpSingle := TD.Port[4].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 101, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 102, Bmp_Out2);
    if RAM[cMCU_regPORTB, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 101, Bmp_r0);
  end;
  // PORTB,1
  if RAM[cMCU_regTRISB, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 120, Bmp_In2);
    tmpSingle := TD.Port[5].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 119, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 120, Bmp_Out2);
    if RAM[cMCU_regPORTB, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 119, Bmp_r0);
  end;
  // PORTB,2
  if RAM[cMCU_regTRISB, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 138, Bmp_In2);
    tmpSingle := TD.Port[6].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 137, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 138, Bmp_Out2);
    if RAM[cMCU_regPORTB, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 137, Bmp_r0);
  end;
  // PORTB,3
  if RAM[cMCU_regTRISB, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 156, Bmp_In2);
    tmpSingle := TD.Port[7].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 155, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 156, Bmp_Out2);
    if RAM[cMCU_regPORTB, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 155, Bmp_r0);
  end;
  // PORTB,4
  if RAM[cMCU_regTRISB, 4] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 174, Bmp_In2);
    tmpSingle := TD.Port[8].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 173, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 173, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 174, Bmp_Out2);
    if RAM[cMCU_regPORTB, 4] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 173, Bmp_r0);
  end;
  // PORTB,5
  if RAM[cMCU_regTRISB, 5] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 192, Bmp_In2);
    tmpSingle := TD.Port[9].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 191, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 191, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 192, Bmp_Out2);
    if RAM[cMCU_regPORTB, 5] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 191, Bmp_r0);
  end;
  // PORTB,6
  if RAM[cMCU_regTRISB, 6] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 210, Bmp_In2);
    tmpSingle := TD.Port[10].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 209, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 209, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 210, Bmp_Out2);
    if RAM[cMCU_regPORTB, 6] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 209, Bmp_r0);
  end;
  // PORTB,7
  if RAM[cMCU_regTRISB, 7] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 228, Bmp_In2);
    tmpSingle := TD.Port[11].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 227, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 227, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 228, Bmp_Out2);
    if RAM[cMCU_regPORTB, 7] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 227, Bmp_r0);
  end;
  // PORTC,0
  if RAM[cMCU_regTRISC, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 282, Bmp_In2);
    tmpSingle := TD.Port[12].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 281, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 281, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 281, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 281, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 282, Bmp_Out2);
    if RAM[cMCU_regPORTC, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 281, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 281, Bmp_r0);
  end;
  // PORTC,1
  if RAM[cMCU_regTRISC, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 300, Bmp_In2);
    tmpSingle := TD.Port[13].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 299, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 299, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 299, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 299, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 300, Bmp_Out2);
    if RAM[cMCU_regPORTC, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 299, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 299, Bmp_r0);
  end;
  // PORTC,2
  if RAM[cMCU_regTRISC, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 318, Bmp_In2);
    tmpSingle := TD.Port[14].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 317, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 317, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 317, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 317, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 318, Bmp_Out2);
    if RAM[cMCU_regPORTC, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 317, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 317, Bmp_r0);
  end;
  // PORTC,3
  if RAM[cMCU_regTRISC, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 336, Bmp_In2);
    tmpSingle := TD.Port[15].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 335, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 335, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 335, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 335, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 336, Bmp_Out2);
    if RAM[cMCU_regPORTC, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 335, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 335, Bmp_r0);
  end;
  // PORTC,4
  if RAM[cMCU_regTRISC, 4] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 354, Bmp_In2);
    tmpSingle := TD.Port[16].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(5, 353, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 353, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(5, 353, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 353, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(14, 354, Bmp_Out2);
    if RAM[cMCU_regPORTC, 4] then // Change
      (Sender as TDevice).Image.Canvas.Draw(5, 353, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(5, 353, Bmp_r0);
  end;
  // PORTC,5
  if RAM[cMCU_regTRISC, 5] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 354, Bmp_In);
    tmpSingle := TD.Port[17].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 353, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 353, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 353, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 353, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 354, Bmp_Out);
    if RAM[cMCU_regPORTC, 5] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 353, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 353, Bmp_r0);
  end;
  // PORTC,6
  if RAM[cMCU_regTRISC, 6] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 336, Bmp_In);
    tmpSingle := TD.Port[18].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 335, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 335, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 335, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 335, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 336, Bmp_Out);
    if RAM[cMCU_regPORTC, 6] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 335, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 335, Bmp_r0);
  end;
  // PORTC,7
  if RAM[cMCU_regTRISC, 7] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 318, Bmp_In);
    tmpSingle := TD.Port[19].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 317, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 317, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 317, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 317, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 318, Bmp_Out);
    if RAM[cMCU_regPORTC, 7] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 317, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 317, Bmp_r0);
  end;
  // PORTD,0
  if RAM[cMCU_regTRISD, 0] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 300, Bmp_In);
    tmpSingle := TD.Port[20].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 299, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 299, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 299, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 299, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 300, Bmp_Out);
    if RAM[cMCU_regPORTD, 0] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 299, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 299, Bmp_r0);
  end;
  // PORTD,1
  if RAM[cMCU_regTRISD, 1] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 264, Bmp_In);
    tmpSingle := TD.Port[21].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 263, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 263, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 263, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 263, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 264, Bmp_Out);
    if RAM[cMCU_regPORTD, 1] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 263, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 263, Bmp_r0);
  end;
  // PORTD,2
  if RAM[cMCU_regTRISD, 2] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 246, Bmp_In);
    tmpSingle := TD.Port[22].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 245, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 245, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 246, Bmp_Out);
    if RAM[cMCU_regPORTD, 2] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 245, Bmp_r0);
  end;
  // PORTD,3
  if RAM[cMCU_regTRISD, 3] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 228, Bmp_In);
    tmpSingle := TD.Port[23].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 227, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 227, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 228, Bmp_Out);
    if RAM[cMCU_regPORTD, 3] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 227, Bmp_r0);
  end;
  // PORTD,4
  if RAM[cMCU_regTRISD, 4] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 210, Bmp_In);
    tmpSingle := TD.Port[24].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 209, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 209, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 210, Bmp_Out);
    if RAM[cMCU_regPORTD, 4] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 209, Bmp_r0);
  end;
  // PORTD,5
  if RAM[cMCU_regTRISD, 5] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 192, Bmp_In);
    tmpSingle := TD.Port[25].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 191, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 191, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 192, Bmp_Out);
    if RAM[cMCU_regPORTD, 5] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 191, Bmp_r0);
  end;
  // PORTD,6
  if RAM[cMCU_regTRISD, 6] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 174, Bmp_In);
    tmpSingle := TD.Port[26].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 173, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 173, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 174, Bmp_Out);
    if RAM[cMCU_regPORTD, 6] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 173, Bmp_r0);
  end;
  // PORTD,7
  if RAM[cMCU_regTRISD, 7] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 156, Bmp_In);
    tmpSingle := TD.Port[27].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 155, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 156, Bmp_Out);
    if RAM[cMCU_regPORTD, 7] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 155, Bmp_r0);
  end;
  // PORTE,4
  if RAM[cMCU_regTRISE, 4] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 84, Bmp_In);
    tmpSingle := TD.Port[28].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 83, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 83, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 84, Bmp_Out);
    if RAM[cMCU_regPORTE, 4] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 83, Bmp_r0);
  end;
  // PORTE,5
  if RAM[cMCU_regTRISE, 5] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_In);
    tmpSingle := TD.Port[29].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 65, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 65, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 66, Bmp_Out);
    if RAM[cMCU_regPORTE, 5] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 65, Bmp_r0);
  end;
  // PORTE,6
  if RAM[cMCU_regTRISE, 6] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 48, Bmp_In);
    tmpSingle := TD.Port[30].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 47, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 47, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 47, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 47, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 48, Bmp_Out);
    if RAM[cMCU_regPORTE, 6] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 47, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 47, Bmp_r0);
  end;
  // PORTE,7
  if RAM[cMCU_regTRISE, 7] then // Change
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 30, Bmp_In);
    tmpSingle := TD.Port[31].Node.GetLevel(); // Change
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 29, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 29, bmp_r3);
  end
  else
  begin
    (Sender as TDevice).Image.Canvas.Draw(89, 30, Bmp_Out);
    if RAM[cMCU_regPORTE, 7] then // Change
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r1)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 29, Bmp_r0);
  end;
  // T0CKI
  if RAM[cMCU_regOPTION, 5] then // ��������, �� ��������� ���� T0CS
  begin
    (Sender as TDevice).Image.Canvas.Draw(59, 14, Bmp_T0CKI);
    // ���� TOCKI
    (Sender as TDevice).Image.Canvas.Draw(89, 11, Bmp_In2);
    // ��� ������, ��� �� ����
    tmpSingle := TD.Port[32].Node.GetLevel(); // ������� �������
    if isNan(tmpSingle) then
      (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3)
    else if (tmpSingle >= MinHighLevelVoltage) and
      (tmpSingle <= MaxHighLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r1)
    else if (tmpSingle >= MinLowLevelVoltage) and
      (tmpSingle <= MaxLowLevelVoltage) then
      (Sender as TDevice).Image.Canvas.Draw(99, 11, Bmp_r0)
    else
      (Sender as TDevice).Image.Canvas.Draw(99, 11, bmp_r3);
    // ����� ����������
    if RAM[cMCU_regOPTION, 4] then // ��������, �� ��������� ���� T0SE
      (Sender as TDevice).Image.Canvas.Draw(105, 11, bmp_HiToLo)
    else
      (Sender as TDevice).Image.Canvas.Draw(105, 11, bmp_LoToHi);
  end;
  // \MCLR
  // �.�. ���� �������� ������ ���� �� ����
  tmpSingle := TD.Port[33].Node.GetLevel();
  if isNan(tmpSingle) then
    (Sender as TDevice).Image.Canvas.Draw(5, 245, bmp_r3)
  else if (tmpSingle >= MinHighLevelVoltage) and
    (tmpSingle <= MaxHighLevelVoltage) then
    (Sender as TDevice).Image.Canvas.Draw(5, 245, Bmp_r1)
  else if (tmpSingle >= MinLowLevelVoltage) and (tmpSingle <= MaxLowLevelVoltage)
  then
    (Sender as TDevice).Image.Canvas.Draw(5, 245, Bmp_r0)
  else
    (Sender as TDevice).Image.Canvas.Draw(5, 245, bmp_r3);
  exit;
end;
{$ENDREGION}
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
  SetLength(TID.vSModel, 16);
  TID.vSModel[0] := cSDevModel[0]; // PIC10F200
  TID.vSModel[1] := cSDevModel[1]; // PIC10F202
  TID.vSModel[2] := cSDevModel[2]; // PIC10F204
  TID.vSModel[3] := cSDevModel[3]; // PIC10F206
  TID.vSModel[4] := cSDevModel[4]; // PIC10F220
  TID.vSModel[5] := cSDevModel[5]; // PIC10F222
  TID.vSModel[6] := cSDevModel[6]; // PIC12F508
  TID.vSModel[7] := cSDevModel[7]; // PIC12F509
  TID.vSModel[8] := cSDevModel[8]; // PIC12F510
  TID.vSModel[9] := cSDevModel[9]; // PIC12F519
  TID.vSModel[10] := cSDevModel[10]; // PIC16F505
  TID.vSModel[11] := cSDevModel[11]; // PIC16F506
  TID.vSModel[12] := cSDevModel[12]; // PIC16F526
  TID.vSModel[13] := cSDevModel[13]; // PIC16F54
  TID.vSModel[14] := cSDevModel[14]; // PIC16F57
  TID.vSModel[15] := cSDevModel[15]; // PIC16F59
  // !!!����� "������������" ��������� ���
  // setLength(TID.vSModel, 10);

  // !!!
  TID.vIcon := LoadIcon(HInstance, 'tlb');
  TID.vSDisplayName := GetText(0);
  Get_info_class := TID;

end;

function BackProcGetLevel(Sender: TObject): Single; stdcall;
// ������� ��������� ������ ������ �������;
begin

  { ��������!
    ������ ���� ��������� ���������� ��������� ����������� BackProcDraw
    � ������:
    �������, ����� ���������� ����, ����� ������ � � ���������.
    � ��������!
  }
  // �� ������ �������� ���������� NaN (���� 3-� ��������� ��� �� ��������� �� � ����

  if rtMCId <= 5 then // ���� ���� ������ ��� PIC10F200/202/204/206/220/222
{$REGION 'for PIC10F20X/22X'}
  begin
    // ����� ������ ����� GP0 (������ � 10F200/202) � �������� �����, ��� CIN+
    if (Sender as trcport).PortNo = 0 then
    begin
      if (cMCU_regADCON0 > -1) and (RAM[cMCU_regADCON0, 6] = true) then
      // ����� AN0
      begin
        BackProcGetLevel := NaN;
        exit;
      end
      else if (cMCU_regCMCON > -1) and (RAM[cMCU_regCMCON, 3] = true) then
      // ����� CIN+
      begin
        BackProcGetLevel := NaN;
        exit;
      end
      else // GP0
        if RAM[cMCU_regTRISGPIO, 0] then
        begin // GP0 �� ����
          BackProcGetLevel := NaN;
          exit;
        end
        else
        begin // GP0 �� �����
          if RAM[cMCU_regGPIO, 0] then
            BackProcGetLevel := cHighLogicLevel
          else
            BackProcGetLevel := cLowLogicLevel;
          exit;
        end;
    end;

    // ����� ������ ����� GP1 (������ � 10F200/202) � �������� �����, ��� CIN-
    // ��������� ������� ����������� ������ � ����� � ������� �������
    if (Sender as trcport).PortNo = 1 then
    begin
      if (cMCU_regADCON0 > -1) and (RAM[cMCU_regADCON0, 7] = true) then
      // ����� AN1
      begin
        BackProcGetLevel := NaN;
        exit;
      end
      else if (cMCU_regCMCON > -1) and (RAM[cMCU_regCMCON, 3] = true) then
      // ����� CIN-
      begin
        BackProcGetLevel := NaN;
        exit;
      end
      else // GP1
        if RAM[cMCU_regTRISGPIO, 1] then
        begin
          BackProcGetLevel := NaN;
          exit;
        end
        else
        begin
          if RAM[cMCU_regGPIO, 1] then
            BackProcGetLevel := cHighLogicLevel
          else
            BackProcGetLevel := cLowLogicLevel;
          exit;
        end;
    end;

    // ��������� ����� ������ ����� GP2
    if (Sender as trcport).PortNo = 2 then
    begin
      if (cMCU_regCMCON > -1) and ((RAM[cMCU_regCMCON, 3] = true) and
        (RAM[cMCU_regCMCON, 6] = false)) then // ����� COUT
      begin
        if RAM[cMCU_regCMCON, 7] then
          BackProcGetLevel := cHighLogicLevel
        else
          BackProcGetLevel := cLowLogicLevel;
        exit;
      end
      else // ��������� ����� ������ ����� GP2 (�� ����� �� COUT)
        if cMCU_avFosc4Out and RAM[cMCU_regOSCCAL, 0] then
        // ������ ������ � �������� OSCCAL,0 <FOSC4>
        begin
          // #NI //����� OSC/4
          {
            �� �����������, �.�. �������� � ������ ����������
            ��������� �� 4 ����� ���� ���� ���������������� (��� � �������� ����������)
          }
          BackProcGetLevel := cHighLogicLevel;
          exit;
        end

        else if RAM[cMCU_regOPTION, 5] then
        begin
          BackProcGetLevel := NaN; // ���� TOCKI
          exit;
        end
        else
        begin // GP2
          if RAM[cMCU_regTRISGPIO, 2] then
          begin // �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // �� �����
            if RAM[cMCU_regGPIO, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
    end;

    // ��������� ����� ����� GP3 (�� �������� ������ �� ����)
    if (Sender as trcport).PortNo = 3 then
    begin
      if Config[4] = true then
        // �� ������ ���������������� � ���� ������������ (������ ��� pic10f200-222)
        BackProcGetLevel := NaN // ����� - /MCLR
      else
        BackProcGetLevel := NaN; // ����� - GP3
      exit;
    end;
    exit;
  end;
{$ENDREGION}
  if rtMCId <= 9 then // ���� ���� ������ ��� PIC12F508/509/510/519
{$REGION 'for PIC12F5XX'}
  begin
    if (Sender as trcport).PortNo = 0 then
    begin
      if rtMCId = 8 then
        if RAM[cMCU_regCMCON, 3] or RAM[cMCU_regADCON0, 7] then
        begin
          BackProcGetLevel := NaN;
          exit;
        end;

      begin // ����� ������ ����� - GP0 (begin ���������� ������� � 510-��
        if RAM[cMCU_regTRISGPIO, 0] then
        begin // GP0 �� ����
          BackProcGetLevel := NaN;
          exit;
        end
        else
        begin // GP0 �� �����
          if RAM[cMCU_regGPIO, 0] then
            BackProcGetLevel := cHighLogicLevel
          else
            BackProcGetLevel := cLowLogicLevel;
          exit;
        end;
      end;
    end;

    if (Sender as trcport).PortNo = 1 then
    begin
      if rtMCId = 8 then
        if RAM[cMCU_regCMCON, 3] or
          (RAM[cMCU_regADCON0, 7] and RAM[cMCU_regADCON0, 6]) then
        begin
          BackProcGetLevel := NaN;
          exit;
        end;

      begin // ����� ������ ����� - GP1 (begin ���������� ������� � 510-��)
        if RAM[cMCU_regTRISGPIO, 1] then
        begin // GP0 �� ����
          BackProcGetLevel := NaN;
          exit;
        end
        else
        begin // GP0 �� �����
          if RAM[cMCU_regGPIO, 1] then
            BackProcGetLevel := cHighLogicLevel
          else
            BackProcGetLevel := cLowLogicLevel;
          exit;
        end;
      end;
    end;

    if (Sender as trcport).PortNo = 2 then
    begin
      if rtMCId = 8 then
      begin
        if RAM[cMCU_regADCON0, 7] or RAM[cMCU_regADCON0, 6] then
        begin // ADC
          BackProcGetLevel := NaN;
          exit;
        end;
        if (RAM[cMCU_regCMCON, 3]) and (RAM[cMCU_regCMCON, 6] = false) then
        begin // ����� ����������� ��������� � ������ C1OUT (��������)

          if RAM[cMCU_regCMCON, 7] then
          begin
            BackProcGetLevel := cHighLogicLevel;
            exit;
          end
          else
          begin
            BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;

      end;

      begin // (begin ���������� ������� � 510-��)
        if RAM[cMCU_regOPTION, 5] then
        begin
          BackProcGetLevel := NaN; // ���� TOCKI
          exit;
        end
        else
        begin // GP2
          if RAM[cMCU_regTRISGPIO, 2] then
          begin // �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // �� �����
            if RAM[cMCU_regGPIO, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      end;
    end;

    if (Sender as trcport).PortNo = 3 then
    begin
      // ��������� ����� ����� GP3 (�� �������� ������ �� ����)
      if (Sender as trcport).PortNo = 3 then
      begin
        if Config[4] = true then
          // �� ������ ���������������� � ���� ������������ (������ ��� pic12f)
          BackProcGetLevel := NaN // ����� - /MCLR
        else
          BackProcGetLevel := NaN; // ����� - GP3
        exit;
      end;
    end;

    if (Sender as trcport).PortNo = 4 then
    begin
      if (Config[0] = false) and (Config[1] = true) then
      begin // GP4
        if RAM[cMCU_regTRISGPIO, 4] then
        begin // �� ����
          BackProcGetLevel := NaN;
          exit;
        end
        else
        begin // �� �����
          if RAM[cMCU_regGPIO, 4] then
            BackProcGetLevel := cHighLogicLevel
          else
            BackProcGetLevel := cLowLogicLevel;
          exit;
        end;
      end
      else
      begin // OSC
        // #NI - �� �����������, � ����� ������ ���������� "�����"
        BackProcGetLevel := NaN;
      end;
      exit;
    end;

    if (Sender as trcport).PortNo = 5 then
    begin
      if (Config[0] = false) and (Config[1] = true) then
      begin // GP5
        if RAM[cMCU_regTRISGPIO, 5] then
        begin // �� ����
          BackProcGetLevel := NaN;
          exit;
        end
        else
        begin // �� �����
          if RAM[cMCU_regGPIO, 5] then
            BackProcGetLevel := cHighLogicLevel
          else
            BackProcGetLevel := cLowLogicLevel;
          exit;
        end;
      end
      else
      begin // OSC
        // #NI - �� �����������, � ����� ������ ���������� "�����"
        BackProcGetLevel := NaN;
      end;
      exit;
    end;

    exit;
  end;
{$ENDREGION}
  if (rtMCId = 13) then // ���� ���� ������ ��� PIC16F54
{$REGION 'for PIC16F54'}
  begin
    case (Sender as trcport).PortNo of
      0:
        begin
          if RAM[cMCU_regTRISA, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      1:
        begin
          if RAM[cMCU_regTRISA, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      2:
        begin
          if RAM[cMCU_regTRISA, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      3:
        begin
          if RAM[cMCU_regTRISA, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      4:
        begin
          if RAM[cMCU_regTRISB, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      5:
        begin
          if RAM[cMCU_regTRISB, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      6:
        begin
          if RAM[cMCU_regTRISB, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      7:
        begin
          if RAM[cMCU_regTRISB, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      8:
        begin
          if RAM[cMCU_regTRISB, 4] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 4] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      9:
        begin
          if RAM[cMCU_regTRISB, 5] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 5] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      10:
        begin
          if RAM[cMCU_regTRISB, 6] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 6] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      11:
        begin
          if RAM[cMCU_regTRISB, 7] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 7] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      12:
        begin
          BackProcGetLevel := NaN; // ���� TOCKI
          exit;
        end;
      13:
        begin
          BackProcGetLevel := NaN; // ���� \MCLR
          exit;
        end;
    end;
  end;
{$ENDREGION}
  if (rtMCId = 14) then // ���� ���� ������ ��� PIC16F57
{$REGION 'for PIC16F57'}
  begin
    case (Sender as trcport).PortNo of
      0:
        begin
          if RAM[cMCU_regTRISA, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      1:
        begin
          if RAM[cMCU_regTRISA, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      2:
        begin
          if RAM[cMCU_regTRISA, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      3:
        begin
          if RAM[cMCU_regTRISA, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      4:
        begin
          if RAM[cMCU_regTRISB, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      5:
        begin
          if RAM[cMCU_regTRISB, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      6:
        begin
          if RAM[cMCU_regTRISB, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      7:
        begin
          if RAM[cMCU_regTRISB, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      8:
        begin
          if RAM[cMCU_regTRISB, 4] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 4] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      9:
        begin
          if RAM[cMCU_regTRISB, 5] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 5] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      10:
        begin
          if RAM[cMCU_regTRISB, 6] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 6] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      11:
        begin
          if RAM[cMCU_regTRISB, 7] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 7] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      12:
        begin
          if RAM[cMCU_regTRISC, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      13:
        begin
          if RAM[cMCU_regTRISC, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      14:
        begin
          if RAM[cMCU_regTRISC, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      15:
        begin
          if RAM[cMCU_regTRISC, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      16:
        begin
          if RAM[cMCU_regTRISC, 4] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 4] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      17:
        begin
          if RAM[cMCU_regTRISC, 5] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 5] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      18:
        begin
          if RAM[cMCU_regTRISC, 6] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 6] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      19:
        begin
          if RAM[cMCU_regTRISC, 7] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 7] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      20:
        begin
          BackProcGetLevel := NaN; // ���� TOCKI
          exit;
        end;
      21:
        begin
          BackProcGetLevel := NaN; // ���� \MCLR
          exit;
        end;
    end;
  end;
{$ENDREGION}
  if (rtMCId = 15) then // ���� ���� ������ ��� PIC16F59
{$REGION 'for PIC16F59'}
  begin
    case (Sender as trcport).PortNo of
      0:
        begin
          if RAM[cMCU_regTRISA, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      1:
        begin
          if RAM[cMCU_regTRISA, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      2:
        begin
          if RAM[cMCU_regTRISA, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      3:
        begin
          if RAM[cMCU_regTRISA, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTA, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      4:
        begin
          if RAM[cMCU_regTRISB, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      5:
        begin
          if RAM[cMCU_regTRISB, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      6:
        begin
          if RAM[cMCU_regTRISB, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      7:
        begin
          if RAM[cMCU_regTRISB, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      8:
        begin
          if RAM[cMCU_regTRISB, 4] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 4] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      9:
        begin
          if RAM[cMCU_regTRISB, 5] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 5] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      10:
        begin
          if RAM[cMCU_regTRISB, 6] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 6] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      11:
        begin
          if RAM[cMCU_regTRISB, 7] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTB, 7] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      12:
        begin
          if RAM[cMCU_regTRISC, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      13:
        begin
          if RAM[cMCU_regTRISC, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      14:
        begin
          if RAM[cMCU_regTRISC, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      15:
        begin
          if RAM[cMCU_regTRISC, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      16:
        begin
          if RAM[cMCU_regTRISC, 4] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 4] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      17:
        begin
          if RAM[cMCU_regTRISC, 5] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 5] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      18:
        begin
          if RAM[cMCU_regTRISC, 6] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 6] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      19:
        begin
          if RAM[cMCU_regTRISC, 7] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTC, 7] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      20:
        begin
          if RAM[cMCU_regTRISD, 0] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 0] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      21:
        begin
          if RAM[cMCU_regTRISD, 1] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 1] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      22:
        begin
          if RAM[cMCU_regTRISD, 2] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 2] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      23:
        begin
          if RAM[cMCU_regTRISD, 3] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 3] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      24:
        begin
          if RAM[cMCU_regTRISD, 4] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 4] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      25:
        begin
          if RAM[cMCU_regTRISD, 5] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 5] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      26:
        begin
          if RAM[cMCU_regTRISD, 6] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 6] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      27:
        begin
          if RAM[cMCU_regTRISD, 7] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTD, 7] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      28:
        begin
          if RAM[cMCU_regTRISE, 4] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTE, 4] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      29:
        begin
          if RAM[cMCU_regTRISE, 5] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTE, 5] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      30:
        begin
          if RAM[cMCU_regTRISE, 6] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTE, 6] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      31:
        begin
          if RAM[cMCU_regTRISE, 7] then
          begin // PA0 �� ����
            BackProcGetLevel := NaN;
            exit;
          end
          else
          begin // GP0 �� �����
            if RAM[cMCU_regPORTE, 7] then
              BackProcGetLevel := cHighLogicLevel
            else
              BackProcGetLevel := cLowLogicLevel;
            exit;
          end;
        end;
      32:
        begin
          BackProcGetLevel := NaN; // ���� TOCKI
          exit;
        end;
      33:
        begin
          BackProcGetLevel := NaN; // ���� \MCLR
          exit;
        end;
    end;
  end;
{$ENDREGION}
end;

Procedure BackShowSettings(Sender: TObject); stdcall;
var
  I: integer;
begin
  application.Handle := TD.hosthandle;
  application.CreateForm(TformSettings, formSettings);
  // frmsettings.formSettings:=TFormSettings.Create(application);

  formSettings.InternalIndex := (Sender as TDevice).InternalIndex;
  formSettings.Device := (Sender as TDevice);
  formSettings.OrigHandle := TD.OrigHandle;
  for I := 0 to 11 do
    formSettings.Config[I] := Config[I];
  formSettings.ConfigBits := ConfigBits;
  formSettings.rtCrystalFreq := rtCrystalFreq;
  formSettings.ShowModal; // ������� ����� ��������
  // �������� �������, ������� ����������
  for I := 0 to 11 do
    Config[I] := formSettings.Config[I];
  rtCrystalFreq := formSettings.rtCrystalFreq;
end;

Procedure BackApplySaveData(Sender: TObject); stdcall;
var
  k: integer;
var
  frq: string;
begin
  // ��������� ����� ������������
  for k := 0 to 11 do
    if (Sender as TDevice).SaveData[k] = '1' then
      Config[k] := true
    else
      Config[k] := false;
  // ��������� ������� ������
  frq := (Sender as TDevice).SaveData[13] + (Sender as TDevice).SaveData[14] +
    (Sender as TDevice).SaveData[15] + (Sender as TDevice).SaveData[16] +
    (Sender as TDevice).SaveData[17] + (Sender as TDevice).SaveData[18] +
    (Sender as TDevice).SaveData[19] + (Sender as TDevice).SaveData[20] +
    (Sender as TDevice).SaveData[21];
  if (Sender as TDevice).SaveData[12] = '1' then
  begin // ��� ������������ ��������� ������� ������
    rtCrystalFreq := strtoint(frq);
  end
  else
  begin // ��� �����-�� �����������
    rtCrystalFreq := 4000000; // ��� PIC10F200/202/204/206
    if (TD.RCModel = 'PIC10F220') or (TD.RCModel = 'PIC10F222') then
      // ��� 10F220/222
      if Config[0] = true then
        rtCrystalFreq := 8000000
      else
        rtCrystalFreq := 4000000;

  end;

  // ����� ������ POR
  POR;

end;

Function Get_Device_class(hosthandle: THandle; MainDevice: TDevice)
  : TDevice; stdcall;
var
  k: integer;
begin
  UnitRes.SetLang();
  if not ResAlreadyLoaded then
  begin
    // �������� ����������� �� ��������
    Bmp200 := TBitmap.Create;
    Bmp200.Handle := LoadBitmap(HInstance, 'PIC10F200');
    Bmp200_free := TBitmap.Create;
    Bmp200_free.Handle := LoadBitmap(HInstance, 'PIC10F200_free');
    Bmp202 := TBitmap.Create;
    Bmp202.Handle := LoadBitmap(HInstance, 'PIC10F202');
    Bmp202_free := TBitmap.Create;
    Bmp202_free.Handle := LoadBitmap(HInstance, 'PIC10F202_free');
    Bmp204 := TBitmap.Create;
    Bmp204.Handle := LoadBitmap(HInstance, 'PIC10F204');
    Bmp204_free := TBitmap.Create;
    Bmp204_free.Handle := LoadBitmap(HInstance, 'PIC10F204_free');
    Bmp206 := TBitmap.Create;
    Bmp206.Handle := LoadBitmap(HInstance, 'PIC10F206');
    Bmp206_free := TBitmap.Create;
    Bmp206_free.Handle := LoadBitmap(HInstance, 'PIC10F206_free');
    Bmp220 := TBitmap.Create;
    Bmp220.Handle := LoadBitmap(HInstance, 'PIC10F220');
    Bmp220_free := TBitmap.Create;
    Bmp220_free.Handle := LoadBitmap(HInstance, 'PIC10F220_free');
    Bmp222 := TBitmap.Create;
    Bmp222.Handle := LoadBitmap(HInstance, 'PIC10F222');
    Bmp222_free := TBitmap.Create;
    Bmp222_free.Handle := LoadBitmap(HInstance, 'PIC10F222_free');
    Bmp508 := TBitmap.Create;
    Bmp508.Handle := LoadBitmap(HInstance, 'PIC12F508');
    Bmp508_free := TBitmap.Create;
    Bmp508_free.Handle := LoadBitmap(HInstance, 'PIC12F508_free');

    Bmp509 := TBitmap.Create;
    Bmp509.Handle := LoadBitmap(HInstance, 'PIC12F509');
    Bmp509_free := TBitmap.Create;
    Bmp509_free.Handle := LoadBitmap(HInstance, 'PIC12F509_free');
    Bmp510 := TBitmap.Create;
    Bmp510.Handle := LoadBitmap(HInstance, 'PIC12F510');
    Bmp510_free := TBitmap.Create;
    Bmp510_free.Handle := LoadBitmap(HInstance, 'PIC12F510_free');
    Bmp519 := TBitmap.Create;
    Bmp519.Handle := LoadBitmap(HInstance, 'PIC12F519');
    Bmp519_free := TBitmap.Create;
    Bmp519_free.Handle := LoadBitmap(HInstance, 'PIC12F519_free');
    Bmp505 := TBitmap.Create;
    Bmp505.Handle := LoadBitmap(HInstance, 'PIC16F505');
    Bmp505_free := TBitmap.Create;
    Bmp505_free.Handle := LoadBitmap(HInstance, 'PIC16F505_free');
    Bmp506 := TBitmap.Create;
    Bmp506.Handle := LoadBitmap(HInstance, 'PIC16F506');
    Bmp506_free := TBitmap.Create;
    Bmp506_free.Handle := LoadBitmap(HInstance, 'PIC16F506_free');
    Bmp526 := TBitmap.Create;
    Bmp526.Handle := LoadBitmap(HInstance, 'PIC16F526');
    Bmp526_free := TBitmap.Create;
    Bmp526_free.Handle := LoadBitmap(HInstance, 'PIC16F526_free');
    Bmp54 := TBitmap.Create;
    Bmp54.Handle := LoadBitmap(HInstance, 'PIC16F54');
    Bmp54_free := TBitmap.Create;
    Bmp54_free.Handle := LoadBitmap(HInstance, 'PIC16F54_free');
    Bmp57 := TBitmap.Create;
    Bmp57.Handle := LoadBitmap(HInstance, 'PIC16F57');
    Bmp57_free := TBitmap.Create;
    Bmp57_free.Handle := LoadBitmap(HInstance, 'PIC16F57_free');
    Bmp59 := TBitmap.Create;
    Bmp59.Handle := LoadBitmap(HInstance, 'PIC16F59');
    Bmp59_free := TBitmap.Create;
    Bmp59_free.Handle := LoadBitmap(HInstance, 'PIC16F59_free');

    Bmp_r0 := TBitmap.Create;
    Bmp_r0.Handle := LoadBitmap(HInstance, 'r0');
    Bmp_r1 := TBitmap.Create;
    Bmp_r1.Handle := LoadBitmap(HInstance, 'r1');
    bmp_r3 := TBitmap.Create;
    bmp_r3.Handle := LoadBitmap(HInstance, 'r3');
    Bmp_In := TBitmap.Create;
    Bmp_In.Handle := LoadBitmap(HInstance, 'In');
    Bmp_Out := TBitmap.Create;
    Bmp_Out.Handle := LoadBitmap(HInstance, 'Out');
    Bmp_In2 := TBitmap.Create;
    Bmp_In2.Handle := LoadBitmap(HInstance, 'In2');
    Bmp_Out2 := TBitmap.Create;
    Bmp_Out2.Handle := LoadBitmap(HInstance, 'Out2');
    Bmp_GP0 := TBitmap.Create;
    Bmp_GP0.Handle := LoadBitmap(HInstance, 'GP0');
    Bmp_GP1 := TBitmap.Create;
    Bmp_GP1.Handle := LoadBitmap(HInstance, 'GP1');
    Bmp_GP2 := TBitmap.Create;
    Bmp_GP2.Handle := LoadBitmap(HInstance, 'GP2');
    Bmp_GP3 := TBitmap.Create;
    Bmp_GP3.Handle := LoadBitmap(HInstance, 'GP3');
    Bmp_GP4 := TBitmap.Create;
    Bmp_GP4.Handle := LoadBitmap(HInstance, 'GP4');
    Bmp_GP5 := TBitmap.Create;
    Bmp_GP5.Handle := LoadBitmap(HInstance, 'GP5');
    Bmp_MCLR := TBitmap.Create;
    Bmp_MCLR.Handle := LoadBitmap(HInstance, 'MCLR');
    Bmp_T0CKI := TBitmap.Create;
    Bmp_T0CKI.Handle := LoadBitmap(HInstance, 'T0CKI');
    Bmp_Fosc4 := TBitmap.Create;
    Bmp_Fosc4.Handle := LoadBitmap(HInstance, 'Fosc4');
    bmp_HiToLo := TBitmap.Create;
    bmp_HiToLo.Handle := LoadBitmap(HInstance, 'HiToLo');
    bmp_LoToHi := TBitmap.Create;
    bmp_LoToHi.Handle := LoadBitmap(HInstance, 'LoToHi');
    Bmp_CINn := TBitmap.Create;
    Bmp_CINn.Handle := LoadBitmap(HInstance, 'CINn');
    Bmp_CINp := TBitmap.Create;
    Bmp_CINp.Handle := LoadBitmap(HInstance, 'CINp');
    Bmp_cout := TBitmap.Create;
    Bmp_cout.Handle := LoadBitmap(HInstance, 'cout');
    Bmp_minus := TBitmap.Create;
    Bmp_minus.Handle := LoadBitmap(HInstance, 'minus');
    Bmp_V := TBitmap.Create;
    Bmp_V.Handle := LoadBitmap(HInstance, 'V');
    bmp_0 := TBitmap.Create;
    bmp_0.Handle := LoadBitmap(HInstance, 'sd0');
    bmp_1 := TBitmap.Create;
    bmp_1.Handle := LoadBitmap(HInstance, 'sd1');
    bmp_2 := TBitmap.Create;
    bmp_2.Handle := LoadBitmap(HInstance, 'sd2');
    bmp_3 := TBitmap.Create;
    bmp_3.Handle := LoadBitmap(HInstance, 'sd3');
    bmp_4 := TBitmap.Create;
    bmp_4.Handle := LoadBitmap(HInstance, 'sd4');
    bmp_5 := TBitmap.Create;
    bmp_5.Handle := LoadBitmap(HInstance, 'sd5');
    bmp_6 := TBitmap.Create;
    bmp_6.Handle := LoadBitmap(HInstance, 'sd6');
    bmp_7 := TBitmap.Create;
    bmp_7.Handle := LoadBitmap(HInstance, 'sd7');
    bmp_8 := TBitmap.Create;
    bmp_8.Handle := LoadBitmap(HInstance, 'sd8');
    bmp_9 := TBitmap.Create;
    bmp_9.Handle := LoadBitmap(HInstance, 'sd9');
    bmp_dot := TBitmap.Create;
    bmp_dot.Handle := LoadBitmap(HInstance, 'dot');
    Bmp_AN0 := TBitmap.Create;
    Bmp_AN0.Handle := LoadBitmap(HInstance, 'AN0');
    Bmp_AN1 := TBitmap.Create;
    Bmp_AN1.Handle := LoadBitmap(HInstance, 'AN1');
    Bmp_CLKIN := TBitmap.Create;
    Bmp_CLKIN.Handle := LoadBitmap(HInstance, 'CLKIN');
    Bmp_OSC1 := TBitmap.Create;
    Bmp_OSC1.Handle := LoadBitmap(HInstance, 'OSC1');
    Bmp_OSC2 := TBitmap.Create;
    Bmp_OSC2.Handle := LoadBitmap(HInstance, 'OSC2');

    bmp_RA0 := TBitmap.Create;
    bmp_RA0.Handle := LoadBitmap(HInstance, 'RA0');
    bmp_RA1 := TBitmap.Create;
    bmp_RA1.Handle := LoadBitmap(HInstance, 'RA1');
    bmp_RA2 := TBitmap.Create;
    bmp_RA2.Handle := LoadBitmap(HInstance, 'RA2');
    bmp_RA3 := TBitmap.Create;
    bmp_RA3.Handle := LoadBitmap(HInstance, 'RA3');
    bmp_RB0 := TBitmap.Create;
    bmp_RB0.Handle := LoadBitmap(HInstance, 'RB0');
    bmp_RB1 := TBitmap.Create;
    bmp_RB1.Handle := LoadBitmap(HInstance, 'RB1');
    bmp_RB2 := TBitmap.Create;
    bmp_RB2.Handle := LoadBitmap(HInstance, 'RB2');
    bmp_RB3 := TBitmap.Create;
    bmp_RB3.Handle := LoadBitmap(HInstance, 'RB3');
    bmp_RB4 := TBitmap.Create;
    bmp_RB4.Handle := LoadBitmap(HInstance, 'RB4');
    bmp_RB5 := TBitmap.Create;
    bmp_RB5.Handle := LoadBitmap(HInstance, 'RB5');
    bmp_RB6 := TBitmap.Create;
    bmp_RB6.Handle := LoadBitmap(HInstance, 'RB6');
    bmp_RB7 := TBitmap.Create;
    bmp_RB7.Handle := LoadBitmap(HInstance, 'RB7');
    bmp_RC0 := TBitmap.Create;
    bmp_RC0.Handle := LoadBitmap(HInstance, 'RC0');
    bmp_RC1 := TBitmap.Create;
    bmp_RC1.Handle := LoadBitmap(HInstance, 'RC1');
    bmp_RC2 := TBitmap.Create;
    bmp_RC2.Handle := LoadBitmap(HInstance, 'RC2');
    bmp_RC3 := TBitmap.Create;
    bmp_RC3.Handle := LoadBitmap(HInstance, 'RC3');
    bmp_RC4 := TBitmap.Create;
    bmp_RC4.Handle := LoadBitmap(HInstance, 'RC4');
    bmp_RC5 := TBitmap.Create;
    bmp_RC5.Handle := LoadBitmap(HInstance, 'RC5');
    bmp_RC6 := TBitmap.Create;
    bmp_RC6.Handle := LoadBitmap(HInstance, 'RC6');
    bmp_RC7 := TBitmap.Create;
    bmp_RC7.Handle := LoadBitmap(HInstance, 'RC7');
    bmp_RD0 := TBitmap.Create;
    bmp_RD0.Handle := LoadBitmap(HInstance, 'RD0');
    bmp_RD1 := TBitmap.Create;
    bmp_RD1.Handle := LoadBitmap(HInstance, 'RD1');
    bmp_RD2 := TBitmap.Create;
    bmp_RD2.Handle := LoadBitmap(HInstance, 'RD2');
    bmp_RD3 := TBitmap.Create;
    bmp_RD3.Handle := LoadBitmap(HInstance, 'RD3');
    bmp_RD4 := TBitmap.Create;
    bmp_RD4.Handle := LoadBitmap(HInstance, 'RD4');
    bmp_RD5 := TBitmap.Create;
    bmp_RD5.Handle := LoadBitmap(HInstance, 'RD5');
    bmp_RD6 := TBitmap.Create;
    bmp_RD6.Handle := LoadBitmap(HInstance, 'RD6');
    bmp_RD7 := TBitmap.Create;
    bmp_RD7.Handle := LoadBitmap(HInstance, 'RD7');
    bmp_RE4 := TBitmap.Create;
    bmp_RE4.Handle := LoadBitmap(HInstance, 'RE4');
    bmp_RE5 := TBitmap.Create;
    bmp_RE5.Handle := LoadBitmap(HInstance, 'RE5');
    bmp_RE6 := TBitmap.Create;
    bmp_RE6.Handle := LoadBitmap(HInstance, 'RE6');
    bmp_RE7 := TBitmap.Create;
    bmp_RE7.Handle := LoadBitmap(HInstance, 'RE7');

    bmp_C1INp := TBitmap.Create;
    bmp_C1INp.Handle := LoadBitmap(HInstance, 'C1INp');
    bmp_C1INn := TBitmap.Create;
    bmp_C1INn.Handle := LoadBitmap(HInstance, 'C1INn');
    bmp_AN2 := TBitmap.Create;
    bmp_AN2.Handle := LoadBitmap(HInstance, 'AN2');
    bmp_C1OUT := TBitmap.Create;
    bmp_C1OUT.Handle := LoadBitmap(HInstance, 'C1OUT');
    bmp_CLKOUT := TBitmap.Create;
    bmp_CLKOUT.Handle := LoadBitmap(HInstance, 'CLKOUT');
    bmp_C2OUT := TBitmap.Create;
    bmp_C2OUT.Handle := LoadBitmap(HInstance, 'C2OUT');
    bmp_C2INp := TBitmap.Create;
    bmp_C2INp.Handle := LoadBitmap(HInstance, 'C2INp');
    bmp_C2INn := TBitmap.Create;
    bmp_C2INn.Handle := LoadBitmap(HInstance, 'C2INn');
    bmp_CVref := TBitmap.Create;
    bmp_CVref.Handle := LoadBitmap(HInstance, 'CVref');

    bmp_AN0C1INp := TBitmap.Create;
    bmp_AN0C1INp.Handle := LoadBitmap(HInstance, 'AN0C1INp');
    bmp_AN1C1INn := TBitmap.Create;
    bmp_AN1C1INn.Handle := LoadBitmap(HInstance, 'AN1C1INn');

    ResAlreadyLoaded := true;
  end;

  // ������ ������ ������� ������

  // ������� ��������� ������ 1-�� �����
  // TP[0]:=TRCPort.Create ( 'GP0', 3, true, 0,@BackProcGetLevel,0);
  // TP[1]:=TRCPort.Create ( 'GP1', 3, true, 0,@BackProcGetLevel,1);
  // TP[2]:=TRCPort.Create ( 'GP2/T0CKI/Fosc4', 3, true, 0,@BackProcGetLevel,2);
  // TP[3]:=TRCPort.Create ( 'GP3/\MCLR', 1, true, 0,@BackProcGetLevel,3);
  // ������� ��������� ������ ������ ����������
  case rtMCId of
    0:
{$REGION 'POR for PIC10F200'}
      begin
        TD := TDevice.Create(0, Bmp200.Width, Bmp200.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 4, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI/Fosc4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    1:
{$REGION 'POR for PIC10F202'}
      begin
        TD := TDevice.Create(0, Bmp202.Width, Bmp202.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 4, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI/Fosc4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    2:
{$REGION 'POR for PIC10F204'}
      begin
        TD := TDevice.Create(0, Bmp204.Width, Bmp204.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 4, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0/CIN+', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1/CIN-', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI/COUT/Fosc4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    3:
{$REGION 'POR for PIC10F206'}
      begin
        TD := TDevice.Create(0, Bmp206.Width, Bmp206.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 4, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0/CIN+', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1/CIN-', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI/COUT/Fosc4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    4:
{$REGION 'POR for PIC10F220'}
      begin
        TD := TDevice.Create(0, Bmp220.Width, Bmp220.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 4, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0/AN0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1/AN1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI/Fosc4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    5:
{$REGION 'POR for PIC10F222'}
      begin
        TD := TDevice.Create(0, Bmp222.Width, Bmp222.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 4, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0/AN0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1/AN1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI/Fosc4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    6:
{$REGION 'POR for PIC12F508'}
      begin
        TD := TDevice.Create(0, Bmp508.Width, Bmp508.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 6, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('GP4/OSC2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP5/OSC1/CLKIN', 3, true, 0, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    7:
{$REGION 'POR for PIC12F509'}
      begin
        TD := TDevice.Create(0, Bmp509.Width, Bmp509.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 6, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('GP4/OSC2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP5/OSC1/CLKIN', 3, true, 0, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    8:
{$REGION 'POR for PIC12F510'}
      begin
        TD := TDevice.Create(0, Bmp510.Width, Bmp510.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 6, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0/AN0/C1IN+', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1/AN1/C1IN-', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('GP4/OSC2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP5/OSC1/CLKIN', 3, true, 0, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    9:
{$REGION 'POR for PIC12F519'}
      begin
        TD := TDevice.Create(0, Bmp519.Width, Bmp519.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 6, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('GP0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP2/T0CKI', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('GP4/OSC2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('GP5/OSC1/CLKIN', 3, true, 0, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    10:
{$REGION 'POR for PIC16F505'}
      begin
        TD := TDevice.Create(0, Bmp505.Width, Bmp505.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 12, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('RB0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('RB4/OSC2/CLKOUT', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB5/OSC1/CLKIN', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC5/T0CKI', 3, true, 0, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    11:
{$REGION 'POR for PIC16F506'}
      begin
        TD := TDevice.Create(0, Bmp506.Width, Bmp506.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 12, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('RB0/AN0/C1IN+', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB1/AN1/C1IN-', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB2/AN2/C1OUT', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('RB4/OSC2/CLKOUT', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB5/OSC1/CLKIN', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC0/C2IN+', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC1/C2IN-', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC2/CVref', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC4/C2OUT', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC5/T0CKI', 3, true, 0, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    12:
{$REGION 'POR for PIC16F526'}
      begin
        TD := TDevice.Create(0, Bmp526.Width, Bmp526.height, cDevType,
          cSDevType, cSDevFamily, cSDevModel[rtMCId], 12, @BackProcDraw, nil,
          nil, nil, nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('RB0/AN0/C1IN+', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB1/AN1/C1IN-', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB2/AN2/C1OUT', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB3/\MCLR', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('RB4/OSC2/CLKOUT', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB5/OSC1/CLKIN', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC0/C2IN+', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC1/C2IN-', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC2/CVref', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC4/C2OUT', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC5/T0CKI', 3, true, 0, @BackProcGetLevel);
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    13:
{$REGION 'POR for PIC16F54'}
      begin
        TD := TDevice.Create(0, Bmp54.Width, Bmp54.height, cDevType, cSDevType,
          cSDevFamily, cSDevModel[rtMCId], 14, @BackProcDraw, nil, nil, nil,
          nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('RA0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB5', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB6', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB7', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('T0CKI', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('MCLR', 1, true, NaN, @BackProcGetLevel); // #13
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    14:
{$REGION 'POR for PIC16F57'}
      begin
        TD := TDevice.Create(0, Bmp57.Width, Bmp57.height, cDevType, cSDevType,
          cSDevFamily, cSDevModel[rtMCId], 22, @BackProcDraw, nil, nil, nil,
          nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('RA0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB5', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB6', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB7', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC5', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC6', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC7', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('T0CKI', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('MCLR', 1, true, NaN, @BackProcGetLevel); // #21
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
    15:
{$REGION 'POR for PIC16F59'}
      begin
        TD := TDevice.Create(0, Bmp59.Width, Bmp59.height, cDevType, cSDevType,
          cSDevFamily, cSDevModel[rtMCId], 34, @BackProcDraw, nil, nil, nil,
          nil, nil, @BackShowSettings, @BackApplySaveData, nil,
          application.Handle, hosthandle, MainDevice, @Get_MCandCF);
        TD.AddPort('RA0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RA3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB5', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB6', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RB7', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC5', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC6', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RC7', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD0', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD1', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD2', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD3', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD5', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD6', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RD7', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RE4', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RE5', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RE6', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('RE7', 3, true, 0, @BackProcGetLevel);
        TD.AddPort('T0CKI', 1, true, NaN, @BackProcGetLevel);
        TD.AddPort('MCLR', 1, true, NaN, @BackProcGetLevel); // #33
        // ��������� ������ �� ��������� ������ ����������
        result := TD;
      end;
{$ENDREGION}
  end;

  // ������ ��� ����������
  TD.LenSaveData := 23;
  // ���� ������������ [0-11]
  for k := 0 to 11 do
    if Config[k] = true then
      TD.SaveData[k] := '1'
    else
      TD.SaveData[k] := '0';
  // ��������� ������ "������������ ������������� �������" [12]
  TD.SaveData[12] := '0';
  // "������������� �������" [13-21] (4000000 ��)
  TD.SaveData[13] := '0';
  TD.SaveData[14] := '0';
  TD.SaveData[15] := '4';
  TD.SaveData[16] := '0';
  TD.SaveData[17] := '0';
  TD.SaveData[18] := '0';
  TD.SaveData[19] := '0';
  TD.SaveData[20] := '0';
  TD.SaveData[21] := '0';
  // ��������, ������������ �������� GetXValue
  TD.SaveData[22] := '0';
  // �������� ��� ��� ���������
  BackApplySaveData(TD);
end;

// ���������� ������� �����������

exports Get_Device_class name 'Get_Device_class';

exports Get_info_class name 'Get_info_class';

exports What_is name 'What_is';

exports BackApplySaveData name 'BackApplySaveData';

// ������������� ��� ��

exports Get_MatrixRAM_ToClearDelta name 'Get_MatrixRAM_ToClearDelta';

exports Set_MatrixRAM_ToClearDelta name 'Set_MatrixRAM_ToClearDelta';

exports Get_MatrixRAM_SIMadress name 'Get_MatrixRAM_SIMadress';

exports Set_MatrixRAM_SIMadress name 'Set_MatrixRAM_SIMadress';

exports Get_MatrixRAM_BreakPoint name 'Get_MatrixRAM_BreakPoint';

exports Set_MatrixRAM_BreakPoint name 'Set_MatrixRAM_BreakPoint';

exports Get_MatrixRAM_GreenBP name 'Get_MatrixRAM_GreenBP';

exports Set_MatrixRAM_GreenBP name 'Set_MatrixRAM_GreenBP';

exports Get_MatrixRAM_IDEHexaddres name 'Get_MatrixRAM_IDEHexaddres';

exports Get_MatrixRAM_IDEName name 'Get_MatrixRAM_IDEName';

exports Get_MatrixRAM_delta name 'Get_MatrixRAM_delta';

exports Set_MatrixRAM_delta name 'Set_MatrixRAM_delta';

exports Get_MatrixRAM_greenDelta name 'Get_MatrixRAM_greenDelta';

exports Set_MatrixRAM_greenDelta name 'Set_MatrixRAM_greenDelta';

exports Get_MatrixRAM_deltabit name 'Get_MatrixRAM_deltabit';

exports Set_MatrixRAM_deltabit name 'Set_MatrixRAM_deltabit';

exports Get_MatrixRAM_usedbit name 'Get_MatrixRAM_usedbit';

exports Set_MatrixRAM_usedbit name 'Set_MatrixRAM_usedbit';

exports Get_MatrixRAM_bitname name 'Get_MatrixRAM_bitname';

exports Set_MatrixRAM_bitname name 'Set_MatrixRAM_bitname';

exports Get_StackCounter name 'Get_StackCounter';

exports Get_IC name 'Get_IC';

exports Get_stack name 'Get_stack';

exports Get_PC name 'Get_PC';

exports Get_TaktsWDT name 'Get_TaktsWDT';

exports Get_StackMax name 'Get_StackMax';

exports GetInstruction name 'GetInstruction';

exports Get_family_mc name 'Get_family_mc';

exports Get_SystemCommandCounter name 'Get_SystemCommandCounter';

{ exports Get_ConfigBitsCounter name 'Get_ConfigBitsCounter';

  exports Get_ConfigBitsHI name 'Get_ConfigBitsHI'; }

exports Get_rtRunning name 'Get_rtRunning';

exports Set_rtRunning name 'Set_rtRunning';

exports Get_UserTimer name 'Get_UserTimer';

exports Set_UserTimer name 'Set_UserTimer';

exports Get_MCandCF name 'Get_MCandCF';

exports Get_RAM name 'Get_RAM';

exports Set_RAM name 'Set_RAM';

exports Get_ROM name 'Get_ROM';

exports Set_ROM name 'Set_ROM';

exports Get_SFRcount name 'Get_SFRcount';

exports CurrentToParCommand name 'CurrentToParCommand';

exports RomToParCommand name 'RomToParCommand';

exports Get_I name 'Get_I';

exports Get_ROM_Size name 'Get_ROM_Size';

exports Get_GPRCount name 'Get_GPRCount';

exports Get_rtPause name 'Get_rtPause';

exports Set_rtPause name 'Set_rtPause';

exports Set_RT_parametrs name 'Set_RT_parametrs';

exports Get_rtRefreshComplete name 'Get_rtRefreshComplete';

exports Set_rtRefreshComplete name 'Set_rtRefreshComplete';

exports Get_RT_parametrs name 'Get_RT_parametrs';

exports SelectMC name 'SelectMC';

exports Calculate_CuclPerCycMK_AndRun name 'Calculate_CuclPerCycMK';

exports Get_SystemCommand_CommandName name 'Get_SystemCommand_CommandName';

exports Get_parGOTOaddr name 'Get_parGOTOaddr';

exports Get_config name 'Get_config';

exports set_config name 'Set_config';

exports Set_rtexStep name 'Set_rtexStep';

exports Get_ROM_Str_No_from name 'Get_ROM_Str_No_from';

exports Get_ROM_Str_No_to name 'Get_ROM_Str_No_to';

exports Get_ROM_Str_No name 'Get_ROM_Str_No';

exports Set_ROM_Str_No_from name 'Set_ROM_Str_No_from';

exports Set_ROM_Str_No_to name 'Set_ROM_Str_No_to';

exports Set_ROM_Str_No name 'Set_ROM_Str_No';

exports Set_ROM_BP name 'Set_ROM_BP';

exports Get_PC_Len name 'Get_PC_Len';

// exports Get_ConfigBits name 'Get_ConfigBits';

exports Destroy_CO name 'Destroy_CO';

begin

  // ���, ����������� ��� �������� ����������
end.
