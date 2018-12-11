unit PIC10F;

interface

uses
  Classes,sysutils,mmsystem;
procedure PCLpp();
procedure resetRAM(Id:Byte);
procedure SelectMC(Id:byte);
function GetInstruction():String;
function DimensionCPUCyclesPerSecond:int64;

type
  TRun = class(TThread)
  private
    { Private declarations }

  protected
    procedure Execute; override;

  end;
type TMatrixRAM = record
  IDEaddres:Integer;
  SIMadress:Word; //����� ����������� �������������
  IDEName:String[16];
  IDEHexaddres:string;
  Used:boolean;
  SFR:boolean;
  VirtSFR:boolean;
  delta:boolean;
  value: array[0..7] of boolean;
  deltabit: array[0..7] of boolean;
  usedbit: array[0..7] of boolean;
  bitname:array[0..7] of string[8];
end;
var
//���� ����������, ���������� �� ����� ������ ����������

rtRunning:boolean; //� ������ �������� ��?
rtStepByStep:boolean; //��� �� �����?
rtexStep:boolean; //��������� ������� ���
rtPause:boolean; //�����
rtWithDelay:boolean; //� ���������
rtDelayMS:integer; //��������
rtWithSyncro:boolean; //� ��������������
rtSyncro:real; //������ ����
rtSyncroTMP:int64; //��������� ���� ��� ������������� (������������� ������ �������)

rtCyclPerCycMK:int64; //����, ������������, ������� ������ CPU � ����� ����� ��
rtCrystalFreq:int64; //������� �� � ������ ��


//�������� ����������, ���������� "������� �����" ���������
I:Integer;
//�������� ����������, ��������� � ������ ��
MatrixRAM:array of TMatrixRAM; //�������� ������� ��� �/� ���������� � IDE
AllRAMSize:Word; //������ ������ RAM - GPR,SFR, ������� �����������
SFRCount:Word; //���-�� SFR, ������� W � �����������
GPRCount:Word; //���-�� GPR
//�������� ���
ROM:array[0..255,0..11] of boolean;
//������� �������� �� ���
CurrentCommand:array[0..11] of boolean;
//������� W
regW:Word;
//������� TRIS
regTRISGPI0:Word;
// ������� OPTION
regOPTION:Word;
//������� INDF
regINDF:Word;
//������� TMR0 Prescaler
regTMR0P:Word;
//����������� ������, ������� GFR � SFR
RAM:array of array of boolean;
//��� ������������
Config:array[0..11] of boolean;
//Instruction Counter
IC:Int64;
//Machine cycles
MC:Int64;
//Stack
St1,St2,StC:byte;
bSt1,bSt2:array[0..7] of boolean;
//����� � ������ � Ram, ������� ������ ����� ���� ��������
ChangeAddr:Word;
�hangeData:array[0..7] of boolean;
ChangeBitAddr:Word;
ChangeBitNo:Byte;
ChangeBitData:boolean;
//��������, � ������� ����������� bin-������ ��� ��������������� � �� ��
par:array[0..8] of boolean;
//�������� ������� �������� ��������, � ���. ���������� ��������, ���. ����� ������������
parCommand:array[0..11] of boolean;
implementation



{
  Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TRun.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end;

    or

    Synchronize(
      procedure
      begin
        Form1.Caption := 'Updated in thread via an anonymous method'
      end
      )
    );

  where an anonymous method is passed.

  Similarly, the developer can call the Queue method with similar parameters as
  above, instead passing another TThread class as the first parameter, putting
  the calling thread in a queue with the other thread.

}

{ TRun }

procedure PCLpp();  //���������� �� 1 �������� PCL
begin
  if RAM[2,0]=false then
  begin
    RAM[2,0]:=true;
    exit;
  end
  else
  begin
    RAM[2,0]:=false;
    if RAM[2,1]=false then
    begin
      RAM[2,1]:=true;
      exit;
    end
    else
    begin
      RAM[2,1]:=false;
      if RAM[2,2]=false then
      begin
        RAM[2,2]:=true;
        exit;
      end
      else
      begin
        RAM[2,2]:=false;
        if RAM[2,3]=false then
        begin
        RAM[2,3]:=true;
        exit;
        end
        else
        begin
          RAM[2,3]:=false;
          if RAM[2,4]=false then
          begin
          RAM[2,4]:=true;
          exit;
          end
          else
          begin
            RAM[2,4]:=false;
            if RAM[2,5]=false then
            begin
            RAM[2,5]:=true;
            exit;
            end
            else
            begin
              RAM[2,5]:=false;
              if RAM[2,6]=false then
              begin
              RAM[2,6]:=true;
              exit;
              end
              else
              begin
                RAM[2,6]:=false;
                if RAM[2,7]=false then
                begin
                RAM[2,7]:=true;
                exit;
                end
                else
                begin

                RAM[2,7]:=false;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure ChangeRAMByte(); //���������� ChangeAddr,ChangeData ������������
begin
//��������, � ������ ������������ �� ���� ����
if MatrixRAM[ChangeAddr].Used  then  //������������
  begin
  RAM[ChangeAddr,0]:=�hangeData[0];
  RAM[ChangeAddr,1]:=�hangeData[1];
  RAM[ChangeAddr,2]:=�hangeData[2];
  RAM[ChangeAddr,3]:=�hangeData[3];
  RAM[ChangeAddr,4]:=�hangeData[4];
  RAM[ChangeAddr,5]:=�hangeData[5];
  RAM[ChangeAddr,6]:=�hangeData[6];
  RAM[ChangeAddr,7]:=�hangeData[7];

  end
  else
  begin //�� ������������

  end;
end;

function readTSC:int64;
var ts:record
  case byte of
  1:(count:int64);
  2:(b,a:cardinal);
  end;
begin
  asm
    db $F;
    db $31;
    MOV [ts.a],edx;
    MOV [ts.b],eax;
  end;
  readTSC:=ts.count;
end;

function DimensionCPUCyclesPerSecond:int64;
var tmpA,tmpB,tmpC:array[0..9] of int64;
tmpD:int64;
J:byte;
begin
timebeginperiod(1); //������� ������� �������� ����������� ������� �������
sleep(10); //�������� ������-�� ����� ������ ����
tmpD:=0;
for j := 0 to 9 do
  begin
   tmpA[J]:=readTSC;
   sleep(100);
   tmpB[J]:=readTSC;
   tmpC[J]:=tmpB[J]-tmpA[J];
   tmpC[J]:=tmpC[J]*10;
   tmpD:=tmpD+TMPC[J];
  end;
timeEndPeriod(1); //����������� ��������
DimensionCPUCyclesPerSecond:=tmpD div 10;
end;

procedure ChangeRAMBit();  //���. ���������� ChangeBitAddr, ChangeBitNo, ChangeBitData
begin
 RAM[ChangeBitAddr,ChangeBitNo]:=ChangeBitData;

end;


procedure TRun.Execute;
label 10,20, lINCFSZ1, lDECFSZ1,lINCF1,lDECF1;
var
// ��������� ���������� ��� ��������� ASM �������, ����� �������������� � �����, ������ �����������, ���� ����������
tmpByte1,tmpByte2,tmpByte3:byte;
tmpAByte,tmpBByte:array[0..7] of boolean;
tmpW1,tmpW2:Word;
tmpWA:array [0..7] of byte;
tmpBit1,tmpBit2,tmpBit3:boolean;
begin
//! - �� ������
//a - �����, ������� �������� (�� ���� �� �����������)
//a! - �� ���� �� �����������, ������� ������� ��������
//b - ����
//OK - ������

//����� ���������
I:=-1;
IC:=0;
MC:=0;
//����� �����
St1:=0;
St2:=0;
StC:=0;
// �������� ����� ������ �������� - MOVLW 00h
CurrentCommand[11]:=true;
CurrentCommand[10]:=true;
CurrentCommand[9]:=false;
CurrentCommand[8]:=false;
CurrentCommand[7]:=false;
CurrentCommand[6]:=false;
CurrentCommand[5]:=false;
CurrentCommand[4]:=false;
CurrentCommand[3]:=false;
CurrentCommand[2]:=false;
CurrentCommand[1]:=false;
CurrentCommand[0]:=false;
//������� �������� �������������
rtSyncroTMP:=readTSC;
//���������� ��������

goto 20;
10:
//� ������ �������� ��?
if not rtRunning then exit;

//� ����������� �� ������
//Step-By-Step
if rtstepbystep then
  begin
    if not rtexStep then
      begin
        sleep(10);
        goto 10;
      end
      else rtexStep:=false;
  end;

//Delay
if rtWithDelay then
  begin
    sleep(rtDelayMS);
  end;
//�������������
if rtWithSyncro then
  begin
    if readTSC-pic10f.rtSyncroTMP<pic10f.rtCyclPerCycMK*pic10f.rtSyncro  then
      goto  10
      else
        begin
          pic10f.rtSyncroTMP:=trunc(pic10f.rtSyncroTMP+(pic10f.rtCyclPerCycMK/pic10f.rtSyncro)) ;

        end;

  end;
//Pause
if rtpause then
  begin
    sleep(10);
    //������� �������� �������������
    rtSyncroTMP:=readTSC;
    goto 10;
  end;

//��������, � �� ����������� �� ��������?
if I>255 then
begin
//����� �������� ���, ������� �����, ���� ������� ����� ��������� ���-�� ����� ROM - ����������� �����, �...

exit;
end;

IC:=IC+1;
MC:=MC+1;


CurrentCommand[0]:=ROM[I,0];
CurrentCommand[1]:=ROM[I,1];
CurrentCommand[2]:=ROM[I,2];
CurrentCommand[3]:=ROM[I,3];
CurrentCommand[4]:=ROM[I,4];
CurrentCommand[5]:=ROM[I,5];
CurrentCommand[6]:=ROM[I,6];
CurrentCommand[7]:=ROM[I,7];
CurrentCommand[8]:=ROM[I,8];
CurrentCommand[9]:=ROM[I,9];
CurrentCommand[10]:=ROM[I,10];
CurrentCommand[11]:=ROM[I,11];
20: begin
//

  if CurrentCommand[11] then //1XXXXXXXXXXX
  begin
    if currentcommand[10]  then //11XXXXXXXXXX
    begin
      if currentcommand[9] then  //111XXXXXXXXX
      begin
        if currentcommand[8] then  //1111XXXXXXXX
        begin
//bXORLW

        ChangeBitData:=True; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
        // ����� ���� �������� XOR �-� ���������� � ��������� W. ���-� � W. ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
        �hangeData[0]:=RAM[RegW,0] XOR currentcommand[0]; if �hangeData[0] then ChangeBitData:=false;
        �hangeData[1]:=RAM[RegW,1] XOR currentcommand[1]; if �hangeData[1] then ChangeBitData:=false;
        �hangeData[2]:=RAM[RegW,2] XOR currentcommand[2]; if �hangeData[2] then ChangeBitData:=false;
        �hangeData[3]:=RAM[RegW,3] XOR currentcommand[3]; if �hangeData[3] then ChangeBitData:=false;
        �hangeData[4]:=RAM[RegW,4] XOR currentcommand[4]; if �hangeData[4] then ChangeBitData:=false;
        �hangeData[5]:=RAM[RegW,5] XOR currentcommand[5]; if �hangeData[5] then ChangeBitData:=false;
        �hangeData[6]:=RAM[RegW,6] XOR currentcommand[6]; if �hangeData[6] then ChangeBitData:=false;
        �hangeData[7]:=RAM[RegW,7] XOR currentcommand[7]; if �hangeData[7] then ChangeBitData:=false;
        //�������� RAM �� ������ � ������������ � �������
        ChangeAddr:=RegW;
        ChangeRAMByte();
        //�������� ���� Z � Status
        ChangeBitAddr:=3;
        ChangeBitNo:=2;
        ChangeRAMBit;
        //��������� ������� �������, � ��������� ��. ��������.
        I:=I+1;
        PCLpp();
        goto 10;
        end
        else //1110XXXXXXXX
        begin
//bANDLW
        ChangeBitData:=True; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
        // ����� ���� �������� AND �-� ���������� � ��������� W. ���-� � W. ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
        �hangeData[0]:=RAM[RegW,0] AND currentcommand[0]; if �hangeData[0] then ChangeBitData:=false;
        �hangeData[1]:=RAM[RegW,1] AND currentcommand[1]; if �hangeData[1] then ChangeBitData:=false;
        �hangeData[2]:=RAM[RegW,2] AND currentcommand[2]; if �hangeData[2] then ChangeBitData:=false;
        �hangeData[3]:=RAM[RegW,3] AND currentcommand[3]; if �hangeData[3] then ChangeBitData:=false;
        �hangeData[4]:=RAM[RegW,4] AND currentcommand[4]; if �hangeData[4] then ChangeBitData:=false;
        �hangeData[5]:=RAM[RegW,5] AND currentcommand[5]; if �hangeData[5] then ChangeBitData:=false;
        �hangeData[6]:=RAM[RegW,6] AND currentcommand[6]; if �hangeData[6] then ChangeBitData:=false;
        �hangeData[7]:=RAM[RegW,7] AND currentcommand[7]; if �hangeData[7] then ChangeBitData:=false;
        //�������� RAM �� ������ � ������������ � �������
        ChangeAddr:=RegW;
        ChangeRAMByte();
        //�������� ���� Z � Status
        ChangeBitAddr:=3;
        ChangeBitNo:=2;
        ChangeRAMBit;
        //��������� ������� �������, � ��������� ��. ��������.
        I:=I+1;
        PCLpp();
        goto 10;
        end;
      end
      else //110XXXXXXXXX
      begin
        if currentcommand[8] then //1101XXXXXXXX
        begin
//bIORLW
        ChangeBitData:=True; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
        // ����� ���� �������� OR �-� ���������� � ��������� W. ���-� � W. ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
        �hangeData[0]:=RAM[RegW,0] OR currentcommand[0]; if �hangeData[0] then ChangeBitData:=false;
        �hangeData[1]:=RAM[RegW,1] OR currentcommand[1]; if �hangeData[1] then ChangeBitData:=false;
        �hangeData[2]:=RAM[RegW,2] OR currentcommand[2]; if �hangeData[2] then ChangeBitData:=false;
        �hangeData[3]:=RAM[RegW,3] OR currentcommand[3]; if �hangeData[3] then ChangeBitData:=false;
        �hangeData[4]:=RAM[RegW,4] OR currentcommand[4]; if �hangeData[4] then ChangeBitData:=false;
        �hangeData[5]:=RAM[RegW,5] OR currentcommand[5]; if �hangeData[5] then ChangeBitData:=false;
        �hangeData[6]:=RAM[RegW,6] OR currentcommand[6]; if �hangeData[6] then ChangeBitData:=false;
        �hangeData[7]:=RAM[RegW,7] OR currentcommand[7]; if �hangeData[7] then ChangeBitData:=false;
        //�������� RAM �� ������ � ������������ � �������
        ChangeAddr:=RegW;
        ChangeRAMByte();
        //�������� ���� Z � Status
        ChangeBitAddr:=3;
        ChangeBitNo:=2;
        ChangeRAMBit;
        //��������� ������� �������, � ��������� ��. ��������.
        I:=I+1;
        PCLpp();
        goto 10;

        end
        else //1100XXXXXXXX
        begin
//bMOVLW
        �hangeData[0]:=currentcommand[0];
        �hangeData[1]:=currentcommand[1];
        �hangeData[2]:=currentcommand[2];
        �hangeData[3]:=currentcommand[3];
        �hangeData[4]:=currentcommand[4];
        �hangeData[5]:=currentcommand[5];
        �hangeData[6]:=currentcommand[6];
        �hangeData[7]:=currentcommand[7];
        //�������� RAM �� ������ � ������������ � �������
        ChangeAddr:=RegW;
        ChangeRAMByte();
        //��������� ������� �������, PCL � ��������� ��. ��������.
        I:=I+1;
        PCLpp();
        goto 10;
        end;

      end;
    end
    else //10XXXXXXXXXX
      if CurrentCommand[9] then //101XXXXXXXXX
      begin
//bGOTO
      //������� ������� �������� �� ����� � ���������
      I:=0;
      if CurrentCommand[0]=true then I:=I+1;
      if CurrentCommand[1]=true then I:=I+2;
      if CurrentCommand[2]=true then I:=I+4;
      if CurrentCommand[3]=true then I:=I+8;
      if CurrentCommand[4]=true then I:=I+16;
      if CurrentCommand[5]=true then I:=I+32;
      if CurrentCommand[6]=true then I:=I+64;
      if CurrentCommand[7]=true then I:=I+128;
      if CurrentCommand[8]=true then I:=I+256;
      //���  ������ ������ � PCL
      RAM[2,0]:=CurrentCommand[0];
      RAM[2,1]:=CurrentCommand[1];
      RAM[2,2]:=CurrentCommand[2];
      RAM[2,3]:=CurrentCommand[3];
      RAM[2,4]:=CurrentCommand[4];
      RAM[2,5]:=CurrentCommand[5];
      RAM[2,6]:=CurrentCommand[6];
      RAM[2,7]:=CurrentCommand[7];
      //�.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
      pic10f.rtSyncroTMP:=trunc(pic10f.rtSyncroTMP+(pic10f.rtCyclPerCycMK / pic10f.rtSyncro));
      MC:=MC+1;



      goto 10;

      end
      else //100XXXXXXXXX
      begin
        if CurrentCommand[8] then //1001XXXXXXXX
        begin
//bCALL
         //������� ������� �������� �� ����� � ���������
        if StC=2 then
        begin
//��� ����� ����� �������� ���������� ������ - ������������ �����, � ��� ����� ��. ���
        St2:=St1;
        bSt2:=bSt1;
        PCLpp();
        bSt1[0]:=RAM[2,0];
        bSt1[1]:=RAM[2,1];
        bSt1[2]:=RAM[2,2];
        bSt1[3]:=RAM[2,3];
        bSt1[4]:=RAM[2,4];
        bSt1[5]:=RAM[2,5];
        bSt1[6]:=RAM[2,6];
        bSt1[7]:=RAM[2,7];
        St1:=I+1;
        end;
        if StC=1 then
        begin
          StC:=StC+1;
          St2:=St1;
          bSt2:=bSt1;
          PCLpp();
          bSt1[0]:=RAM[2,0];
          bSt1[1]:=RAM[2,1];
          bSt1[2]:=RAM[2,2];
          bSt1[3]:=RAM[2,3];
          bSt1[4]:=RAM[2,4];
          bSt1[5]:=RAM[2,5];
          bSt1[6]:=RAM[2,6];
          bSt1[7]:=RAM[2,7];
          St1:=I+1;
        end;
        if StC=0 then
        begin
          StC:=StC+1;
          PCLpp();
          bSt1[0]:=RAM[2,0];
          bSt1[1]:=RAM[2,1];
          bSt1[2]:=RAM[2,2];
          bSt1[3]:=RAM[2,3];
          bSt1[4]:=RAM[2,4];
          bSt1[5]:=RAM[2,5];
          bSt1[6]:=RAM[2,6];
          bSt1[7]:=RAM[2,7];
          St1:=I+1;
        end;
        I:=0;
        if CurrentCommand[0]=true then I:=I+1;
        if CurrentCommand[1]=true then I:=I+2;
        if CurrentCommand[2]=true then I:=I+4;
        if CurrentCommand[3]=true then I:=I+8;
        if CurrentCommand[4]=true then I:=I+16;
        if CurrentCommand[5]=true then I:=I+32;
        if CurrentCommand[6]=true then I:=I+64;
        if CurrentCommand[7]=true then I:=I+128;
        //���  ������ ������ � PCL
        RAM[2,0]:=CurrentCommand[0];
        RAM[2,1]:=CurrentCommand[1];
        RAM[2,2]:=CurrentCommand[2];
        RAM[2,3]:=CurrentCommand[3];
        RAM[2,4]:=CurrentCommand[4];
        RAM[2,5]:=CurrentCommand[5];
        RAM[2,6]:=CurrentCommand[6];
        RAM[2,7]:=CurrentCommand[7];
        //�.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
        MC:=MC+1;

        goto 10

        end
        else
        begin   //1000XXXXXXXX
//bRETLW
        //����������� ��������� � ������� W
        �hangeData[0]:=currentcommand[0];
        �hangeData[1]:=currentcommand[1];
        �hangeData[2]:=currentcommand[2];
        �hangeData[3]:=currentcommand[3];
        �hangeData[4]:=currentcommand[4];
        �hangeData[5]:=currentcommand[5];
        �hangeData[6]:=currentcommand[6];
        �hangeData[7]:=currentcommand[7];

        //����� �������, �� ������� ����� ����, � ��������� ��� ���������� � I
        if StC=0 then
        begin
//�� - ��� ��� ���������, � ���, ���� ���� ������??
        end;
        if StC=1  then
        begin
          StC:=0;
          I:=St1;
          RAM[2,0]:=bSt1[0];
          RAM[2,1]:=bSt1[1];
          RAM[2,2]:=bSt1[2];
          RAM[2,3]:=bSt1[3];
          RAM[2,4]:=bSt1[4];
          RAM[2,5]:=bSt1[5];
          RAM[2,6]:=bSt1[6];
          RAM[2,7]:=bSt1[7];
          St1:=0;
        end;
        if StC=2 then
        begin
          StC:=1;
          I:=St1;
          RAM[2,0]:=bSt1[0];
          RAM[2,1]:=bSt1[1];
          RAM[2,2]:=bSt1[2];
          RAM[2,3]:=bSt1[3];
          RAM[2,4]:=bSt1[4];
          RAM[2,5]:=bSt1[5];
          RAM[2,6]:=bSt1[6];
          RAM[2,7]:=bSt1[7];
          St1:=St2;
          bSt1:=bSt2;
          St2:=0;
        end;
         //�������� RAM �� ������ � ������������ � �������
        ChangeAddr:=RegW;
        ChangeRAMByte();

        //�.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
        MC:=MC+1;

        goto 10
        end;
      end;
  end
  else
  begin //0XXXXXXXXXXX
    if CurrentCommand[10] then
    begin //01XXXXXXXXXX
      if CurrentCommand[9] then
      begin //011XXXXXXXXX
        if CurrentCommand[8] then
        begin //0111XXXXXXXX
//bBTFSS  0111bbbfffff
        //�������������� fffff � ����� ������
        tmpByte1:=0;
        if currentcommand[0] then tmpByte1:=tmpByte1+1;
        if currentcommand[1] then tmpByte1:=tmpByte1+2;
        if currentcommand[2] then tmpByte1:=tmpByte1+4;
        if currentcommand[3] then tmpByte1:=tmpByte1+8;
        if currentcommand[4] then tmpByte1:=tmpByte1+16;
        //�������������� bbb � ����� ����
        tmpByte2:=0;
        if currentcommand[5] then tmpByte2:=tmpByte2+1;
        if currentcommand[6] then tmpByte2:=tmpByte2+2;
        if currentcommand[7] then tmpByte2:=tmpByte2+4;
//�.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
        if RAM[tmpByte1,tmpByte2] then
          begin
          //��������� ������� �������, PCL � ��������� ��. ��������.
          I:=I+2;
          PCLpp();
          PCLpp();
          goto 10;
          end
          else
          begin
          I:=I+1;
          PCLpp();
          goto 10;
          end;


        end
        else
        begin //0110XXXXXXXX
//bBTFSC 0110bbbfffff
        //�������������� fffff � ����� ������
        tmpByte1:=0;
        if currentcommand[0] then tmpByte1:=tmpByte1+1;
        if currentcommand[1] then tmpByte1:=tmpByte1+2;
        if currentcommand[2] then tmpByte1:=tmpByte1+4;
        if currentcommand[3] then tmpByte1:=tmpByte1+8;
        if currentcommand[4] then tmpByte1:=tmpByte1+16;
        //�������������� bbb � ����� ����
        tmpByte2:=0;
        if currentcommand[5] then tmpByte2:=tmpByte2+1;
        if currentcommand[6] then tmpByte2:=tmpByte2+2;
        if currentcommand[7] then tmpByte2:=tmpByte2+4;
//�.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
        if RAM[tmpByte1,tmpByte2] then
          begin
          //��������� ������� �������, PCL � ��������� ��. ��������.
          I:=I+1;
          PCLpp();
          goto 10;

          end
          else
          begin
          I:=I+2;
          PCLpp();
          PCLpp();
          goto 10;
          end;
        end;
      end
      else
      begin //010XXXXXXXXX
        if CurrentCommand[8] then
        begin //0101XXXXXXXX
//bBSF
        //�������������� fffff � ����� ������
        tmpByte1:=0;
        if currentcommand[0] then tmpByte1:=tmpByte1+1;
        if currentcommand[1] then tmpByte1:=tmpByte1+2;
        if currentcommand[2] then tmpByte1:=tmpByte1+4;
        if currentcommand[3] then tmpByte1:=tmpByte1+8;
        if currentcommand[4] then tmpByte1:=tmpByte1+16;
        //�������������� bbb � ����� ����
        tmpByte2:=0;
        if currentcommand[5] then tmpByte2:=tmpByte2+1;
        if currentcommand[6] then tmpByte2:=tmpByte2+2;
        if currentcommand[7] then tmpByte2:=tmpByte2+4;
//�.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
        //�������� �������� ��������
        ChangeBitData:=true;
        //�������� ����
        ChangeBitAddr:=tmpByte1;
        ChangeBitNo:=tmpByte2;
        ChangeRAMBit;
        //��������� ������� �������, PCL � ��������� ��. ��������.
        I:=I+1;
        PCLpp();
        goto 10;
        end
        else
        begin  //0100XXXXXXXX
//bBCF
        //�������������� fffff � ����� ������
        tmpByte1:=0;
        if currentcommand[0] then tmpByte1:=tmpByte1+1;
        if currentcommand[1] then tmpByte1:=tmpByte1+2;
        if currentcommand[2] then tmpByte1:=tmpByte1+4;
        if currentcommand[3] then tmpByte1:=tmpByte1+8;
        if currentcommand[4] then tmpByte1:=tmpByte1+16;
        //�������������� bbb � ����� ����
        tmpByte2:=0;
        if currentcommand[5] then tmpByte2:=tmpByte2+1;
        if currentcommand[6] then tmpByte2:=tmpByte2+2;
        if currentcommand[7] then tmpByte2:=tmpByte2+4;
//�.�. - ��� ��� ����� �������� ����������, � ���� ����� ��������� � �������������� ������� ��� ����� RAM
        //�������� �������� ��������
        ChangeBitData:=false;
        //�������� ����
        ChangeBitAddr:=tmpByte1;
        ChangeBitNo:=tmpByte2;
        ChangeRAMBit;
        //��������� ������� �������, PCL � ��������� ��. ��������.
        I:=I+1;
        PCLpp();
        goto 10;
        end;
      end;

    end
    else
    begin //00XXXXXXXXXX
      if CurrentCommand[9] then
      begin //001XXXXXXXXX
        if CurrentCommand[8] then
        begin //0011XXXXXXXX
          if CurrentCommand[7] then
          begin //00111XXXXXXX
            if CurrentCommand[6] then
            begin //001111XXXXXX
//bINCFSZ
            //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];
            //�������������� ��������� ������
                if tmpAByte[0]=false then
                begin
                tmpAByte[0]:=true;
                goto lINCFSZ1;
                end
                else
                begin
                tmpAByte[0]:=false;
                  if tmpAByte[1]=false then
                  begin
                  tmpAByte[1]:=true;
                  goto lINCFSZ1;
                  end
                  else
                  begin
                  tmpAByte[1]:=false;
                    if tmpAByte[2]=false then
                    begin
                    tmpAByte[2]:=true;
                    goto lINCFSZ1;
                    end
                    else
                    begin
                    tmpAByte[2]:=false;
                      if tmpAByte[3]=false then
                      begin
                      tmpAByte[3]:=true;
                      goto lINCFSZ1;
                      end
                      else
                      begin
                      tmpAByte[3]:=false;
                        if tmpAByte[4]=false then
                        begin
                        tmpAByte[4]:=true;
                        goto lINCFSZ1;
                        end
                        else
                        begin
                        tmpAByte[4]:=false;
                          if tmpAByte[5]=false then
                          begin
                          tmpAByte[5]:=true;
                          goto lINCFSZ1;
                          end
                          else
                          begin
                          tmpAByte[5]:=false;
                            if tmpAByte[6]=false then
                            begin
                            tmpAByte[6]:=true;
                            goto lINCFSZ1;
                            end
                            else
                            begin
                            tmpAByte[6]:=false;
                              if tmpAByte[7]=false then
                              begin
                              tmpAByte[7]:=true;
                              goto lINCFSZ1;
                              end
                              else
                              begin
                              tmpAByte[7]:=false;
                              //��� ��� ��� ���������� ���, ��� ��������� ����� ����� �� 0
                              //��������������, ���������� ��� �� 1 �.�.(���� ���� 2 �.�., �� ��� ��� ����� GOTO)
                              I:=I+1;
                              //�.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
                              MC:=MC+1;
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
            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
             �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=RegW;
            ChangeRAMByte();
            end;
            // ���������� (���) ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;

            end
            else
            begin //001110XXXXXX
//aSWAPF
             //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];
            //����������, ���� ���� ��������� (��������� �� ��������� ������ B)
            tmpBByte[0]:=tmpAByte[4];
            tmpBByte[1]:=tmpAByte[5];
            tmpBByte[2]:=tmpAByte[6];
            tmpBByte[3]:=tmpAByte[7];
            tmpBByte[4]:=tmpAByte[0];
            tmpBByte[5]:=tmpAByte[1];
            tmpBByte[6]:=tmpAByte[2];
            tmpBByte[7]:=tmpAByte[3];

            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f
             �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=RegW;
            ChangeRAMByte();
            end;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;

            end;

          end
          else
          begin //00110XXXXXXX
            if currentcommand[6] then
            begin //001101XXXXXX
//aRLF
            //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];
            //����������, ���� ���� ��������� (��������� �� ��������� ������ B � ������� �� � STATUS,0 - ���� C)
            tmpBByte[0]:=RAM[3,0];
            tmpBByte[1]:=tmpAByte[0];
            tmpBByte[2]:=tmpAByte[1];
            tmpBByte[3]:=tmpAByte[2];
            tmpBByte[4]:=tmpAByte[3];
            tmpBByte[5]:=tmpAByte[4];
            tmpBByte[6]:=tmpAByte[5];
            tmpBByte[7]:=tmpAByte[6];
            ChangeBitData:=tmpAByte[7];
            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f

            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=RegW;
            ChangeRAMByte();
            end;
            //�������� ���� C � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=0;
            ChangeRAMBit;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;
            end
            else
            begin  //001100XXXXXX
//aRRF
            //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];
            //����������, ���� ���� ��������� (��������� �� ��������� ������ B � ������� �� � STATUS,0 - ���� C)
            tmpBByte[7]:=RAM[3,0];
            tmpBByte[6]:=tmpAByte[7];
            tmpBByte[5]:=tmpAByte[6];
            tmpBByte[4]:=tmpAByte[5];
            tmpBByte[3]:=tmpAByte[4];
            tmpBByte[2]:=tmpAByte[3];
            tmpBByte[1]:=tmpAByte[2];
            tmpBByte[0]:=tmpAByte[1];
            ChangeBitData:=tmpAByte[0];
            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();;
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regw;
            ChangeRAMByte();
            end;
            //�������� ���� C � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=0;
            ChangeRAMBit;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;
            end;
          end;

        end
        else
        begin //0010XXXXXXXX
          if currentcommand[7] then
          begin //00101XXXXXXX
            if currentcommand[6] then
            begin //001011XXXXXX
//a!DECFSZ  - ������� �������� ��������� �������������
             //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];

            //�������������� ��������� ������
                if tmpAByte[0]=true then
                begin
                tmpAByte[0]:=false;
                goto lDECFSZ1;
                end
                else
                begin
                tmpAByte[0]:=true;

                  if tmpAByte[1]=true then
                  begin
                  tmpAByte[1]:=false;
                  goto lDECFSZ1;
                  end
                  else
                  begin
                  tmpAByte[1]:=true;

                    if tmpAByte[2]=true then
                    begin
                    tmpAByte[2]:=false;
                    goto lDECFSZ1;
                    end
                    else
                    begin
                    tmpAByte[2]:=true;

                      if tmpAByte[3]=true then
                      begin
                      tmpAByte[3]:=false;
                      goto lDECFSZ1;
                      end
                      else
                      begin
                      tmpAByte[3]:=true;

                        if tmpAByte[4]=true then
                        begin
                        tmpAByte[4]:=false;
                        goto lDECFSZ1;
                        end
                        else
                        begin
                        tmpAByte[4]:=true;

                          if tmpAByte[5]=true then
                          begin
                          tmpAByte[5]:=false;
                          goto lDECFSZ1;
                          end
                          else
                          begin
                          tmpAByte[5]:=true;

                            if tmpAByte[6]=true then
                            begin
                            tmpAByte[6]:=false;
                            goto lDECFSZ1;
                            end
                            else
                            begin
                            tmpAByte[6]:=true;

                              if tmpAByte[7]=true then
                              begin
                              tmpAByte[7]:=false;
                              goto lDECFSZ1;
                              end
                              else
                              begin
                              tmpAByte[7]:=true;

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

            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f
             �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();;
            end
            else
            begin //��� ������ � ������� W
             �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //���������, � �� ����� �� �������� ��������� ����?
            if   not �hangeData[0] and not �hangeData[1] and not �hangeData[2] and not �hangeData[3] and not �hangeData[4] and not �hangeData[5] and not �hangeData[6] and not �hangeData[7] then
            begin
            //��� ��� ��� ���������� ���, ��� ��������� ����� ����� �� 0
                              //��������������, ���������� ��� �� 1 �.�.(���� ���� 2 �.�., �� ��� ��� ����� GOTO)
                              I:=I+1;
                              //�.�. �������� ����������� �� 2 �.�., �� ��������� 1 �.�. � ������ ���������� �� 1
                              MC:=MC+1;
                              PCLpp();
            end;
            // ���������� (���) ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;
            end
            else
            begin //001010XXXXXX
//a!INCF   - ����������� ��������� ��������� ����� Z
            //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];
            ChangeBitData:=false; //������ Z �����, �� ������ ���� ���-� �������� �� ����� ����� 0
            //�������������� ��������� ������
                if tmpAByte[0]=false then
                begin
                tmpAByte[0]:=true;
                goto lINCF1;
                end
                else
                begin
                tmpAByte[0]:=false;
                  if tmpAByte[1]=false then
                  begin
                  tmpAByte[1]:=true;
                  goto lINCF1;
                  end
                  else
                  begin
                  tmpAByte[1]:=false;
                    if tmpAByte[2]=false then
                    begin
                    tmpAByte[2]:=true;
                    goto lINCF1;
                    end
                    else
                    begin
                    tmpAByte[2]:=false;
                      if tmpAByte[3]=false then
                      begin
                      tmpAByte[3]:=true;
                      goto lINCF1;
                      end
                      else
                      begin
                      tmpAByte[3]:=false;
                        if tmpAByte[4]=false then
                        begin
                        tmpAByte[4]:=true;
                        goto lINCF1;
                        end
                        else
                        begin
                        tmpAByte[4]:=false;
                          if tmpAByte[5]=false then
                          begin
                          tmpAByte[5]:=true;
                          goto lINCF1;
                          end
                          else
                          begin
                          tmpAByte[5]:=false;
                            if tmpAByte[6]=false then
                            begin
                            tmpAByte[6]:=true;
                            goto lINCF1;
                            end
                            else
                            begin
                            tmpAByte[6]:=false;
                              if tmpAByte[7]=false then
                              begin
                              tmpAByte[7]:=true;
                              goto lINCF1;
                              end
                              else
                              begin
                              tmpAByte[7]:=false;
                              //��� ��� ��� ���������� ���, ��� ��������� ����� ����� �� 0
                              //������������� ���� Z
                              ChangeBitData:=true;
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
            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f
             �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();;
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
              //�������� ���� Z � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            // C�������� ���������� - �� ������� ���������
            I:=I+1;
            PCLpp();
            goto 10;
            end
          end
          else
          begin //00100XXXXXXX
            if currentcommand[5] then
            begin //001001XXXXXX
//aCOMF
            //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];
            ChangeBitData:=true; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            //����������, ���� ��������
            if tmpAByte[0] then
              begin
              tmpBByte[0]:=false;
              end
              else
              begin
              tmpBByte[0]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            if tmpAByte[1] then
              begin
              tmpBByte[1]:=false;
              end
              else
              begin
              tmpBByte[1]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            if tmpAByte[2] then
              begin
              tmpBByte[2]:=false;
              end
              else
              begin
              tmpBByte[2]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            if tmpAByte[3] then
              begin
              tmpBByte[3]:=false;
              end
              else
              begin
              tmpBByte[3]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            if tmpAByte[4] then
              begin
              tmpBByte[4]:=false;
              end
              else
              begin
              tmpBByte[4]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            if tmpAByte[5] then
              begin
              tmpBByte[5]:=false;
              end
              else
              begin
              tmpBByte[5]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            if tmpAByte[6] then
              begin
              tmpBByte[6]:=false;
              end
              else
              begin
              tmpBByte[6]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            if tmpAByte[7] then
              begin
              tmpBByte[7]:=false;
              end
              else
              begin
              tmpBByte[7]:=true;
              ChangeBitData:=false; //������ Z �����
              end;
            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpbyte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //�������� ���� Z � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;

            end
            else
            begin //001000XXXXXX
//aMOVF
            //����������� � f
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //��������� f �� ��������� ������
            tmpAByte[0]:=RAM[tmpByte1,0];
            tmpAByte[1]:=RAM[tmpByte1,1];
            tmpAByte[2]:=RAM[tmpByte1,2];
            tmpAByte[3]:=RAM[tmpByte1,3];
            tmpAByte[4]:=RAM[tmpByte1,4];
            tmpAByte[5]:=RAM[tmpByte1,5];
            tmpAByte[6]:=RAM[tmpByte1,6];
            tmpAByte[7]:=RAM[tmpByte1,7];
            ChangeBitData:=true;; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            //�������� �� ���� Z
            if tmpAByte[0]=true then ChangeBitData:=true;;
            if tmpAByte[1]=true then ChangeBitData:=true;;
            if tmpAByte[2]=true then ChangeBitData:=true;;
            if tmpAByte[3]=true then ChangeBitData:=true;;
            if tmpAByte[4]=true then ChangeBitData:=true;;
            if tmpAByte[5]=true then ChangeBitData:=true;;
            if tmpAByte[6]=true then ChangeBitData:=true;;
            if tmpAByte[7]=true then ChangeBitData:=true;;

            //�������� ��� � ����� ����������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpbyte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpAByte[0];
            �hangeData[1]:=tmpAByte[1];
            �hangeData[2]:=tmpAByte[2];
            �hangeData[3]:=tmpAByte[3];
            �hangeData[4]:=tmpAByte[4];
            �hangeData[5]:=tmpAByte[5];
            �hangeData[6]:=tmpAByte[6];
            �hangeData[7]:=tmpAByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //�������� ���� Z � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;

            end;
          end;
        end;

      end
      else
      begin //000XXXXXXXXX
        if currentcommand[8] then
        begin //0001XXXXXXXX
          if currentcommand[7] then
          begin  //00011XXXXXXX
            if currentcommand[6] then
            begin //000111XXXXXX
//aADDWF   - ��� ���� �������� ��������� W � f
             //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //���� ��������� ��������
            tmpBit1:=true; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            tmpByte2:=0;
            if RAM[RegW,0] then inc(tmpByte2);
            if RAM[tmpByte1,0] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[0]:=false;
              tmpAByte[0]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[0]:=true;
                    tmpAByte[0]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[0]:=false;
                        tmpAByte[0]:=true;
                      end
                      else
                      begin
                        tmpBByte[0]:=true;
                        tmpAByte[0]:=true;
                        tmpBit1:=false;
                      end;
            tmpByte2:=0;
            if RAM[RegW,1] then inc(tmpByte2);
            if RAM[tmpByte1,1] then inc(tmpByte2);
            if tmpAByte[0] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[1]:=false;
              tmpAByte[1]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[1]:=true;
                    tmpAByte[1]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[1]:=false;
                        tmpAByte[1]:=true;
                      end
                      else
                      begin
                        tmpBByte[1]:=true;
                        tmpAByte[1]:=true;
                        tmpBit1:=false;
                      end;
            tmpByte2:=0;
            if RAM[RegW,2] then inc(tmpByte2);
            if RAM[tmpByte1,2] then inc(tmpByte2);
            if tmpAByte[1] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[2]:=false;
              tmpAByte[2]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[2]:=true;
                    tmpAByte[2]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[2]:=false;
                        tmpAByte[2]:=true;
                      end
                      else
                      begin
                        tmpBByte[2]:=true;
                        tmpAByte[2]:=true;
                        tmpBit1:=false;
                      end;
            tmpByte2:=0;
            if RAM[RegW,3] then inc(tmpByte2);
            if RAM[tmpByte1,3] then inc(tmpByte2);
            if tmpAByte[2] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[3]:=false;
              tmpAByte[3]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[3]:=true;
                    tmpAByte[3]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[3]:=false;
                        tmpAByte[3]:=true;
                      end
                      else
                      begin
                        tmpBByte[3]:=true;
                        tmpAByte[3]:=true;
                        tmpBit1:=false;
                      end;
            tmpByte2:=0;
            if RAM[RegW,4] then inc(tmpByte2);
            if RAM[tmpByte1,4] then inc(tmpByte2);
            if tmpAByte[3] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[4]:=false;
              tmpAByte[4]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[4]:=true;
                    tmpAByte[4]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[4]:=false;
                        tmpAByte[4]:=true;
                      end
                      else
                      begin
                        tmpBByte[4]:=true;
                        tmpAByte[4]:=true;
                        tmpBit1:=false;
                      end;
            tmpByte2:=0;
            if RAM[RegW,5] then inc(tmpByte2);
            if RAM[tmpByte1,5] then inc(tmpByte2);
            if tmpAByte[4] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[5]:=false;
              tmpAByte[5]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[5]:=true;
                    tmpAByte[5]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[5]:=false;
                        tmpAByte[5]:=true;
                      end
                      else
                      begin
                        tmpBByte[5]:=true;
                        tmpAByte[5]:=true;
                        tmpBit1:=false;
                      end;
            tmpByte2:=0;
            if RAM[RegW,6] then inc(tmpByte2);
            if RAM[tmpByte1,6] then inc(tmpByte2);
            if tmpAByte[5] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[6]:=false;
              tmpAByte[6]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[6]:=true;
                    tmpAByte[6]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[6]:=false;
                        tmpAByte[6]:=true;
                      end
                      else
                      begin
                        tmpBByte[6]:=true;
                        tmpAByte[6]:=true;
                        tmpBit1:=false;
                      end;
            tmpByte2:=0;
            if RAM[RegW,7] then inc(tmpByte2);
            if RAM[tmpByte1,7] then inc(tmpByte2);
            if tmpAByte[6] then inc(tmpByte2);
            if tmpByte2=0 then
              begin
              tmpBByte[7]:=false;
              tmpAByte[7]:=false;
              end
              else
                if tmpByte2=1  then
                  begin
                    tmpBByte[7]:=true;
                    tmpAByte[7]:=false;
                    tmpBit1:=false;
                  end
                  else
                    if tmpByte2=2 then
                      begin
                        tmpBByte[7]:=false;
                        tmpAByte[7]:=true;
                      end
                      else
                      begin
                        tmpBByte[7]:=true;
                        tmpAByte[7]:=true;
                        tmpBit1:=false;
                      end;

            //��������� �������� �����������, ������ ��������� ����� �� ����� ��������
            tmpBit2:=tmpAByte[7];//������� ����� C
            tmpBit3:=tmpAByte[3]; //������� ����� DC
            //������ ��������� ���������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regw;
            ChangeRAMByte();
            end;
            //������� ���� Z
            ChangeBitData:=tmpBit1;
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            //������� ���� C
            ChangeBitData:=tmpBit2;
            ChangeBitAddr:=3;
            ChangeBitNo:=0;
            ChangeRAMBit;
            //������� ���� DC
            ChangeBitData:=tmpBit3;
            ChangeBitAddr:=3;
            ChangeBitNo:=1;
            ChangeRAMBit;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;
            end
            else
            begin //000110XXXXXX
//aXORWF
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            ChangeBitData:=true; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            // ����� ���� �������� XOR �-� ��������� f � ��������� W.  ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
            tmpBByte[0]:=RAM[RegW,0] XOR RAM[tmpByte1,0]; if tmpBByte[0] then ChangeBitData:=false;
            tmpBByte[1]:=RAM[RegW,1] XOR RAM[tmpByte1,1]; if tmpBByte[1] then ChangeBitData:=false;
            tmpBByte[2]:=RAM[RegW,2] XOR RAM[tmpByte1,2]; if tmpBByte[2] then ChangeBitData:=false;
            tmpBByte[3]:=RAM[RegW,3] XOR RAM[tmpByte1,3]; if tmpBByte[3] then ChangeBitData:=false;
            tmpBByte[4]:=RAM[RegW,4] XOR RAM[tmpByte1,4]; if tmpBByte[4] then ChangeBitData:=false;
            tmpBByte[5]:=RAM[RegW,5] XOR RAM[tmpByte1,5]; if tmpBByte[5] then ChangeBitData:=false;
            tmpBByte[6]:=RAM[RegW,6] XOR RAM[tmpByte1,6]; if tmpBByte[6] then ChangeBitData:=false;
            tmpBByte[7]:=RAM[RegW,7] XOR RAM[tmpByte1,7]; if tmpBByte[7] then ChangeBitData:=false;
            //������ ��������� ���������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpbyte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //�������� ���� Z � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            //��������� ������� �������, � ��������� ��. ��������.
            I:=I+1;
            PCLpp();
            goto 10;
            end;
          end
          else
          begin  //00010XXXXXXX
          if currentcommand[6] then
            begin  //000101XXXXXX
//aANDWF
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            ChangeBitData:=true;; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            // ����� ���� �������� XOR �-� ��������� f � ��������� W.  ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
            tmpBByte[0]:=RAM[RegW,0] AND RAM[tmpByte1,0]; if tmpBByte[0] then ChangeBitData:=false;
            tmpBByte[1]:=RAM[RegW,1] AND RAM[tmpByte1,1]; if tmpBByte[1] then ChangeBitData:=false;
            tmpBByte[2]:=RAM[RegW,2] AND RAM[tmpByte1,2]; if tmpBByte[2] then ChangeBitData:=false;
            tmpBByte[3]:=RAM[RegW,3] AND RAM[tmpByte1,3]; if tmpBByte[3] then ChangeBitData:=false;
            tmpBByte[4]:=RAM[RegW,4] AND RAM[tmpByte1,4]; if tmpBByte[4] then ChangeBitData:=false;
            tmpBByte[5]:=RAM[RegW,5] AND RAM[tmpByte1,5]; if tmpBByte[5] then ChangeBitData:=false;
            tmpBByte[6]:=RAM[RegW,6] AND RAM[tmpByte1,6]; if tmpBByte[6] then ChangeBitData:=false;
            tmpBByte[7]:=RAM[RegW,7] AND RAM[tmpByte1,7]; if tmpBByte[7] then ChangeBitData:=false;
            //������ ��������� ���������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpbyte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //�������� ���� Z � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            //��������� ������� �������, � ��������� ��. ��������.
            I:=I+1;
            PCLpp();
            goto 10;
            end
            else
            begin  //000100XXXXXX
//aIORWF
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            ChangeBitData:=true; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            // ����� ���� �������� XOR �-� ��������� f � ��������� W.  ���� ���� ���� ��� �� ����� 0, �� ������������ ���� Z
            tmpBByte[0]:=RAM[RegW,0] OR RAM[tmpByte1,0]; if tmpBByte[0] then ChangeBitData:=false;
            tmpBByte[1]:=RAM[RegW,1] OR RAM[tmpByte1,1]; if tmpBByte[1] then ChangeBitData:=false;
            tmpBByte[2]:=RAM[RegW,2] OR RAM[tmpByte1,2]; if tmpBByte[2] then ChangeBitData:=false;
            tmpBByte[3]:=RAM[RegW,3] OR RAM[tmpByte1,3]; if tmpBByte[3] then ChangeBitData:=false;
            tmpBByte[4]:=RAM[RegW,4] OR RAM[tmpByte1,4]; if tmpBByte[4] then ChangeBitData:=false;
            tmpBByte[5]:=RAM[RegW,5] OR RAM[tmpByte1,5]; if tmpBByte[5] then ChangeBitData:=false;
            tmpBByte[6]:=RAM[RegW,6] OR RAM[tmpByte1,6]; if tmpBByte[6] then ChangeBitData:=false;
            tmpBByte[7]:=RAM[RegW,7] OR RAM[tmpByte1,7]; if tmpBByte[7] then ChangeBitData:=false;
            //������ ��������� ���������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpByte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //�������� ���� Z � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            //��������� ������� �������, � ��������� ��. ��������.
            I:=I+1;
            PCLpp();
            goto 10;
            end;
          end;


        end
        else
        begin //0000XXXXXXXX
          if CurrentCommand[7] then
          begin //00001XXXXXXX
            if CurrentCommand[6] then
            begin //000011XXXXXX
//aDECF
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //���� ��������� ���������
            ChangeBitData:=true; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            tmpByte2:=1;
            if RAM[tmpByte1,0] then inc(tmpByte2);
                if tmpByte2=2  then
                  begin
                    tmpAByte[0]:=false;
                    tmpBByte[0]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[0]:=true;
                        tmpAByte[0]:=true;
                        ChangeBitData:=false;
                      end;
            tmpByte2:=2;
            if RAM[tmpByte1,1] then inc(tmpByte2);
            if tmpAByte[0] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[1]:=true;
              tmpAByte[1]:=false;
              ChangeBitData:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[1]:=false;
                    tmpBByte[1]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[1]:=true;
                        tmpAByte[1]:=true;
                        ChangeBitData:=false;
                      end;
            tmpByte2:=2;
            if RAM[tmpByte1,2] then inc(tmpByte2);
            if tmpAByte[1] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[2]:=true;
              tmpAByte[2]:=false;
              ChangeBitData:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[2]:=false;
                    tmpBByte[2]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[2]:=true;
                        tmpAByte[2]:=true;
                        ChangeBitData:=false;
                      end;
            tmpByte2:=2;
            if RAM[tmpByte1,3] then inc(tmpByte2);
            if tmpAByte[2] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[3]:=true;
              tmpAByte[3]:=false;
              ChangeBitData:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[3]:=false;
                    tmpBByte[3]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[3]:=true;
                        tmpAByte[3]:=true;
                        ChangeBitData:=false;
                      end;
            tmpByte2:=2;
            if RAM[tmpByte1,4] then inc(tmpByte2);
            if tmpAByte[3] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[4]:=true;
              tmpAByte[4]:=false;
              ChangeBitData:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[4]:=false;
                    tmpBByte[4]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[4]:=true;
                        tmpAByte[4]:=true;
                        ChangeBitData:=false;
                      end;
            tmpByte2:=2;
            if RAM[tmpByte1,5] then inc(tmpByte2);
            if tmpAByte[4] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[5]:=true;
              tmpAByte[5]:=false;
              ChangeBitData:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[5]:=false;
                    tmpBByte[5]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[5]:=true;
                        tmpAByte[5]:=true;
                        ChangeBitData:=false;
                      end;
            tmpByte2:=2;
            if RAM[tmpByte1,6] then inc(tmpByte2);
            if tmpAByte[5] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[6]:=true;
              tmpAByte[6]:=false;
              ChangeBitData:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[6]:=false;
                    tmpBByte[6]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[6]:=true;
                        tmpAByte[6]:=true;
                        ChangeBitData:=false;
                      end;
            tmpByte2:=2;
            if RAM[tmpByte1,7] then inc(tmpByte2);
            if tmpAByte[6] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[7]:=true;
              tmpAByte[7]:=false;
              ChangeBitData:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[7]:=false;
                    tmpBByte[7]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[7]:=true;
                        tmpAByte[7]:=true;
                        ChangeBitData:=false;
                      end;
            //������ ��������� ���������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpbyte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //�������� ���� Z � Status
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;
            end
            else
            begin //000010XXXXXX
//bSUBWF
            //�������������� fffff � ����� ������
            tmpByte1:=0;
            if currentcommand[0] then tmpByte1:=tmpByte1+1;
            if currentcommand[1] then tmpByte1:=tmpByte1+2;
            if currentcommand[2] then tmpByte1:=tmpByte1+4;
            if currentcommand[3] then tmpByte1:=tmpByte1+8;
            if currentcommand[4] then tmpByte1:=tmpByte1+16;
            //���� ��������� ���������
            tmpbit1:=true; //��������� Z �����, �� ������ ���� ���-� �������� ����� ����� 0
            tmpByte2:=2;
            if RAM[RegW,0] then DEC(tmpByte2);
            if RAM[tmpByte1,0] then inc(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[0]:=true;
              tmpAByte[0]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[0]:=false;
                    tmpBByte[0]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[0]:=true;
                        tmpAByte[0]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[0]:=false;
                        tmpAByte[0]:=true;
                      end;
            tmpByte2:=2;
            if RAM[RegW,1] then DEC(tmpByte2);
            if RAM[tmpByte1,1] then inc(tmpByte2);
            if tmpAByte[0] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[1]:=true;
              tmpAByte[1]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[1]:=false;
                    tmpBByte[1]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[1]:=true;
                        tmpAByte[1]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[1]:=false;
                        tmpAByte[1]:=true;
                      end;
            tmpByte2:=2;
            if RAM[RegW,2] then DEC(tmpByte2);
            if RAM[tmpByte1,2] then inc(tmpByte2);
            if tmpAByte[1] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[2]:=true;
              tmpAByte[2]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[2]:=false;
                    tmpBByte[2]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[2]:=true;
                        tmpAByte[2]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[2]:=false;
                        tmpAByte[2]:=true;
                      end;
            tmpByte2:=2;
            if RAM[RegW,3] then DEC(tmpByte2);
            if RAM[tmpByte1,3] then inc(tmpByte2);
            if tmpAByte[2] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[3]:=true;
              tmpAByte[3]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[3]:=false;
                    tmpBByte[3]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[3]:=true;
                        tmpAByte[3]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[3]:=false;
                        tmpAByte[3]:=true;
                      end;
            tmpByte2:=2;
            if RAM[RegW,4] then DEC(tmpByte2);
            if RAM[tmpByte1,4] then inc(tmpByte2);
            if tmpAByte[3] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[4]:=true;
              tmpAByte[4]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[4]:=false;
                    tmpBByte[4]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[4]:=true;
                        tmpAByte[4]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[4]:=false;
                        tmpAByte[4]:=true;
                      end;
            tmpByte2:=2;
            if RAM[RegW,5] then DEC(tmpByte2);
            if RAM[tmpByte1,5] then inc(tmpByte2);
            if tmpAByte[4] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[5]:=true;
              tmpAByte[5]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[5]:=false;
                    tmpBByte[5]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[5]:=true;
                        tmpAByte[5]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[5]:=false;
                        tmpAByte[5]:=true;
                      end;
            tmpByte2:=2;
            if RAM[RegW,6] then DEC(tmpByte2);
            if RAM[tmpByte1,6] then inc(tmpByte2);
            if tmpAByte[5] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[6]:=true;
              tmpAByte[6]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[6]:=false;
                    tmpBByte[6]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[6]:=true;
                        tmpAByte[6]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[6]:=false;
                        tmpAByte[6]:=true;
                      end;
                        tmpByte2:=2;
            if RAM[RegW,7] then DEC(tmpByte2);
            if RAM[tmpByte1,7] then inc(tmpByte2);
            if tmpAByte[6] then DEC(tmpByte2);
            if tmpByte2=3 then
              begin
              tmpBByte[7]:=true;
              tmpAByte[7]:=false;
              tmpbit1:=false;
              end
              else
                if tmpByte2=2  then
                  begin
                    tmpAByte[7]:=false;
                    tmpBByte[7]:=false;
                  end
                  else
                    if tmpByte2=1 then
                      begin
                        tmpBByte[7]:=true;
                        tmpAByte[7]:=true;
                        tmpbit1:=false;
                      end
                      else
                      begin
                        tmpBByte[7]:=false;
                        tmpAByte[7]:=true;
                      end;

            //��������� ������ �����������, ������ ��������� ����� �� ����� ��������
            tmpbit2:=not tmpAByte[7];//������� ����� C
//�� � ����� DC
            tmpbit3:=not tmpAByte[3]; //������� ����� DC
            //������ ��������� ���������
            if currentcommand[5] then
            begin //��� ������ � ������� f
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=tmpbyte1;
            ChangeRAMByte();
            end
            else
            begin //��� ������ � ������� W
            �hangeData[0]:=tmpBByte[0];
            �hangeData[1]:=tmpBByte[1];
            �hangeData[2]:=tmpBByte[2];
            �hangeData[3]:=tmpBByte[3];
            �hangeData[4]:=tmpBByte[4];
            �hangeData[5]:=tmpBByte[5];
            �hangeData[6]:=tmpBByte[6];
            �hangeData[7]:=tmpBByte[7];

            //�������� RAM �� ������ � ������������ � �������
            ChangeAddr:=regW;
            ChangeRAMByte();
            end;
            //�������� ���� Z � Status
            ChangeBitData:=tmpbit1;
            ChangeBitAddr:=3;
            ChangeBitNo:=2;
            ChangeRAMBit;
            //�������� ���� C � Status
            ChangeBitData:=tmpbit2;
            ChangeBitAddr:=3;
            ChangeBitNo:=0;
            ChangeRAMBit;
            //�������� ���� DC � Status
            ChangeBitData:=tmpbit3;
            ChangeBitAddr:=3;
            ChangeBitNo:=1;
            ChangeRAMBit;
            // ����������  ��� �� 1 �.�.
            I:=I+1;
            PCLpp();
            goto 10;
            end;


          end
          else
          begin //00000XXXXXXX
            if CurrentCommand[6] then
            begin //000001XXXXXX
              if CurrentCommand[5] then
              begin //0000011XXXXX
//aCLRF
              //�������������� fffff � ����� ������
              tmpByte1:=0;
              if currentcommand[0] then tmpByte1:=tmpByte1+1;
              if currentcommand[1] then tmpByte1:=tmpByte1+2;
              if currentcommand[2] then tmpByte1:=tmpByte1+4;
              if currentcommand[3] then tmpByte1:=tmpByte1+8;
              if currentcommand[4] then tmpByte1:=tmpByte1+16;
              //���� ��������� �������
              ChangeBitData:=true; //��������� Z �����, ������ ����� ���������� � ���� ����
              �hangeData[0]:=false;
              �hangeData[1]:=false;
              �hangeData[2]:=false;
              �hangeData[3]:=false;
              �hangeData[4]:=false;
              �hangeData[5]:=false;
              �hangeData[6]:=false;
              �hangeData[7]:=false;
              //�������� RAM �� ������ � ������������ � �������
              ChangeAddr:=tmpByte1;
              ChangeRAMByte();
              //�������� ���� Z � Status
              ChangeBitAddr:=3;
              ChangeBitNo:=2;
              ChangeRAMBit;
              // ����������  ��� �� 1 �.�.
              I:=I+1;
              PCLpp();
              goto 10;
              end
              else
              begin //0000010XXXXX
//aCLRW
              ChangeBitData:=true; //��������� Z �����, ������ ����� ���������� � ���� ����
              �hangeData[0]:=false;
              �hangeData[1]:=false;
              �hangeData[2]:=false;
              �hangeData[3]:=false;
              �hangeData[4]:=false;
              �hangeData[5]:=false;
              �hangeData[6]:=false;
              �hangeData[7]:=false;
              //�������� RAM �� ������ � ������������ � �������
              ChangeAddr:=regW;
              ChangeRAMByte();
              //�������� ���� Z � Status
              ChangeBitAddr:=3;
              ChangeBitNo:=2;
              ChangeRAMBit;
               // ����������  ��� �� 1 �.�.
              I:=I+1;
              PCLpp();
              goto 10;
              end;
            end
            else
            begin //000000XXXXXX
              if CurrentCommand[5] then
              begin //0000001XXXXX
//aMOVWF
              //�������������� fffff � ����� ������
              tmpByte1:=0;
              if currentcommand[0] then tmpByte1:=tmpByte1+1;
              if currentcommand[1] then tmpByte1:=tmpByte1+2;
              if currentcommand[2] then tmpByte1:=tmpByte1+4;
              if currentcommand[3] then tmpByte1:=tmpByte1+8;
              if currentcommand[4] then tmpByte1:=tmpByte1+16;
              //���� ��������� �������� W->f
              �hangeData[0]:=RAM[RegW,0];
              �hangeData[1]:=RAM[RegW,1];
              �hangeData[2]:=RAM[RegW,2];
              �hangeData[3]:=RAM[RegW,3];
              �hangeData[4]:=RAM[RegW,4];
              �hangeData[5]:=RAM[RegW,5];
              �hangeData[6]:=RAM[RegW,6];
              �hangeData[7]:=RAM[RegW,7];
              //�������� RAM �� ������ � ������������ � �������
              ChangeAddr:=tmpByte1;
              ChangeRAMByte();
              // ����������  ��� �� 1 �.�.
              I:=I+1;
              PCLpp();
              goto 10;
              end
              else
              begin //0000000XXXXX
                if CurrentCommand[4] then
                begin //00000001XXXX
                //Unknow command
                end
                else
                begin //00000000XXXX
                  if CurrentCommand[3] then
                  begin //000000001XXX
                  //Unknow command
                  end
                  else
                  begin //000000000XXX
                    if CurrentCommand[2] then
                    begin //0000000001XX
                      if CurrentCommand[1] then
                      begin //00000000011X
                        if CurrentCommand[0] then
                          begin //000000000111
//!TRIS 7  - PORT?    //Unknow command
                          end
                          else
                          begin  //000000000110
//aTRIS 6
                          tmpBit1:=RAM[RegW,0];
                          tmpBit2:=RAM[RegW,1];
                          tmpBit3:=RAM[RegW,2];
                          //�������� �����
                          ChangeBitData:=tmpBit1;
                          ChangeBitAddr:=regTRISGPI0;
                          ChangeBitNo:=0;
                          ChangeRAMBit;
                          ChangeBitData:=tmpBit2;
                          ChangeBitAddr:=regTRISGPI0;
                          ChangeBitNo:=1;
                          ChangeRAMBit;
                          ChangeBitData:=tmpBit3;
                          ChangeBitAddr:=regTRISGPI0;
                          ChangeBitNo:=2;
                          ChangeRAMBit;
                          // ����������  ��� �� 1 �.�.
                           I:=I+1;
                            PCLpp();
                              goto 10;
                          end;
                      end
                      else
                      begin //00000000010X
                        if CurrentCommand[0] then
                        begin //000000000101
//!TRIS 5 - PORT?    //Unknow command
                        end
                        else
                        begin //000000000100
//!CLRWDT
                        end;




                      end;

                    end
                    else
                    begin //0000000000XX
                      if CurrentCommand[1] then
                      begin //00000000001X
                        if CurrentCommand[0] then
                        Begin //000000000011
//!Sleep
                        End
                        else
                        begin //000000000010
//aOPTION
                        �hangeData[0]:=RAM[RegW,0];
                        �hangeData[1]:=RAM[RegW,1];
                        �hangeData[2]:=RAM[RegW,2];
                        �hangeData[3]:=RAM[RegW,3];
                        �hangeData[4]:=RAM[RegW,4];
                        �hangeData[5]:=RAM[RegW,5];
                        �hangeData[6]:=RAM[RegW,6];
                        �hangeData[7]:=RAM[RegW,7];
                         //�������� RAM �� ������ � ������������ � �������
                        ChangeAddr:=regoption;
                        ChangeRAMByte();
                         // ����������  ��� �� 1 �.�.
                           I:=I+1;
                            PCLpp();
                              goto 10;
                        end;

                      end
                      else
                      begin //00000000000X
                        if CurrentCommand[0] then
                        Begin //000000000001
                        //Unknow command
                        End
                        else
                        begin //000000000000
//aNOP
                        // ����������  ��� �� 1 �.�.
                           I:=I+1;
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
Function BinToHex():string;
var L,H:string[1];
begin
//LOW
  if par[0] then
  begin //XXX1
    if par[1] then
    begin //XX11
      if par[2] then
      begin //X111
        if par[3] then //1111
        L:='F'
        else  //0111
        L:='7';
      end
      else
      begin  //X011
         if par[3] then //1011
         L:='B'
         else //0011
         L:='3';
      end;
    end
    else
    begin //XX01
      if par[2] then
      begin //X101
        if par[3] then //1101
        L:='D'
        else  //0101
        L:='5';
      end
      else
      begin  //X001
         if par[3] then //1001
         L:='9'
         else //0001
         L:='1';
      end;
    end;
  end
  else
  begin //XXX0
  if par[1] then
    begin //XX10
      if par[2] then
      begin //X110
        if par[3] then //1110
        L:='E'
        else  //0110
        L:='6';
      end
      else
      begin  //X010
         if par[3] then //1010
         L:='A'
         else //0010
         L:='2';
      end;
    end
    else
    begin //XX00
      if par[2] then
      begin //X100
        if par[3] then //1100
        L:='C'
        else  //0100
        L:='4';
      end
      else
      begin  //X000
         if par[3] then //1000
         L:='8'
         else //0000
         L:='0';
      end;
    end;
  end;

  //HIGHT

   if par[4] then
  begin //XXX1
    if par[5] then
    begin //XX11
      if par[6] then
      begin //X111
        if par[7] then //1111
        H:='F'
        else  //0111
        H:='7';
      end
      else
      begin  //X011
         if par[7] then //1011
         H:='B'
         else //0011
         H:='3';
      end;
    end
    else
    begin //XX01
      if par[6] then
      begin //X101
        if par[7] then //1101
        H:='D'
        else  //0101
        H:='5';
      end
      else
      begin  //X001
         if par[7] then //1001
         H:='9'
         else //0001
         H:='1';
      end;
    end;
  end
  else
  begin //XXX0
  if par[5] then
    begin //XX10
      if par[6] then
      begin //X110
        if par[7] then //1110
        H:='E'
        else  //0110
        H:='6';
      end
      else
      begin  //X010
         if par[7] then //1010
         H:='A'
         else //0010
         H:='2';
      end;
    end
    else
    begin //XX00
      if par[6] then
      begin //X100
        if par[7] then //1100
        H:='C'
        else  //0100
        H:='4';
      end
      else
      begin  //X000
         if par[7] then //1000
         H:='8'
         else //0000
         H:='0';
      end;
    end;
  end;
if par[8] then result:='1'+H+L else result:=H+L;
end;

function GetInstruction():String;
var
tmpByte1:byte;
begin
//

  if parCommand[11] then //1XXXXXXXXXXX
  begin
    if parCommand[10]  then //11XXXXXXXXXX
    begin
      if parCommand[9] then  //111XXXXXXXXX
      begin
        if parCommand[8] then  //1111XXXXXXXX
        begin
//XORLW k(8)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=parCommand[5];
        par[6]:=parCommand[6];
        par[7]:=parCommand[7];
        par[8]:=false;
        result:='XORLW ' + BinToHex() + 'h';
        end
        else //1110XXXXXXXX
        begin
//ANDLW k(8)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=parCommand[5];
        par[6]:=parCommand[6];
        par[7]:=parCommand[7];
        par[8]:=false;
        result:='ANDLW ' + BinToHex() + 'h';
        end;
      end
      else //110XXXXXXXXX
      begin
        if parCommand[8] then //1101XXXXXXXX
        begin
//IORLW k(8)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=parCommand[5];
        par[6]:=parCommand[6];
        par[7]:=parCommand[7];
        par[8]:=false;
        result:='IORLW ' + BinToHex() + 'h';
        end
        else //1100XXXXXXXX
        begin
//MOVLW k(8)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=parCommand[5];
        par[6]:=parCommand[6];
        par[7]:=parCommand[7];
        par[8]:=false;
        result:='MOVLW ' + BinToHex() + 'h';
        end;
      end;
    end
    else //10XXXXXXXXXX
      if parCommand[9] then //101XXXXXXXXX
      begin
//GOTO k(9)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=parCommand[5];
        par[6]:=parCommand[6];
        par[7]:=parCommand[7];
        par[8]:=parCommand[8];
        result:='GOTO ' + BinToHex() + 'h';
      end
      else //100XXXXXXXXX
      begin
        if parCommand[8] then //1001XXXXXXXX
        begin
//CALL k(8)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=parCommand[5];
        par[6]:=parCommand[6];
        par[7]:=parCommand[7];
        par[8]:=false;
        result:='CALL ' + BinToHex() + 'h';
        end
        else
        begin   //1000XXXXXXXX
//RETLW k(8)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=parCommand[5];
        par[6]:=parCommand[6];
        par[7]:=parCommand[7];
        par[8]:=false;
        result:='RETLW ' + BinToHex() + 'h';
        end;
      end;
  end
  else
  begin //0XXXXXXXXXXX
    if parCommand[10] then
    begin //01XXXXXXXXXX
      if parCommand[9] then
      begin //011XXXXXXXXX
        if parCommand[8] then
        begin //0111XXXXXXXX
//BTFSS f(5),b(3)  0111bbbfffff
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=false;
        par[6]:=false;
        par[7]:=false;
        par[8]:=false;
        tmpByte1:=0;
        if parCommand[5] then tmpByte1:=tmpByte1+1;
        if parCommand[6] then tmpByte1:=tmpByte1+2;
        if parCommand[7] then tmpByte1:=tmpByte1+4;

        result:='BTFSS ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end
        else
        begin //0110XXXXXXXX
//BTFSC f(5),b(3)  0110bbbfffff
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=false;
        par[6]:=false;
        par[7]:=false;
        par[8]:=false;
        tmpByte1:=0;
        if parCommand[5] then tmpByte1:=tmpByte1+1;
        if parCommand[6] then tmpByte1:=tmpByte1+2;
        if parCommand[7] then tmpByte1:=tmpByte1+4;

        result:='BTFSC ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end;
      end
      else
      begin //010XXXXXXXXX
        if parCommand[8] then
        begin //0101XXXXXXXX
//BSF  f(5),b(3)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=false;
        par[6]:=false;
        par[7]:=false;
        par[8]:=false;
        tmpByte1:=0;
        if parCommand[5] then tmpByte1:=tmpByte1+1;
        if parCommand[6] then tmpByte1:=tmpByte1+2;
        if parCommand[7] then tmpByte1:=tmpByte1+4;

        result:='BSF ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end
        else
        begin  //0100XXXXXXXX
//BCF  f(5),b(3)
        par[0]:=parCommand[0];
        par[1]:=parCommand[1];
        par[2]:=parCommand[2];
        par[3]:=parCommand[3];
        par[4]:=parCommand[4];
        par[5]:=false;
        par[6]:=false;
        par[7]:=false;
        par[8]:=false;
        tmpByte1:=0;
        if parCommand[5] then tmpByte1:=tmpByte1+1;
        if parCommand[6] then tmpByte1:=tmpByte1+2;
        if parCommand[7] then tmpByte1:=tmpByte1+4;

        result:='BCF ' + BinToHex() + 'h, ' + inttostr(tmpByte1);
        end;
      end;
    end
    else
    begin //00XXXXXXXXXX
      if parCommand[9] then
      begin //001XXXXXXXXX
        if parCommand[8] then
        begin //0011XXXXXXXX
          if parCommand[7] then
          begin //00111XXXXXXX
            if parCommand[6] then
            begin //001111XXXXXX
//INCFSZ f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='INCFSZ ' + BinToHex() + 'h, f'
            else
            result:='INCFSZ ' + BinToHex() + 'h, W';


            end
            else
            begin //001110XXXXXX
//SWAPF f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='SWAPF ' + BinToHex() + 'h, f'
            else
            result:='SWAPF ' + BinToHex() + 'h, W';
            end;

          end
          else
          begin //00110XXXXXXX
            if parCommand[6] then
            begin //001101XXXXXX
//RLF f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='RLF ' + BinToHex() + 'h, f'
            else
            result:='RLF ' + BinToHex() + 'h, W';

            end
            else
            begin  //001100XXXXXX
//RRF f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='RRF ' + BinToHex() + 'h, f'
            else
            result:='RRF ' + BinToHex() + 'h, W';

            end;
          end;

        end
        else
        begin //0010XXXXXXXX
          if parCommand[7] then
          begin //00101XXXXXXX
            if parCommand[6] then
            begin //001011XXXXXX
//DECFSZ  f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='DECFSZ ' + BinToHex() + 'h, f'
            else
            result:='DECFSZ ' + BinToHex() + 'h, W';

            end
            else
            begin //001010XXXXXX
//INCF f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='INCF ' + BinToHex() + 'h, f'
            else
            result:='INCF ' + BinToHex() + 'h, W';

            end
          end
          else
          begin //00100XXXXXXX
            if parCommand[5] then
            begin //001001XXXXXX
//COMF f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='COMF ' + BinToHex() + 'h, f'
            else
            result:='COMF ' + BinToHex() + 'h, W';

            end
            else
            begin //001000XXXXXX
//MOVF f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='MOVF ' + BinToHex() + 'h, f'
            else
            result:='MOVF ' + BinToHex() + 'h, W';

            end;
          end;
        end;

      end
      else
      begin //000XXXXXXXXX
        if parCommand[8] then
        begin //0001XXXXXXXX
          if parCommand[7] then
          begin  //00011XXXXXXX
            if parCommand[6] then
            begin //000111XXXXXX
//ADDWF f(5),d(1)  - ��� ���� �������� ��������� W � f
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='ADDWF ' + BinToHex() + 'h, f'
            else
            result:='ADDWF ' + BinToHex() + 'h, W';
            end
            else
            begin //000110XXXXXX
//XORWF  f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='XORWF ' + BinToHex() + 'h, f'
            else
            result:='XORWF ' + BinToHex() + 'h, W';
            end;
          end
          else
          begin  //00010XXXXXXX
          if parCommand[6] then
            begin  //000101XXXXXX
//ANDWF  f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='ANDWF ' + BinToHex() + 'h, f'
            else
            result:='ANDWF ' + BinToHex() + 'h, W';
            end
            else
            begin  //000100XXXXXX
//IORWF f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='IORWF ' + BinToHex() + 'h, f'
            else
            result:='IORWF ' + BinToHex() + 'h, W';
            end;
          end;


        end
        else
        begin //0000XXXXXXXX
          if parCommand[7] then
          begin //00001XXXXXXX
            if parCommand[6] then
            begin //000011XXXXXX
//DECF  f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='DECF ' + BinToHex() + 'h, f'
            else
            result:='DECF ' + BinToHex() + 'h, W';

            end
            else
            begin //000010XXXXXX
//SUBWF     f(5),d(1)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            if parCommand[5] then
            result:='SUBWF ' + BinToHex() + 'h, f'
            else
            result:='SUBWF ' + BinToHex() + 'h, W';
            end;


          end
          else
          begin //00000XXXXXXX
            if parCommand[6] then
            begin //000001XXXXXX
              if parCommand[5] then
              begin //0000011XXXXX
//CLRF     f(5)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            result:='CLRF ' + BinToHex() + 'h';
              end
              else
              begin //0000010XXXXX
//CLRW
              result:='CLRW'
              end;
            end
            else
            begin //000000XXXXXX
              if parCommand[5] then
              begin //0000001XXXXX
//MOVWF    f(5)
            par[0]:=parCommand[0];
            par[1]:=parCommand[1];
            par[2]:=parCommand[2];
            par[3]:=parCommand[3];
            par[4]:=parCommand[4];
            par[5]:=false;
            par[6]:=false;
            par[7]:=false;
            par[8]:=false;
            result:='MOVWF ' + BinToHex() + 'h';
              end
              else
              begin //0000000XXXXX
                if parCommand[4] then
                begin //00000001XXXX
                //Unknow command
                result:='unknown';
                end
                else
                begin //00000000XXXX
                  if parCommand[3] then
                  begin //000000001XXX
                  //Unknow command
                  result:='unknown';
                  end
                  else
                  begin //000000000XXX
                    if parCommand[2] then
                    begin //0000000001XX
                      if parCommand[1] then
                      begin //00000000011X
                        if parCommand[0] then
                          begin //000000000111
//!TRIS 7  - PORT?    //Unknow command
                          result:='TRIS 7';
                          end
                          else
                          begin  //000000000110
//aTRIS 6
                          result:='TRIS 6';
                          end;
                      end
                      else
                      begin //00000000010X
                        if parCommand[0] then
                        begin //000000000101
//!TRIS 5 - PORT?    //Unknow command
                        result:='TRIS 5';
                        end
                        else
                        begin //000000000100
//!CLRWDT
                        result:='CLRWDT';
                        end;




                      end;

                    end
                    else
                    begin //0000000000XX
                      if parCommand[1] then
                      begin //00000000001X
                        if parCommand[0] then
                        Begin //000000000011
//!Sleep
                        result:='SLEEP';
                        End
                        else
                        begin //000000000010
//aOPTION
                        result:='OPTION';

                        end;

                      end
                      else
                      begin //00000000000X
                        if parCommand[0] then
                        Begin //000000000001
                        //Unknow command
                        result:='unknown';
                        End
                        else
                        begin //000000000000
//aNOP
                        result:='NOP';

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


procedure resetRAM(Id:byte);

 //����� ��������� ������������� RAM �� ����� ������
Var Z:Word;
J:Byte;
begin
  if Id=0  then
  begin
  for Z := 0 to AllRAMSize do //PORT! ������ � ����. ���������� - 35
    for j := 0 to 7 do
    begin
    RAM[Z,J]:=false; //������� �����
    end;
  //��������� PCL
  RAM[2,0]:=true;
  RAM[2,1]:=true;
  RAM[2,2]:=true;
  RAM[2,3]:=true;
  RAM[2,4]:=true;
  RAM[2,5]:=true;
  RAM[2,6]:=true;
  RAM[2,7]:=true;
  //��������� STATUS
  RAM[3,3]:=true;
  RAM[3,4]:=true;
  //��������� FSR
  RAM[4,7]:=true;
  RAM[4,6]:=true;
  RAM[4,5]:=true;
  //��������� OSCCAL
  RAM[5,1]:=true;
  RAM[5,2]:=true;
  RAM[5,3]:=true;
  RAM[5,4]:=true;
  RAM[5,5]:=true;
  RAM[5,6]:=true;
  RAM[5,7]:=true;
  //��������� OPTION
  RAM[regOPTION,0]:=true;
  RAM[regOPTION,1]:=true;
  RAM[regOPTION,2]:=true;
  RAM[regOPTION,3]:=true;
  RAM[regOPTION,4]:=true;
  RAM[regOPTION,5]:=true;
  RAM[regOPTION,6]:=true;
  RAM[regOPTION,7]:=true;
  //��������� TRISGPIO
  RAM[regTRISGPI0,0]:=true;
  RAM[regTRISGPI0,1]:=true;
  RAM[regTRISGPI0,2]:=true;
  RAM[regTRISGPI0,3]:=true;
  //����� �������� RAM � �������, ����� ����� ���� ��������� ������, ����� ������� ������
  for Z := 0 to AllRAMSize do
  begin
    matrixRAM[Z].delta:=false;
    for j := 0 to 7 do
    begin
    MatrixRAM[Z].value[j]:=RAM[Z,J];
    MatrixRAM[Z].deltabit[j]:=false;
    end;
  end;
  end;
end;
procedure generateSimAdress();
var Z:integer;
begin
for Z := 0 to AllRAMSize do
    begin
    if MatrixRAM[Z].IDEaddres >-1 then
      begin
        MatrixRAM[MatrixRAM[Z].IDEaddres].SIMadress:=Z;
      end;
    end;
end;
procedure SelectMC(Id:byte); //����� ��� ������������� ��� �� ����������
var
Z,J:integer;
begin
  if Id=0 then
  begin
//PIC10F200
  // ������� ������ �� ���������
  rtCrystalFreq:=4000000; //4 ���
  //����� ���-�� GPR u SFR
  SFRCount:=11+16;
  GPRCount:=16;
  AllRAMSize:=35;
  //������� ������� RAM ��� 0..31 - GPR � SFR 32 - W,33 - OPTION,34=TRISGPI0,35-TMR0 Prescaler
  setlength(RAM,AllRAMSize,7);
  //������� ������� ������� �/�
  setlength(MatrixRAM,AllRAMSize);
  //������� ������� ����. ����������� ���������
  regINDF:=0;
  regW:=32;
  regOPTION:=33;
  regTRISGPI0:=34;
  regTMR0P:=35;
  //��-���������, ������ ���, ���� � �������������� �������� ������������
  //� �����, ��-��������� ��� ���� ����� �����
  for Z := 0 to AllRAMSize do
    for j := 0 to 7 do
    begin
      MatrixRAM[Z].usedbit[j]:=true;
    //  MatrixRAM[Z].bitname[j]:='';
    end;
  //0 � RAM 1 � SFR
  //INDF
  MatrixRAM[0].Used:=true;
  MatrixRAM[0].SFR:=true;
  MatrixRAM[0].VirtSFR:=false;
  MatrixRAM[0].IDEName:='INDF';
  MatrixRAM[0].IDEHexaddres:='000';
  MatrixRAM[0].IDEaddres:=1;
  //1 � RAM 2 � SFR
  //TMR0
  MatrixRAM[1].Used:=true;
  MatrixRAM[1].SFR:=true;
  MatrixRAM[1].VirtSFR:=false;
  MatrixRAM[1].IDEName:='TMR0';
  MatrixRAM[1].IDEHexaddres:='001';
  MatrixRAM[1].IDEaddres:=2;
  //1 � RAM 2 � SFR
  //TMR0
  MatrixRAM[1].Used:=true;
  MatrixRAM[1].SFR:=true;
  MatrixRAM[1].VirtSFR:=false;
  MatrixRAM[1].IDEName:='TMR0';
  MatrixRAM[1].IDEHexaddres:='001';
  MatrixRAM[1].IDEaddres:=2;
  //2 � RAM 3 � SFR
  //PCL
  MatrixRAM[2].Used:=true;
  MatrixRAM[2].SFR:=true;
  MatrixRAM[2].VirtSFR:=false;
  MatrixRAM[2].IDEName:='PCL';
  MatrixRAM[2].IDEHexaddres:='002';
  MatrixRAM[2].IDEaddres:=3;
  //3 � RAM 4 � SFR
  //STATUS
  MatrixRAM[3].Used:=true;
  MatrixRAM[3].usedbit[5]:=false;
  MatrixRAM[3].usedbit[6]:=false; //Port!
  MatrixRAM[3].SFR:=true;
  MatrixRAM[3].VirtSFR:=false;
  MatrixRAM[3].IDEName:='STATUS';
  MatrixRAM[3].IDEHexaddres:='003';
  MatrixRAM[3].IDEaddres:=4;
  MatrixRAM[3].bitname[7]:='GPWUF';
// Port!  MatrixRAM[3].bitname[6]:='CWUF';
  MatrixRAM[3].bitname[4]:='\TO';
  MatrixRAM[3].bitname[3]:='\PD';
  MatrixRAM[3].bitname[2]:='Z';
  MatrixRAM[3].bitname[1]:='DC';
  MatrixRAM[3].bitname[0]:='C';


  //4 � RAM 5 � SFR
  //FSR
  MatrixRAM[4].Used:=true;
  MatrixRAM[4].SFR:=true;
  MatrixRAM[4].VirtSFR:=false;
  MatrixRAM[4].IDEName:='FSR';
  MatrixRAM[4].IDEHexaddres:='004';
  MatrixRAM[4].IDEaddres:=5;
  //5 � RAM 6 � SFR
  //OSCCAL
  MatrixRAM[5].Used:=true;
  MatrixRAM[5].SFR:=true;
  MatrixRAM[5].VirtSFR:=false;
  MatrixRAM[5].IDEName:='OSCCAL';
  MatrixRAM[5].IDEHexaddres:='005';
  MatrixRAM[5].IDEaddres:=6;
  MatrixRAM[5].bitname[7]:='CAL6';
  MatrixRAM[5].bitname[6]:='CAL5';
  MatrixRAM[5].bitname[5]:='CAL4';
  MatrixRAM[5].bitname[4]:='CAL3';
  MatrixRAM[5].bitname[3]:='CAL2';
  MatrixRAM[5].bitname[2]:='CAL1';
  MatrixRAM[5].bitname[1]:='CAL0';
  MatrixRAM[5].bitname[0]:='FOSC4';
  //6 � RAM 7 � SFR
  //GPIO
  MatrixRAM[6].Used:=true;
  MatrixRAM[6].SFR:=true;
  MatrixRAM[6].VirtSFR:=false;
  MatrixRAM[6].IDEName:='GPIO';
  MatrixRAM[6].IDEHexaddres:='006';
  MatrixRAM[6].IDEaddres:=7;
  MatrixRAM[6].usedbit[7]:=false;
  MatrixRAM[6].usedbit[6]:=false;
  MatrixRAM[6].usedbit[5]:=false;
  MatrixRAM[6].usedbit[4]:=false;
  MatrixRAM[6].bitname[3]:='GP3';
  MatrixRAM[6].bitname[2]:='GP2';
  MatrixRAM[6].bitname[1]:='GP1';
  MatrixRAM[6].bitname[0]:='GP0';
  //7-15 � RAM Unimplemented
  for Z:= 7 to 15 do
    begin
     MatrixRAM[Z].Used:=false;
     MatrixRAM[Z].SFR:=false;
     MatrixRAM[Z].VirtSFR:=false;
     MatrixRAM[Z].IDEName:='';
     MatrixRAM[Z].IDEHexaddres:='';
     MatrixRAM[Z].IDEaddres:=-1;
    end;
  //16-31 � RAM GPR
  J:=-1;
  for Z := 16 to 31 do
    begin
    inc(J);
     MatrixRAM[Z].Used:=true;
     MatrixRAM[Z].SFR:=false;
     MatrixRAM[Z].VirtSFR:=false;
     MatrixRAM[Z].IDEName:='';
     MatrixRAM[Z].IDEHexaddres:=IntToStr(I);
     MatrixRAM[Z].IDEaddres:=11+J;
    end;

  //REGW (32) � RAM 0 � SFR

  MatrixRAM[REGW].Used:=true;
  MatrixRAM[REGW].SFR:=true;
  MatrixRAM[REGW].VirtSFR:=true;
  MatrixRAM[REGW].IDEName:='W';
  MatrixRAM[REGW].IDEHexaddres:='W';
  MatrixRAM[REGW].IDEaddres:=0;
  //regOPTION (33) � RAM 8 � SFR

  MatrixRAM[regOPTION].Used:=true;
  MatrixRAM[regOPTION].SFR:=true;
  MatrixRAM[regOPTION].VirtSFR:=true;
  MatrixRAM[regOPTION].IDEName:='OPTION';
  MatrixRAM[regOPTION].IDEHexaddres:='n/a';
  MatrixRAM[regOPTION].IDEaddres:=8;


  //regTRISGPI0 (34) � RAM 9 � SFR

  MatrixRAM[regTRISGPI0].Used:=true;
  MatrixRAM[regTRISGPI0].SFR:=true;
  MatrixRAM[regTRISGPI0].VirtSFR:=true;
  MatrixRAM[regTRISGPI0].IDEName:='TRISGPIO';
  MatrixRAM[regTRISGPI0].IDEHexaddres:='n/a';
  MatrixRAM[regTRISGPI0].IDEaddres:=9;
  MatrixRAM[regTRISGPI0].usedbit[7]:=false;
  MatrixRAM[regTRISGPI0].usedbit[6]:=false;
  MatrixRAM[regTRISGPI0].usedbit[5]:=false;
  MatrixRAM[regTRISGPI0].usedbit[4]:=false;
  MatrixRAM[regTRISGPI0].usedbit[3]:=false;

  //TMR0 Prescaler (35) � RAM 9 � SFR

  MatrixRAM[regTMR0P].Used:=true;
  MatrixRAM[regTMR0P].SFR:=true;
  MatrixRAM[regTMR0P].VirtSFR:=true;
  MatrixRAM[regTMR0P].IDEName:='TMR0 Prescaler';
  MatrixRAM[regTMR0P].IDEHexaddres:='n/a';
  MatrixRAM[regTMR0P].IDEaddres:=10;


  end;
  if ID=1  then
  begin
//PIC10F202
  end;
  resetRAM(Id);
  generateSimAdress();
end;

end.
