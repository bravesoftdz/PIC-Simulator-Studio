unit unitWeb;

interface

uses windows,IdHTTP,classes,forms,sysutils,dialogs,unitres;

const Soft_version='ATCSS1';


type ThreadWebUpd = class(TThread)
  protected
    procedure Execute; override;
end;

function Check_updates():string;
function GetVersion(var Major, Minor, Release, Build: Byte): Boolean;
function SendReport(name:string; email:string; report:string ):string;
function GenerateHistory():string;
function GetLastLink():string;
var available_version:int64;
const V='';
implementation
uses frmCheckUpdates;
function Check_updates():string;
var
Http  : TidHttp;
  Data  : TStringList;
  s:  String;
  mj,mn,rl,bl:byte;
begin
 try
    Http := TIdHTTP.Create();
    Data := TStringList.Create;
    //Http.CookieManager := IdCookieManager1;
    Http.HandleRedirects := true;
    Http.Request.Host:='appenter.at-control.com';
    Http.Request.UserAgent:='Mozilla/5.0 (Windows; U; Windows NT 6.1; ru; rv:1.9.2.25) Gecko/20111212 Firefox/3.6.25';
    Http.Request.Accept:='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';                                            Http.Request.AcceptLanguage:='ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3';
    Http.Request.AcceptCharSet:='windows-1251,utf-8;q=0.7,*;q=0.7';
    //Http.Request.Referer:='http://g1.botva.ru/login.php';
    GetVersion(mj,mn,rl,bl);
    Data.Add('xproduct='+Soft_version);
    Data.Add('xversionmj=' + inttostr(mj) );
    Data.Add('xversionmn=' + inttostr(mn) );
    Data.Add('xversionrl=' + inttostr(rl));
   // Data.Add('xversionbl=' + inttostr(bl));

    s := Http.Post('http://appenter.at-control.com/chkver.php', Data);
    result:=s;
 //   memo1.text:=s;
 //   memo2.text:=http.Get('http://g1.botva.ru/mine.php');
  except
  result:='e0'; //Error
  end;
     Data.Free;
    Http.Free;
end;
function GenerateHistory():string;
var
Http  : TidHttp;
  Data  : TStringList;
  s:  String;
  mj,mn,rl,bl:byte;
begin
 try
    Http := TIdHTTP.Create();
    Data := TStringList.Create;
    //Http.CookieManager := IdCookieManager1;
    Http.HandleRedirects := true;
    Http.Request.Host:='appenter.at-control.com';
    Http.Request.UserAgent:='Mozilla/5.0 (Windows; U; Windows NT 6.1; ru; rv:1.9.2.25) Gecko/20111212 Firefox/3.6.25';
    Http.Request.Accept:='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';                                            Http.Request.AcceptLanguage:='ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3';
    Http.Request.AcceptCharSet:='windows-1251,utf-8;q=0.7,*;q=0.7';
    //Http.Request.Referer:='http://g1.botva.ru/login.php';
    GetVersion(mj,mn,rl,bl);
    Data.Add('xproduct='+Soft_version);
    Data.Add('xversionmj=' + inttostr(mj) );
    Data.Add('xversionmn=' + inttostr(mn) );
    Data.Add('xversionrl=' + inttostr(rl));
   // Data.Add('xversionbl=' + inttostr(bl));

    s := Http.Post('http://appenter.at-control.com/VersionHistory.php', Data);
    result:=s;
 //   memo1.text:=s;
 //   memo2.text:=http.Get('http://g1.botva.ru/mine.php');
  except
  result:='e0'; //Error
  end;
     Data.Free;
    Http.Free;
end;
function GetLastLink():string;
var
Http  : TidHttp;
  Data  : TStringList;
  s:  String;
  mj,mn,rl,bl:byte;
begin
 try
    Http := TIdHTTP.Create();
    Data := TStringList.Create;
    //Http.CookieManager := IdCookieManager1;
    Http.HandleRedirects := true;
    Http.Request.Host:='appenter.at-control.com';
    Http.Request.UserAgent:='Mozilla/5.0 (Windows; U; Windows NT 6.1; ru; rv:1.9.2.25) Gecko/20111212 Firefox/3.6.25';
    Http.Request.Accept:='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';                                            Http.Request.AcceptLanguage:='ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3';
    Http.Request.AcceptCharSet:='windows-1251,utf-8;q=0.7,*;q=0.7';
    //Http.Request.Referer:='http://g1.botva.ru/login.php';

    Data.Add('xproduct='+Soft_version);

   // Data.Add('xversionbl=' + inttostr(bl));

    s := Http.Post('http://appenter.at-control.com/GetLastLink.php', Data);
    result:=s;
 //   memo1.text:=s;
 //   memo2.text:=http.Get('http://g1.botva.ru/mine.php');
  except
  result:='e0'; //Error
  end;
     Data.Free;
    Http.Free;
end;
function GetVersion(var Major, Minor, Release, Build: Byte): Boolean;
var
  info: Pointer;
  infosize: DWORD;
  fileinfo: PVSFixedFileInfo;
  fileinfosize: DWORD;
  tmp: DWORD;
begin
  infosize := GetFileVersionInfoSize(PChar(ParamStr(0)), tmp);
  Result := infosize <> 0;
  if Result then
  begin
    GetMem(info, infosize);
    try
      GetFileVersionInfo(PChar(Application.ExeName), 0, infosize, info);
      VerQueryValue(info, '\', Pointer(fileinfo), fileinfosize);
      Major   := fileinfo.dwProductVersionMS shr 16;
      Minor   := fileinfo.dwProductVersionMS and $FFFF;
      Release := fileinfo.dwProductVersionLS shr 16;
      Build   := fileinfo.dwProductVersionLS and $FFFF;
    finally
      FreeMem(info, fileinfosize);
    end;
  end;
end;
function SendReport(name:string; email:string; report:string ):string;
var
Http  : TidHttp;
Data  : TStringList;
s:  String;
begin
 try
    Http := TIdHTTP.Create();
    Data := TStringList.Create;
    Http.AllowCookies := false;
    //Http.CookieManager := IdCookieManager1;
    Http.HandleRedirects := true;
    //Http.Request.Host:='http://at-control.com';
    Http.Request.UserAgent:='Mozilla/5.0 (Windows; U; Windows NT 6.1; ru; rv:1.9.2.25) Gecko/20111212 Firefox/3.6.25';
    Http.Request.Accept:='text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8';                                            Http.Request.AcceptLanguage:='ru-ru,ru;q=0.8,en-us;q=0.5,en;q=0.3';
    Http.Request.AcceptCharSet:='windows-1251,utf-8;q=0.7,*;q=0.7';
   // Http.Request.Referer:='http://appenter.at-control.com/bugreport.php';

    Data.Add('xproduct='+Soft_version);
    Data.Add('xname='+name);
    Data.Add('xemail='+email);
    Data.Add('xmessage='+report);
    s:='';
    s := Http.Post('http://appenter.at-control.com/bugreport.php', Data);

    if COPY(s,1,2)='ar' then result:=GetText(2050) else result:=s;
    if LENGTH(S)=5 then if COPY(s,4,2)='ar' then result:=GetText(2050) else result:=s;


  except
  result:=gettext(2051);
  end;
      Data.Free;
  //  IdCookieManager1.Free;
    Http.Free;
end;

procedure ThreadWebUpd.Execute;
var s:string;
begin
  formcheckupdates.Memo1.Text:=Gettext(2052)+'...';
application.ProcessMessages;
s:=Check_updates();
if copy(s,1,2)='e0' then //������ ����������� � �������
  begin
  formcheckupdates.memo1.Text:=gettext(2051);
  exit;
  end;
if copy(s,1,2)='e1' then //Error connecting to MySQL server
  begin
  formcheckupdates.memo1.Text:=gettext(2053);
  exit;
  end;
if copy(s,1,2)='e2' then //Error querying database
  begin
  formcheckupdates.memo1.Text:=gettext(2054);
  exit;
  end;
if copy(s,1,2)='lv' then //All good
  begin
  formcheckupdates.memo1.Text:=gettext(2055);
  CHK_Complite:=true;
  exit;
  end;
if Copy(s,1,2)='ru' then
  begin
  formcheckupdates.memo1.Text:='------------'+gettext(2056)+'!!!-------------'+chr(13)+chr(10)+chr(13)+chr(10);
  formcheckupdates.memo1.Text:=formcheckupdates.Memo1.text+gettext(2057)+' '+ Copy(s,3,Length(S)-2)+chr(13)+chr(10)+chr(13)+chr(10);
  formcheckupdates.Memo1.Text:=formcheckupdates.Memo1.text+gettext(2058)+':'+chr(13)+chr(10);
  application.ProcessMessages;
  S:=GenerateHistory();
  formCheckUpdates.btnDownNInst.Enabled:=true;
//  if formcheckUpdates.Showing=false then formcheckupdates.Show;
  CHK_Complite:=true;
  frmCheckUpdates.CanShow:=true;
  if copy(s,1,2)='e0' then //������ ����������� � �������
  begin
  formcheckupdates.Memo1.Text:=formcheckupdates.Memo1.Text+gettext(2051);
  exit;
  end;
  if copy(s,1,2)='e1' then //Error connecting to MySQL server
  begin
  formcheckupdates.Memo1.Text:=formcheckupdates.Memo1.Text+gettext(2053);
  exit;
  end;
  if copy(s,1,2)='e2' then //Error querying database
  begin
  formcheckupdates.Memo1.Text:=formcheckupdates.Memo1.Text+gettext(2054);
  exit;
  end;
    formcheckupdates.Memo1.Text:=formcheckupdates.Memo1.Text+S;

  end;
end;

end.
