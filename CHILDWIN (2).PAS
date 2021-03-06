unit CHILDWIN;

interface

uses Windows, Classes, Graphics, Forms, Controls, StdCtrls, ComCtrls, PIC10F,SysUtils, Dialogs;

type TArrayOfLinks = record
  lnkNo:integer;
  lnkAddr:integer;
end;

type
  TMDIChild = class(TForm)
    RT: TRichEdit;

    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormResize(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure RTChange(Sender: TObject);

  private

    { Private declarations }
  public
    { Public declarations }
  procedure DisAssembley();
  procedure CheckSyn();
  procedure CheckSynLine(str:String; StartPos:integer);
//  function IsCommand(Str:string):integer;
   var alload: boolean;
   tableofLinks:array of TArrayOfLinks;
   tablelinkscount:integer;
  end;


implementation

{$R *.dfm}
function IsCommand(Str:string):integer;  //������� �������� �� ��������
var tI:Integer;
begin
IsCommand:=-1;
  for tI:=1 to PIC10F.SystemCommandCounter do
      if PIC10F.SystemCommand[tI-1].CommandName=str then
        begin
          result:=tI-1;
          exit;
        end;
end;
function IsDirective(str:string):integer; //������� �������� �� ��������� ����������
begin
  isDirective:=-1 ;
  if str='EQU' then result:=1;

end;
function IsDigth(str:string):integer; //������� �������� �� �������� ��������
var len,tmpI,tmpOrd:integer;
label l1,l2,l3,l4;
begin
IsDigth:=-1;
len:=Length(STR);

//�������� �� ������������������� ���� 0x1F
if len>2 then //����� ������ �� 3-� ������� �.�. ����. 0x1
  if str[1]='0' then //������ ������ ���� 0
    if str[1]='X' then //����� ������ ���� "���"
    begin
    for tmpI := 2 to len-1 do
      begin
        tmpOrd:=ord(STR[I]);
         if not (((tmpOrd>47) and (tmpOrd<58)) or ((tmpOrd>64) and (tmpOrd<71))) then  //��������, � ����� �����-��� ������ �� 0123456789ABCDEF
         goto l1; //���
      end;
      //��� ������ ��� hex!!!
      result:=3;
      exit;
    end;
l1:
//�������� �� ������������������� ���� F1Ah
if len>1 then //����� ������ �� 2-� �������� �.�. ���� 1h
  if str[len-1]='H' then //������ ������������� �� ������ "��"
  begin
    for tmpI := 0 to len-2 do
      begin
      if not (((tmpOrd>47) and (tmpOrd<58)) or ((tmpOrd>64) and (tmpOrd<71))) then  //��������, � ����� �����-��� ������ �� 0123456789ABCDEF
      goto l2; //���
      end;
    //��� ������ ��� hex!!!
    result:=3;
    exit;
  end;
l2:
//�������� �� ������������ ���� 12953
 for tmpI := 0 to len-1 do
      begin
      if not (tmpOrd>47) and (tmpOrd<58)  then  //��������, � ����� �����-��� ������ �� 0123456789
      goto l3; //���
      end;
    //��� ������ ��� dec!!!
    result:=1;
    exit;
l3:
//�������� �� ���������� ���� 011101b
if len>1 then //����� ������ �� 2-� �������� �.�. ���� 1b
  if True then
    if str[len-1]='B' then //������ ������������� �� ������ "��"
    begin
    for tmpI := 0 to len-2 do
      begin
      if not (tmpOrd>47) and (tmpOrd<50)  then  //��������, � ����� �����-��� ������ �� 0123456789ABCDEF
      goto l4; //���
      end;
    //��� ������ ��� ���!!!
    result:=2;
    exit;
    end;
l4:


end;

procedure TMDIChild.CheckSynLine(str:String; StartPos:integer);
var pComment,pMet,LenStr,pPlus:integer;
tS:string[1];
tA:AnsiChar;
tI,tZ:integer;
aCaD: array of string;
aInd: integer;
label lMet,lOther, lOther2;
begin
LenStr:=Length(str); //� ���������� ����� ������
pPlus:=0; //��� ������ � ������ �� �������
//������� ��� �������� � ������ - ���� � ��������
RT.SelStart:=StartPos;
RT.SelLength:=LenStr;
RT.SelAttributes.Style:=[fsBold];
RT.SelAttributes.Color:=clBlack;

//��������� ��� � ������� �������
str:=AnsiUpperCase(str);
//���������� �����������
pComment:=pos(';',str); //����� ����������� � ������
if pComment=0 then goto lMet; //���� ���, �� ������� � ������ �����
RT.SelStart:=StartPos+pComment-1; //��������� ������� ��� ���������
RT.SelLength:=LenStr-pComment+1; //�������� ������� ��� ���������

RT.SelAttributes.Color:=clGreen; //�������� ������� ������
Delete(Str,pComment,LenStr-pComment+1); //������� ������� �� ���������� ���������
LenStr:=Length(str); //� ���������� ����� ��� ����� ������

//���������� �����
lMet:
if str='' then exit;//��������, � �� ����� �� ������, � ���� ��, �� �������
ts:=copy(str,1,1); //�������� ��������� ������
if (ts=#9) or (ts=#32) then //���������, � �� ������ ��� �� ��� �� ���,
    begin
    delete(str,1,1); //���� �� - �� ������ ���
    pPlus:=pPlus+1;     //���������� ���������� ��������
    goto lMet;            //� �������� ��������
    end;
pMet:=pos(':',str); //����� ����� � ������
if pMet=0 then goto lOther; //���� ���, �� ������� � ������ ����������
tS:=copy(str,1,1); //����� ������ ���������� � �����
tA:=tS[1];
tI:=ord(tA);
if ((tI>64) and (tI<91)) or ((tI>96) and (tI<123)) or ((tI>192) and (tI<256))  then
  begin
  for tZ := 2 to pMet-1 do
    begin
      tS:=copy(str,tZ,1); //����� ������ ������������ ������ ��� ������
      tA:=tS[1];
      tI:=ord(tA);
      if ((tI>64) and (tI<91))
      or ((tI>96) and (tI<123))
      or ((tI>192) and (tI<256))
      or  ((tI>47) and (tI<58))
      then
        else
        begin
           //������������ ����� - � ������� ���� ��� ���-��
            RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
            RT.SelLength:=pMet; //�������� ������� ��� ���������
            RT.SelAttributes.Color:=clRed; //�������� �� ������
            exit;
        end;
    end;
    //� ��� ��� ����������
      RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
      RT.SelLength:=pMet; //�������� ������� ��� ���������
      RT.SelAttributes.Style:=[fsUnderLine]+[fsBold]; //�������� ������
      Delete(str,1,pMet);
      LenStr:=Length(str); //� ���������� ����� ��� ����� ������
      pPlus:=pPlus+pMet;

  end
  else
  begin
  //������������ ����� - � ������ ����� ��� ��� ���-��
  RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
  RT.SelLength:=pMet; //�������� ������� ��� ���������
  RT.SelAttributes.Color:=clRed; //�������� �� ������
  exit;
  end;


//����� ������ � �������� ����������
lOther:
if (Copy(str,LenStr,1)<>#32) or (Copy(str,LenStr,1)<>#9) then Str:=Str+' ';//���������� ������� � �����, ���� ����
LenStr:=Length(str); //� ���������� ����� ��� ����� ������
aInd:=0; //������������� ������� ������, ���. ����� ��������� ���������
lOther2:
 // �������� �������� � ������, ���� ����
if (copy(str,1,1)=#9) or (copy(str,1,1)=#32) then
  begin
    Delete(Str,1,1);
    pPlus:=pPlus+1;
    goto lOther2;
  end;
for tZ := 1 to LenStr do
  begin
    if (copy(str,tZ,1)=#9) or (copy(str,tZ,1)=#32)  then
      begin
      aInd:=aInd+1;
      SetLength(aCaD,aInd);
      aCad[aInd-1]:=Copy(str,1,tZ-1);
      //��������, ��� �� ���?
      if IsCommand(aCad[aInd-1])>-1 then //�������� �� �������
        begin
          RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
          RT.SelLength:=tZ-1; //�������� ������� ��� ���������
          //RT.SelAttributes.Style:=[fsUnderLine]+[fsBold]; //�������� ������
          RT.SelAttributes.Color:=clBlue;
        end
        else
        begin //�� �������
          if IsDirective(aCad[aInd-1])>-1 then //�������� �� ��������� ����������
            begin
          RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
          RT.SelLength:=tZ-1; //�������� ������� ��� ���������
          //RT.SelAttributes.Style:=[fsUnderLine]+[fsBold]; //�������� ������
          RT.SelAttributes.Color:=clYellow;
            end
            else
            begin //�� ���������
            case IsDigth(aCad[aInd-1]) of
            1:
              begin //Dec
                        RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
          RT.SelLength:=tZ-1; //�������� ������� ��� ���������
          //RT.SelAttributes.Style:=[fsUnderLine]+[fsBold]; //�������� ������
          RT.SelAttributes.Color:=clwhite;
              end;
            2:
              begin //Bin
                      RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
          RT.SelLength:=tZ-1; //�������� ������� ��� ���������
          //RT.SelAttributes.Style:=[fsUnderLine]+[fsBold]; //�������� ������
          RT.SelAttributes.Color:=clYellow;
              end;
            3:
              begin //Hex
                     RT.SelStart:=StartPos+pPlus; //��������� ������� ��� ���������
          RT.SelLength:=tZ-1; //�������� ������� ��� ���������
          //RT.SelAttributes.Style:=[fsUnderLine]+[fsBold]; //�������� ������
          RT.SelAttributes.Color:=clred;
              end
            else
              begin

              end;

            end;
            end;

        end;
      //�������� � ���������� ���������
      Delete(str,1,tZ);
      pplus:=pplus+tZ;
      goto lOther;
      end;
  end;





end;

procedure TMDIChild.CheckSyn();
var Z,indx:Integer;
begin
indx:=0;
for Z := 0 to RT.Lines.Count-1 do
  begin
    CheckSynLine(rt.Lines[Z],indx);
    indx:=indx+1+length(rt.Lines[Z]);

  end;
end;
procedure TMDIChild.DisAssembley();
var G,H:integer;
Instr:string;
label lblEndCycle;
begin
rt.Text:='';
tablelinkscount:=0;
//txtlines.Text:='';
for G := 0 to 255 do
  begin
  PIC10F.parCommand[0]:=PIC10F.ROM[G,0];
  PIC10F.parCommand[1]:=PIC10F.ROM[G,1];
  PIC10F.parCommand[2]:=PIC10F.ROM[G,2];
  PIC10F.parCommand[3]:=PIC10F.ROM[G,3];
  PIC10F.parCommand[4]:=PIC10F.ROM[G,4];
  PIC10F.parCommand[5]:=PIC10F.ROM[G,5];
  PIC10F.parCommand[6]:=PIC10F.ROM[G,6];
  PIC10F.parCommand[7]:=PIC10F.ROM[G,7];
  PIC10F.parCommand[8]:=PIC10F.ROM[G,8];
  PIC10F.parCommand[9]:=PIC10F.ROM[G,9];
  PIC10F.parCommand[10]:=PIC10F.ROM[G,10];
  PIC10F.parCommand[11]:=PIC10F.ROM[G,11];
  //rt.Lines.Add(#9+PIC10F.GetInstruction());
  Instr:=PIC10F.GetInstruction();
//���� ���� ����, �� ������� � ������� �����
  if Copy(Instr,1,4) = 'GOTO' then
    begin
      //������ ��������, � ��� �� ��� ����� ����� � �������
      for H := 1 to tablelinkscount do
        begin
          if tableoflinks[H-1].lnkAddr=pic10f.parGOTOaddr then
            begin
              //������, ����
              rt.Text:=rt.Text+#9+'GOTO lbl'+inttostr(tableoflinks[H-1].lnkno)+#13#10;
              goto lblEndCycle;
            end;

        end;
      //������, ���
      tablelinkscount:=tablelinkscount+1;
      SetLength(tableoflinks,tablelinkscount);
      tableoflinks[tablelinkscount-1].lnkNo:=tablelinkscount;
      tableoflinks[tablelinkscount-1].lnkAddr:=pic10f.parGOTOaddr;
      rt.Text:=rt.Text+#9+'GOTO lbl'+inttostr(tableoflinks[tablelinkscount-1].lnkno)+#13#10;
      goto lblEndCycle;
    end;
//���� ���� CALL, �� ������� � ������� �����
  if Copy(Instr,1,4) = 'CALL' then
    begin
      //������ ��������, � ��� �� ��� ����� ����� � �������
      for H := 1 to tablelinkscount do
        begin
          if tableoflinks[H-1].lnkAddr=pic10f.parGOTOaddr then
            begin
              //������, ����
              rt.Text:=rt.Text+#9+'CALL lbl'+inttostr(tableoflinks[H-1].lnkno)+#13#10;
              goto lblEndCycle;
            end;

        end;
      //������, ���
      tablelinkscount:=tablelinkscount+1;
      SetLength(tableoflinks,tablelinkscount);
      tableoflinks[tablelinkscount-1].lnkNo:=tablelinkscount;
      tableoflinks[tablelinkscount-1].lnkAddr:=pic10f.parGOTOaddr;
      rt.Text:=rt.Text+#9+'CALL lbl'+inttostr(tableoflinks[tablelinkscount-1].lnkno)+#13#10;
      goto lblEndCycle;
    end;

  rt.text:=rt.text+#9+Instr+#13#10;
lblEndCycle:
  end;
 //������������� ������� ������
 for G := 1 to tablelinkscount do
 begin
 rt.Lines[tableoflinks[G-1].lnkAddr]:='lbl'+inttostr(tableoflinks[G-1].lnkNo)+':'+rt.Lines[tableoflinks[G-1].lnkAddr];
 end;
 //�������� �������� NOP-��
 for G := rt.Lines.Count  downto 1 do
   begin
     if rt.Lines[G-1]=#9+'NOP' then
          rt.Lines.Delete(G-1)
               else exit;

   end;

end;

procedure TMDIChild.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;

end;

procedure TMDIChild.FormCreate(Sender: TObject);
begin
rt.Width:=width-rt.left-8;
rt.Height:=height-rt.top-30;
rt.DoubleBuffered:=true;


end;

procedure TMDIChild.FormResize(Sender: TObject);
begin
rt.Width:=width-rt.left-8;
rt.Height:=height-rt.top-30;

end;

procedure TMDIChild.RTChange(Sender: TObject);
var tZ, tS:integer;
tp:TPoint;
begin
if not alload then exit;
tp:=rt.CaretPos;
tS:=0;
for tZ := 1 to rt.CaretPos.Y  do tS:=tS+length(rt.Lines[tZ-1])+1;

checkSynLine(rt.Lines[rt.CaretPos.Y],ts);
rt.CaretPos:=tp;

end;

end.
