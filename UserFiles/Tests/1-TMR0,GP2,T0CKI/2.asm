	MOVLW 00000000b
	TRIS 6 ;��� �������,�� ����������� GP3 (�� ��� ����� �� ������������) �� �����
	MOVLW 11010111b ;5(0) - ���� ���������� ������� � �����. ���������� Fosc/4; 3(0) -������������ ����� TMR0; 2-0(1) - ������������ 1:256
	OPTION
	BSF 5,0  ;���������� ����� 3 �� INTOSC/4 � GP2 ��� T0CKI
l1:	NOP
	BTFSC 01h,7
	BSF 6h,0 ;������ ��������� �� GP0
	BTFSS 01h,7
	BCF 6h,0 ;Gjneibv ��������� �� GP0
	goto l1