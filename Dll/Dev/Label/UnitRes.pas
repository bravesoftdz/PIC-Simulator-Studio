unit UnitRes;

interface

uses Registry, windows;

const
  rg_COMPANY = 'AT-Control';
  // !!!��������, �� ������� �������� ���� ���������!!!
  rg_APPNAME = 'ATCSS1'; // !!!��������, �� ������� �������� ���� ���������!!!

var
  v_Root_Key_current_user: Boolean;
  v_Key_Path: string;
  v_Key_Name: string;
  V_Def_Val_Bool: Boolean;
  V_Def_Val_int: integer;

var
  Lang: integer;
procedure SetLang();
function GetText(Id: integer): string;

implementation

Procedure Get_from_db(Id: integer);

begin
  case Id of
    0: // ���� !!!��������, �� ��������� �������� ����� ��������� ����!!!
      begin
        v_Root_Key_current_user := true;
        v_Key_Path := 'software\' + rg_COMPANY + '\' + rg_APPNAME;
        v_Key_Name := 'Lang';
        V_Def_Val_int := 0;
        exit;
      end;

  end;
end;

// Boolean
procedure WriteBool(Id: integer; value: Boolean);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create();
  Get_from_db(Id);
  { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
  if v_Root_Key_current_user then
    Registry.RootKey := hkey_current_user
  else
    Registry.RootKey := hkey_local_machine;
  Registry.OpenKey(v_Key_Path, true);
  Registry.WriteBool(v_Key_Name, value);
  { ��������� � ����������� ���� }
  Registry.CloseKey;
  Registry.Free;
end;

Function ReadBool(Id: integer): Boolean;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create();
  Get_from_db(Id);
  { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
  if v_Root_Key_current_user then
    Registry.RootKey := hkey_current_user
  else
    Registry.RootKey := hkey_local_machine;
  Registry.OpenKey(v_Key_Path, true);
  if Registry.ValueExists(v_Key_Name) then
    ReadBool := Registry.ReadBool(v_Key_Name)
  else
  begin
    Registry.WriteBool(v_Key_Name, V_Def_Val_Bool);
    ReadBool := V_Def_Val_Bool;
  end;
  { ��������� � ����������� ���� }
  Registry.CloseKey;
  Registry.Free;
end;

// Integer
procedure WriteInt(Id: integer; value: integer);
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create();
  Get_from_db(Id);
  { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
  if v_Root_Key_current_user then
    Registry.RootKey := hkey_current_user
  else
    Registry.RootKey := hkey_local_machine;
  Registry.OpenKey(v_Key_Path, true);
  Registry.WriteInteger(v_Key_Name, value);
  { ��������� � ����������� ���� }
  Registry.CloseKey;
  Registry.Free;
end;

Function ReadInt(Id: integer): integer;
var
  Registry: TRegistry;
begin
  Registry := TRegistry.Create();
  Get_from_db(Id);
  { ������������� �������� ����; ������� hkey_local_machine ��� hkey_current_user }
  if v_Root_Key_current_user then
    Registry.RootKey := hkey_current_user
  else
    Registry.RootKey := hkey_local_machine;
  Registry.OpenKey(v_Key_Path, true);
  if Registry.ValueExists(v_Key_Name) then
    ReadInt := Registry.ReadInteger(v_Key_Name)
  else
  begin
    Registry.WriteInteger(v_Key_Name, V_Def_Val_int);
    ReadInt := V_Def_Val_int;
  end;
  { ��������� � ����������� ���� }
  Registry.CloseKey;
  Registry.Free;
end;

procedure SetLang();
var
  vLang: integer;
begin
  vLang := ReadInt(0);
  case vLang of
    0:
      Lang := 0; // English
    1:
      Lang := 1; // Russian
  else
    Lang := 0; // English for other
  end;
end;

function GetText(Id: integer): string;
Begin

  case Id of
    0: // title shown on the panel
      begin
        case Lang of
          0:
            result := 'Label';
          1:
            result := '�����';
        end;
        exit;
      end;
    1: // Ok
      begin
        case Lang of
          0:
            result := 'OK';
          1:
            result := 'OK';
        end;
        exit;
      end;
    2: // Cancel
      begin
        case Lang of
          0:
            result := 'Cancel';
          1:
            result := '������';
        end;
        exit;
      end;
    3: // Settings
      begin
        case Lang of
          0:
            result := 'Settings';
          1:
            result := '���������';
        end;
        exit;
      end;
    4:
      begin
        case Lang of
          0:
            result := 'Preview';
          1:
            result := '������������';
        end;
        exit;
      end;



    10:
      begin
        case Lang of
          0:
            result := 'Bold';
          1:
            result := '������';
        end;
        exit;
      end;
    11:
      begin
        case Lang of
          0:
            result := 'Italic';
          1:
            result := '������';
        end;
        exit;
      end;
    12:
      begin
        case Lang of
          0:
            result := 'Underline';
          1:
            result := '������������';
        end;
        exit;
      end;
    13:
      begin
        case Lang of
          0:
            result := 'Text:';
          1:
            result := '�����:';
        end;
        exit;
      end;
    14:
      begin
        case Lang of
          0:
            result := 'Text size:';
          1:
            result := '������ ������:';
        end;
        exit;
      end;

    20:
     begin
        case Lang of
          0:
            result := 'Text options';
          1:
            result := '��������� ������';
        end;
        exit;
      end;
      21:
     begin
        case Lang of
          0:
            result := 'Text color';
          1:
            result := '���� ������';
        end;
        exit;
      end;
        22:
     begin
        case Lang of
          0:
            result := 'Back color';
          1:
            result := '���� ����';
        end;
        exit;
      end;


  end;
End;

end.
