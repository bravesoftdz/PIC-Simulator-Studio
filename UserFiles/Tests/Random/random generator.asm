MOVLW 11011111b
OPTION ;��������� ����� �� GP2
MOVLW 00000100b
TRIS 6 ;��������� GP2 �� ����, ��������� - �� �����
start: ; ����� ���� ������� ������ "�����"
BTFSS 6,2
GOTO start
BCF 6,0
BCF 6,1
loop: ;������ ����� "������� ������"
BCF 10h,0
NOP
BTFSS 6,2
GOTO glow
BSF 10h,0
BTFSS 6,2
GOTO glow
GOTO loop
glow:
BCF 6,0
BCF 6,1
BTFSS 10h,0
BSF 6,1
BTFSC 6,1
GOTO start
BSF 6,0
GOTO start


