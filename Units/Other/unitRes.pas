﻿unit unitRes;


interface
uses winapi.windows,vcl.graphics,unitregistry;


function GetText(Id:integer):string;
procedure SetLang();
Procedure ApplyLangToMainForm();



var
Lang:integer;
bmpSFR,bmpGPR,bmpStack:TBitmap;

implementation
uses main;

procedure SetLang();
begin
Lang:=ReadInt(0);
if (lang<>0) and (lang<>1) then lang:=0;



end;

Procedure ApplyLangToMainForm();
begin
with main.MainForm do
begin
  //Загрузка текстовых ресурсов
caption:=unitres.GetText(1); //Заголовок
file1.Caption:=unitres.GetText(200);
Edit1.Caption:=unitres.GetText(201);
Window1.Caption:=unitres.GetText(202);
Option1.Caption:=unitres.GetText(203);
Help1.Caption:=unitres.GetText(204);
Run1.Caption:=unitres.GetText(205);

filenew1.Caption:=unitres.GetText(210);
fileopen1.Caption:=unitres.GetText(211);
fileclose1.Caption:=unitres.GetText(212);
filesave1.Caption:=unitres.GetText(213);
filesaveas1.Caption:=unitres.GetText(214);
fileexit1.Caption:=unitres.GetText(215);
fileexportasm1.Caption:=unitres.GetText(216);
fileexporthex1.Caption:=unitres.GetText(217);

editcut1.Caption:=unitres.GetText(230);
editcopy1.Caption:=unitres.GetText(231);
editpaste1.Caption:=unitres.GetText(232);

windowcascade1.Caption:=unitres.GetText(250);
windowtileHorizontal1.Caption:=unitres.GetText(251);
windowtileVertical1.Caption:=unitres.GetText(252);
windowMinimizeAll1.Caption:=unitres.GetText(253);
windowArrangeAll1.Caption:=unitres.GetText(254);

OptionConfigBits1.Caption:=unitres.GetText(270);

HelpChkUpdItem.Caption:=unitres.GetText(290);
BugReportItem.Caption:=unitres.GetText(291);
HelpAboutItem.Caption:=unitres.GetText(292);
HelpDonateItem.Caption:=unitres.GetText(293);
HelpHelp.Caption:=unitres.GetText(294);

ActionRate.Caption:=unitres.GetText(300);
ActionRun.Caption:=unitres.GetText(301);
ActionPause.Caption:=unitres.GetText(302);
ActionStop.Caption:=unitres.GetText(303);
ActionStep.Caption:=unitres.GetText(304);
ActionClearBP.Caption:=unitres.GetText(305);

ActionRateSBS.Caption:=unitres.GetText(320);
ActionRateVS.Caption:=unitres.GetText(321);
ActionRateSlow.Caption:=unitres.GetText(322);
ActionRateNormal.Caption:=unitres.GetText(323);
ActionRateFast.Caption:=unitres.GetText(324);
ActionRateVF.Caption:=unitres.GetText(325);
ActionRateRT.Caption:=unitres.GetText(326);
ActionRateX2.Caption:=unitres.GetText(327);
ActionRateUL.Caption:=unitres.GetText(328);
ActionOptions.Caption:=Unitres.gettext(329);

btnclear.Caption :=unitres.GetText(104);

label3.Caption:=unitres.GetText(3000);
label4.Caption:=unitres.GetText(3001);
label5.Caption:=unitres.GetText(3002);
label7.Caption:=unitres.GetText(3003);
label8.Caption:=unitres.GetText(3004);
label9.Caption:=unitres.GetText(3005);
label6.Caption:=unitres.GetText(3006);
label12.Caption:=unitres.GetText(3007);
label10.Caption:=unitres.GetText(3020);
label13.Caption:=unitres.GetText(3021);
label11.Caption:=unitres.GetText(3022);
label1.Caption:=unitres.GetText(3040);
label2.Caption:=unitres.GetText(3060);

FileNew1 .Hint:=Gettext(4000);
FileOpen1  .Hint:=Gettext(4001);
FileClose1  .Hint:=Gettext(4002);
FileSave1  .Hint:=Gettext(4003);
FileSaveAs1  .Hint:=Gettext(4004);
FileExit1  .Hint:=Gettext(4005);
FileExportAsm1  .Hint:=Gettext(4006);
FileExportHex1  .Hint:=Gettext(4007);
EditCut1  .Hint:=Gettext(4008);
EditCopy1  .Hint:=Gettext(4009);
EditPaste1  .Hint:=Gettext(4010);
HelpAbout1  .Hint:=Gettext(4011);
WindowCascade1.Hint:=Gettext(4012);
WindowTileHorizontal1 .Hint:=Gettext(4013);
WindowTileVertical1 .Hint:=Gettext(4014);
WindowMinimizeAll1 .Hint:=Gettext(4015);
WindowArrangeAll1 .Hint:=Gettext(4016);
BugReportItem .Hint:=Gettext(4017);
HelpChkUpdItem .Hint:=Gettext(4018);
ActionRate  .Hint:=Gettext(4019);
ActionRateSBS  .Hint:=Gettext(4020);
ActionRateVS  .Hint:=Gettext(4021);
ActionRateSlow  .Hint:=Gettext(4022);
ActionRateNormal  .Hint:=Gettext(4023);
ActionRateFast  .Hint:=Gettext(4024);
ActionRateVF  .Hint:=Gettext(4025);
ActionRateRT  .Hint:=Gettext(4026);
ActionRateX2  .Hint:=Gettext(4027);
ActionRateUL  .Hint:=Gettext(4028);
ActionRun  .Hint:=Gettext(4040);
ActionPause  .Hint:=Gettext(4041);
ActionStop  .Hint:=Gettext(4042);
ActionStep  .Hint:=Gettext(4044);

optionConfigbits1.hint:=gettext(4050);

if lang=0 then
begin //Код для Английского языка
btnclear.Font.Size:=8;
//label3.Font.Size:=8;
label4.Font.Size:=8;
label5.Font.Size:=8;
label7.Font.Size:=8;
label8.Font.Size:=8;
label9.Font.Size:=8;
label6.Font.Size:=8;
label12.Font.Size:=8;
//label10.Font.Size:=8;
label13.Font.Size:=8;
label11.Font.Size:=8;
//label1.Font.Size:=8;
//label2.Font.Size:=8;
bmpSFR.Handle := LoadBitmap(HInstance, 'gSfrEn');
image2.Picture.Bitmap:=bmpSFR;
bmpGPR.Handle := LoadBitmap(HInstance, 'gGprEn');
image4.Picture.Bitmap:=bmpGPR;
bmpStack.Handle := LoadBitmap(HInstance, 'gStackEn');
image5.Picture.Bitmap:=bmpStack;
end
else
begin //Код для Русского языка
btnclear.Font.Size:=7;
//label3.Font.Size:=7;
label4.Font.Size:=7;
label5.Font.Size:=7;
label7.Font.Size:=7;
label8.Font.Size:=7;
label9.Font.Size:=7;
label6.Font.Size:=7;
label12.Font.Size:=7;
//label10.Font.Size:=7;
label13.Font.Size:=7;
label11.Font.Size:=7;
//label1.Font.Size:=7;
//label2.Font.Size:=7;
bmpSFR.Handle := LoadBitmap(HInstance, 'gSfrRu');
image2.Picture.Bitmap:=bmpSFR;
bmpGPR.Handle := LoadBitmap(HInstance, 'gGprRu');
image4.Picture.Bitmap:=bmpGPR;
bmpStack.Handle := LoadBitmap(HInstance, 'gStackRu');
image5.Picture.Bitmap:=bmpStack;
end;

end;

end;

function GetText(Id:integer):string;
Begin
//0 - Web-site
// 1-99 - Captions of forms
// 100-999 - Captions of buttons / menus
// 1000-1999 - Error messages
// 2000 - 2999 - Info messages
// 3000 - 3999 - Labels / panels
//4000 - 4999 - Hints

case Id of
  0: //Web-site
  begin
    result:='http://at-control.com';
  end;
  1:// Main form caption and oth
    begin
    case Lang of
    0:    result:= 'PIC Simulator Studio';
    1:    result:= 'PIC Simulator Studio';
    end;
    exit;
    end;
  2:// About form caption
    begin
    case Lang of
    0:    result:=  'About ' + GetText(1);
    1:    result:=  'О программе ' + GetText(1);
    end;
    exit;
    end;
  3:// Assembler editor form caption
    begin
    case Lang of
    0:    result:=  'Assembler editor';
    1:    result:=  'Редактор ассемблера';
    end;
    exit;
    end;
  4:// Devices editor form caption
    begin
    case Lang of
    0:    result:=  'Devices editor';
    1:    result:=  'Редактор переферийных устройств';
    end;
    exit;
    end;
  5: // FrmOpen (Choosing a microcontroller) form caption
    begin
    case Lang of
    0:    result:=  'Choosing a microcontroller';
    1:    result:=  'Выбор микроконтроллера';
    end;
    exit;
    end;
  6:// FrmConfigBits (Configuration Bits) form caption
    begin
    case Lang of
    0:    result:=  'Configuration Bits';
    1:    result:=  'Биты конфигурации';
    end;
    exit;
    end;
  7:// FormBugReport(Bug Report form) form caption
    begin
    case Lang of
    0:    result:=  'Bug Report form';
    1:    result:=  'Отправить отчет об ошибке';
    end;
    exit;
    end;
  8:// FormCheckUpdates(Updates) form caption
    begin
    case Lang of
    0:    result:=  'Updates';
    1:    result:=  'Обновления';
    end;
    exit;
    end;
  9:// FormDevices(Devices) form caption
    begin
    case Lang of
    0:    result:=  'Devices';
    1:    result:=  'Устройства';
    end;
    exit;
    end;
  10: //FormNodes (ХЗ)form caption
    begin
    case Lang of
    0:    result:= 'Connect pins';
    1:    result:='Подключить выводы';
    end;
      exit;
    end;
  11:  //FormOptions captions
      begin
    case Lang of
    0:    result:= 'Options';
    1:    result:='Опции';
    end;
      exit;
    end;
  12:  //FormShareware captions
      begin
    case Lang of
    0:    result:= 'Need to update';
    1:    result:='Необходимо обновление';
    end;
      exit;
    end;
  100: //Указатель (Pointer). Кнопка на панели в окне схемы
    begin
        case Lang of
    0:    result:= 'Poiner';
    1:    result:= 'Указатель (курсор)';
    end;
      exit;
    end;
  101: //Стандартные
    begin  //Ok
    case Lang of
    0:    result:= 'Ok';
    1:    result:= 'Ok';
    end;
      exit;
    end;
  102: //Стандартные
    begin  //Cancel
        case Lang of
    0:    result:= 'Cancel';
    1:    result:= 'Отмена';
    end;
      exit;
    end;
  103: //Стандартные
    begin  //Delete
    case Lang of
    0:    result:= 'Delete';
    1:    result:= 'Удалить';
    end;
      exit;
    end;
  104: //Стандартные
    begin  //Clear
    case Lang of
    0:    result:= 'Clear';
    1:    result:= 'Очист.';
    end;
      exit;
    end;
    105: //Стандартные
    begin  //Send
    case Lang of
    0:    result:= 'Send';
    1:    result:= 'Отправить';
    end;
      exit;
    end;
    106: //Стандартные
    begin  //Close
    case Lang of
    0:    result:= 'Close';
    1:    result:= 'Закрыть';
    end;
      exit;
    end;
    107: //Стандартные
    begin  //Download and install
    case Lang of
    0:    result:= 'Download and Install';
    1:    result:= 'Загрузить и установить';
    end;
      exit;
    end;
  //Popup для радиодеталей на схеме
  120:
    begin //Настроить порты (Setup Ports)
    case Lang of
    0:    result:= 'Connect pins...';
    1:    result:='Подключить выводы...';
    end;
      exit;
    end;
  121:
    begin //Bring to Front
        case Lang of
    0:    result:= 'Bring to Front';
    1:    result:= 'На передний план';
    end;
      exit;
    end;
  122:
    begin //Send to Back
    case Lang of
    0:    result:= 'Send to Back';
    1:    result:= 'На задний план';
    end;
      exit;
    end;
  123:
    begin //Component Settings
    case Lang of
    0:    result:= 'Settings...';
    1:    result:= 'Настройки...';
    end;
      exit;
    end;
  200: //Главное меню программы
    begin
    case Lang of
    0:    result:= '&File';
    1:    result:= '&Файл';
    end;
    exit;
    end;
  201: //Главное меню программы
    begin
    case Lang of
    0:    result:= '&Edit';
    1:    result:= '&Правка';
    end;
    exit;
    end;
  202: //Главное меню программы
    begin
    case Lang of
    0:    result:= '&Window';
    1:    result:= '&Окна';
    end;
    exit;
    end;
  203: //Главное меню программы
    begin
    case Lang of
    0:    result:= '&Options';
    1:    result:= 'Опц&ии';
    end;
    exit;
    end;
  204: //Главное меню программы
    begin
    case Lang of
    0:    result:= '&Help';
    1:    result:= '&Справка';
    end;
    exit;
    end;
  205: //Главное меню программы
    begin
    case Lang of
    0:    result:= '&Run';
    1:    result:= '&Запуск';
    end;
    exit;
    end;
  210: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= '&New Project...';
    1:    result:= '&Создать проект...';
    end;
    exit;
    end;
  211: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= '&Open...';
    1:    result:= '&Открыть...';
    end;
    exit;
    end;
  212: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= '&Close';
    1:    result:= '&Закрыть';
    end;
    exit;
    end;
  213: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= '&Save';
    1:    result:= 'Сохрнит&ь';
    end;
    exit;
    end;
  214: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= 'Save &As...';
    1:    result:= 'Сохранить &как...';
    end;
    exit;
    end;
  215: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= 'E&xit';
    1:    result:= '&Выход';
    end;
    exit;
    end;
  216: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= '&Export ASM file...';
    1:    result:= '&Экспортировать файл ASM...';
    end;
    exit;
    end;
  217: //Главное меню программы - Файл
    begin
    case Lang of
    0:    result:= 'Export Intel &HEX file...';
    1:    result:= 'Экс&портировать файл Intel HEX...';
    end;
    exit;
    end;
  230: //Главное меню программы - Правка
    begin
    case Lang of
    0:    result:= 'Cu&t';
    1:    result:= 'В&ырезать';
    end;
    exit;
    end;
  231: //Главное меню программы - Правка
    begin
    case Lang of
    0:    result:= '&Copy';
    1:    result:= '&Копировать';
    end;
    exit;
    end;
  232: //Главное меню программы - Правка
    begin
    case Lang of
    0:    result:= '&Paste';
    1:    result:= '&Вставить';
    end;
    exit;
    end;
  250: //Главное меню программы - Окна
    begin
    case Lang of
    0:    result:= '&Cascade';
    1:    result:= '&Каскадом';
    end;
    exit;
    end;
  251: //Главное меню программы - Окна
    begin
    case Lang of
    0:    result:= 'Tile &Horizontally';
    1:    result:= 'Плиткой &горизонтально';
    end;
    exit;
    end;
  252: //Главное меню программы - Окна
    begin
    case Lang of
    0:    result:= 'Tile &Vertically';
    1:    result:= 'Плиткой &вертикально';
    end;
    exit;
    end;
  253: //Главное меню программы - Окна
    begin
    case Lang of
    0:    result:= '&Minimize All';
    1:    result:= '&Свернуть все';
    end;
    exit;
    end;
  254: //Главное меню программы - Окна
    begin
    case Lang of
    0:    result:= '&Arrange All';
    1:    result:= '&Развернуть все';
    end;
    exit;
    end;
  270: //Главное меню программы - Опции
    begin
    case Lang of
    0:    result:= 'Configuration &Bits';
    1:    result:= '&Биты конфигурации...';
    end;
    exit;
    end;
  290: //Главное меню программы - Справка
    begin
    case Lang of
    0:    result:= '&Check for Updates...';
    1:    result:= '&Проверить обновления...';
    end;
    exit;
    end;
  291: //Главное меню программы - Справка
    begin
    case Lang of
    0:    result:= '&Bug Report form...';
    1:    result:= 'Отправить отчет об о&шибке...';
    end;
    exit;
    end;
  292: //Главное меню программы - Справка
    begin
    case Lang of
    0:    result:= '&About...';
    1:    result:= '&О программе...';
    end;
    exit;
    end;
  293: //Главное меню программы - Справка
    begin
    case Lang of
    0:    result:= '&Donate (why?)...';
    1:    result:= '&Пожертвовать (зачем?)...';
    end;
    exit;
    end;
  294: //Главное меню программы - Справка
    begin
    case Lang of
    0:    result:= 'Find help online';
    1:    result:= 'Найти справку онлайн';
    end;
    exit;
    end;

  300: //Главное меню программы - RUN
    begin
    case Lang of
    0:    result:= 'R&ate';
    1:    result:= '&Скорость симуляции';
    end;
    exit;
    end;
  301: //Главное меню программы - RUN
    begin
    case Lang of
    0:    result:= '&Run';
    1:    result:= '&Запуск';
    end;
    exit;
    end;
  302: //Главное меню программы - RUN
    begin
    case Lang of
    0:    result:= '&Pause';
    1:    result:= '&Пауза';
    end;
    exit;
    end;
  303: //Главное меню программы - RUN
    begin
    case Lang of
    0:    result:= '&Stop';
    1:    result:= '&Стоп';
    end;
    exit;
    end;
  304: //Главное меню программы - RUN
    begin
    case Lang of
    0:    result:= 'S&tep';
    1:    result:= '&Шаг';
    end;
    exit;
    end;
  305: //Главное меню программы - RUN
    begin
    case Lang of
    0:    result:= '&Clear all breakpoints';
    1:    result:= 'О&чистить все точки останова';
    end;
    exit;
    end;
  320: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= '&Step By Step';
    1:    result:= '&Шаг за шагом';
    end;
    exit;
    end;
  321: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= '&Very Slow';
    1:    result:= '&Очень медленно';
    end;
    exit;
    end;
  322: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= 'S&low';
    1:    result:= '&Медленно';
    end;
    exit;
    end;
  323: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= '&Normal';
    1:    result:= '&Нормально';
    end;
    exit;
    end;
  324: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= '&Fast';
    1:    result:= '&Быстро';
    end;
    exit;
    end;
  325: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= 'V&ery Fast';
    1:    result:= 'О&чень быстро';
    end;
    exit;
    end;
  326: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= '&Real Time';
    1:    result:= '&В реальном времени';
    end;
    exit;
    end;
  327: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= 'X&2';
    1:    result:= 'X&2';
    end;
    exit;
    end;
  328: //Главное меню программы - RUN -> Rate
    begin
    case Lang of
    0:    result:= '&Ultimate';
    1:    result:= '&Максимальная скорость';
    end;
    exit;
    end;
  329: //Главное меню программы - Option -> Options
    begin
    case Lang of
    0:    result:= '&Options';
    1:    result:= '&Опции';
    end;
    exit;
    end;
  400: //frmOpen
    begin
    case Lang of
    0:    result:= 'Select Microcontroller';
    1:    result:= 'Выберите микроконтроллер';
    end;
    exit;
    end;
  401: //frmOpen
    begin
    case Lang of
    0:    result:= 'Architecture:';
    1:    result:= 'Архитектура:';
    end;
    exit;
    end;
  402: //frmOpen
    begin
    case Lang of
    0:    result:= 'Model:';
    1:    result:= 'Модель:';
    end;
    exit;
    end;
  403: //frmOpen
    begin
    case Lang of
    0:    result:= 'Not available in this version';
    1:    result:= 'Недоступно в данной версии';
    end;
    exit;
    end;


  500: //Options
    begin
    case Lang of
    0:    result:= 'Language';
    1:    result:= 'Язык';
    end;
    exit;
    end;
  //Сообщения об ошибках, предупреждения
  1000:
    begin
    case Lang of
    0:    result:= 'Declared in the project file model of the microcontroller is not supported. Please select a different model of the microcontroller.';
    1:    result:= 'Объявленная в файле проекта модель микроконтроллера не поддерживается. Пожалуйста, выберите другую модель микроконтроллера.';
    end;
      exit;
    end;

  1001:
    begin
     case Lang of
    0:    result:= 'Unknow device';
    1:    result:= 'Неизвестное устройство';
    end;

      exit;
    end;
  1010:
        begin
     case Lang of
    0:    result:= 'Error open file';
    1:    result:= 'Ошибка открытия файла';
    end;

      exit;
    end;
   1011:
        begin
     case Lang of
    0:    result:= 'Error save to file';
    1:    result:= 'Ошибка сохранения в файл';
    end;

      exit;
    end;
  1020:
          begin
     case Lang of
    0:    result:= 'Too many parameters';
    1:    result:= 'Слишком много параметров';
    end;

      exit;
    end;
    1021:
          begin
     case Lang of
    0:    result:=  'Not enough actual parameters';
    1:    result:= 'Не хватает параметров';
    end;

      exit;
    end;
    1022:
              begin
     case Lang of
    0:    result:=  'Byte value out of range (0..255)';
    1:    result:= 'Байтовое значение вне диапазона (0..255)';
    end;

      exit;
    end;
    1023:

    begin
     case Lang of
    0:    result:=  'Undeclared identifier';
    1:    result:= 'Необъявленный идентификатор';
    end;

      exit;
    end;
      1024:

    begin
     case Lang of
    0:    result:=  'Wrong identifier';
    1:    result:= 'Неверный идентификатор';
    end;

      exit;
    end;
          1025:

    begin
     case Lang of
    0:    result:=  'Value out of range';
    1:    result:= 'Значение вне диапазона';
    end;

      exit;
    end;

             1026:

    begin
     case Lang of
    0:    result:=  'Incorrect record';
    1:    result:= 'Неверная запись';
    end;

      exit;
    end;
                 1027:

    begin
     case Lang of
    0:    result:=  'Incorrect label';
    1:    result:= 'Неверная метка';
    end;

      exit;
    end;
               1028:

    begin
     case Lang of
    0:    result:=  'The programm is too long. Please select another microcontroller, or optimize the program.';
    1:    result:= 'Программа слишком большая. Пожалуйста, выберите другой микроконтроллер или оптимизируйте программу';
    end;

      exit;
    end;

                   1029:

    begin
     case Lang of
    0:    result:=  'Identifier redeclared';
    1:    result:= 'Идентификатор уже объявлен';
    end;

      exit;
    end;
    1030:

    begin
     case Lang of
    0:    result:=  'Is not digit';
    1:    result:= 'Это не цифра';
    end;

      exit;
    end;
     1031:

    begin
     case Lang of
    0:    result:=  'Unknown label';
    1:    result:= 'Неизвестная метка';
    end;

      exit;
    end;

  1100:
    begin
         case Lang of
    0:    result:= 'Save changes to project?';
    1:    result:= 'Сохранить изменения в проект?';
    end;

      exit;
    end;
  1150:
    begin
         case Lang of
    0:    result:= 'Wrong format of .hex file';
    1:    result:= 'Неверный формат .hex файла';
    end;

      exit;
    end;

      1151:
    begin
         case Lang of
    0:    result:= 'Line';
    1:    result:= 'Строка';
    end;

      exit;
    end;
      1152:
    begin
         case Lang of
    0:    result:= 'to short';
    1:    result:= 'слишком короткая';
    end;

      exit;
    end;

    1153:
        begin
         case Lang of
    0:    result:= 'missing ":"';
    1:    result:= 'отсутствует ":"';
    end;

      exit;
    end;

        1154:
        begin
         case Lang of
    0:    result:= 'this is not a hex data';
    1:    result:= 'это не hex данные';
    end;

      exit;
    end;
            1155:
        begin
         case Lang of
    0:    result:= 'missing end';
    1:    result:= 'отсутствует конец';
    end;

      exit;
        end;
                1156:
        begin
         case Lang of
    0:    result:= 'this is not for a this microcontroller';
    1:    result:= 'это не для этого микроконтроллера';
    end;

      exit;
    end;



  2000: //Начальная инициализация
    begin
         case Lang of
    0:    result:= 'Start initialization';
    1:    result:= 'Начальная инициализация';
    end;
      exit;
    end;
  2001: //Проверка регистрации
    begin
             case Lang of
    0:    result:= 'Checking registration';
    1:    result:= 'Проверка регистрации';
    end;

      exit;
    end;
  2002: //Поиск файлов устройств
    begin
    case Lang of
    0:    result:=  'Search for device files';
    1:    result:=  'Поиск библиотек устройств';
    end;
      exit;
    end;
  2003: //Загрузка файлов устройств
    begin
    case Lang of
    0:    result:= 'Loading device files:';
    1:    result:= 'Загрузка библиотеки устройств:';
    end;
      exit;
    end;
  2010: // Выбирите верную модель устройства
    begin
    case Lang of
    0:    result:= 'Select a valid device model';
    1:    result:= 'Выбирите верную модель устройства';
    end;
      exit;
    end;

  2020: //Sec
      begin
    case Lang of
    0:    result:= 'Sec';
    1:    result:= 'Сек';
    end;
      exit;
    end;
  2025: //Click to set breakpoint on change
      begin
    case Lang of
    0:    result:= 'Click to set breakpoint on change register';
    1:    result:= 'Щелкните для установки точки останова, при изменении регистра';
    end;
      exit;
    end;
    2026: //Red Delta - on change value; Green - on write in register and not change value
      begin
    case Lang of
    0:    result:= 'Red Delta - on change value; Green - on write in register and not change value';
    1:    result:= 'Красная дельта - при изменении значения; Зеленая дельта - при записи в регистр, но значение от того не поменялось';
    end;
      exit;
    end;
    2027: //Red Delta - on change value; Green - on write in register and not change value
      begin
    case Lang of
    0:    result:= 'The project was successfully saved';
    1:    result:= 'Проект был успешно сохранен';
    end;
      exit;
    end;

    2050: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Your report recieved to server';
    1:    result:= 'Ваш отчет был отправлен на сервер';
    end;
      exit;
    end;
    2051: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Error connecting to server';
    1:    result:= 'Ошибка соединения с сервером';
    end;
      exit;
    end;
      2052: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Connectiong to server';
    1:    result:= 'Соединение с сервером';
    end;
      exit;
    end;
    2053: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Error connecting to MySQL server';
    1:    result:= 'Ошибка соединения с MySQL сервером';
    end;
      exit;
    end;
    2054: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Error querying database';
    1:    result:= 'Ошибка запроса к базе данных';
    end;
      exit;
    end;
    2055: //Web-модуль
      begin
    case Lang of
    0:    result:= 'You are using the latest version';
    1:    result:= 'Вы используете последнюю версию';
    end;
      exit;
    end;
    2056: //Web-модуль
      begin
    case Lang of
    0:    result:= 'The new version is already available';
    1:    result:= 'Новая версия сейчас доступна';
    end;
      exit;
    end;
    2057: //Web-модуль
      begin
    case Lang of
    0:    result:= 'The latest version is';
    1:    result:= 'Последняя версия';
    end;
      exit;
    end;
    2058: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Version history list';
    1:    result:= 'История версий';
    end;
      exit;
    end;
    2059: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Not enough resources';
    1:    result:= 'Не хватает ресурсов';
    end;
      exit;
    end;
    2060: //Web-модуль
      begin
    case Lang of
    0:    result:= 'File not found';
    1:    result:= 'Не найден файл';
    end;
      exit;
    end;
    2061: //Web-модуль
      begin
    case Lang of
    0:    result:= 'Path not found';
    1:    result:= 'Не найден путь';
    end;
      exit;
    end;
    2100: //Shareware-модуль (Или эксплойт)
    begin
    case Lang of
    0:    result:= 'The version is outdated. Please update the program by visiting <a href="http://at-control.com/downloads.html"> at-control.com </a>.';
    1:    result:= 'Используемая версия сильно устарела. Пожалуйста, обновите программу посетив сайт <a href="http://at-control.com/downloads.html">at-control.com</a>.';
    end;
    exit;
    end;

    3000: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'Counters and Instructions';
    1:    result:= 'Счетчики и инструкции';
    end;
    exit;
    end;
    3001: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'Last Instruction:';
    1:    result:= 'Пред. инструкция:';
    end;
    exit;
    end;
    3002: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'Next Instruction:';
    1:    result:= 'След. инструкция:';
    end;
    exit;
    end;
    3003: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'Instruction Counter';
    1:    result:= 'Выполн. инструкций';
    end;
    exit;
    end;
    3004: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'Machine Cycles';
    1:    result:= 'Машинных циклов';
    end;
    exit;
    end;
    3005: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'Real Time Duration';
    1:    result:= 'В реальном времени прошло';
    end;
    exit;
    end;
    3006: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'Real Time Rate';
    1:    result:= 'Скорость от реал.';
    end;
    exit;
    end;
    3007: // Panel Counters and Instructions
    begin
    case Lang of
    0:    result:= 'User Timer';
    1:    result:= 'Польз. тайм.';
    end;
    exit;
    end;
    3020: // Panel Timers and Stack
    begin
    case Lang of
    0:    result:= 'Hardware Timers and Stack';
    1:    result:= 'Аппаратные таймеры и стек';
    end;
    exit;
    end;
    3021: // Panel Timers and Stack
    begin
    case Lang of
    0:    result:= 'WDT filling';
    1:    result:= 'Заполн. WDT';
    end;
    exit;
    end;
    3022: // Panel Timers and Stack
    begin
    case Lang of
    0:    result:= 'Stack Counter';
    1:    result:= 'Счетчик стека';
    end;
    exit;
    end;
    3040: // SFR
    begin
    case Lang of
    0:    result:= 'Special Function Registers';
    1:    result:= 'Специальные регистры (SFR)';
    end;
    exit;
    end;
    3060: // GPR
    begin
    case Lang of
    0:    result:= 'General Purpose Registers';
    1:    result:= 'Регистры общего назн. (GPR)';
    end;
    exit;
    end;
    3100: // frmBugReport
        begin
    case Lang of
    0:    result:= 'User Name:';
    1:    result:= 'Ваше имя:';
    end;
    exit;
    end;
    3101: // frmBugReport
        begin
    case Lang of
    0:    result:= 'E-mail adress:';
    1:    result:= 'Адрес e-mail:';
    end;
    exit;
    end;
    3102: // frmBugReport
        begin
    case Lang of
    0:    result:= 'Enter your report here';
    1:    result:= 'Введите здесь описание ошибки';
    end;
    exit;
    end;
    3120: // frmNodes
        begin
    case Lang of
    0:    result:= 'Pin';
    1:    result:= 'Вывод';
    end;
    exit;
    end;
    3121: // frmNodes
        begin
    case Lang of
    0:    result:= 'Node';
    1:    result:= 'Узел';
    end;
    exit;
    end;
    3150: // frmCheckUpdates
        begin
    case Lang of
    0:    result:= 'Check for updates at startup';
    1:    result:= 'Проверять обновления при запуске';
    end;
    exit;
    end;
    3500: //Другое
        begin
    case Lang of
    0:    result:= 'Version';
    1:    result:= 'Версия';
    end;
    exit;
    end;
    4000: // Hint
    begin
    case Lang of
    0:    result:= 'New Project|Create a new project';
    1:    result:= 'Новый проект|Создать новый проект';
    end;
    exit;
    end;
    4001: // Hint
    begin
    case Lang of
    0:    result:= 'Open|Open a file';
    1:    result:= 'Открыть|Открыть файл';
    end;
    exit;
    end;
    4002: // Hint
    begin
    case Lang of
    0:    result:= 'Close|Close current project';
    1:    result:= 'Закрыть|Закрыть текущий проект';
    end;
    exit;
    end;
        4003: // Hint
    begin
    case Lang of
    0:    result:= 'Save|Save current project';
    1:    result:= 'Сохранить|Сохранить текущий проект';
    end;
    exit;
    end;
        4004: // Hint
    begin
    case Lang of
    0:    result:= 'Save As|Save current project with different name';
    1:    result:= 'Сохранить как|Сохранить текущий проект в другой файл';
    end;
    exit;
    end;
        4005: // Hint
    begin
    case Lang of
    0:    result:= 'Exit|Exit application';
    1:    result:= 'Выход|Выход из программы';
    end;
    exit;
    end;
        4006: // Hint
    begin
    case Lang of
    0:    result:= 'Export ASM|Export to file only assembler text';
    1:    result:= 'Экспорт ASM|Экспортировать в файл только текст программы';
    end;
    exit;
    end;
        4007: // Hint
    begin
    case Lang of
    0:    result:= 'Export Hex|Export to file firmware in Intel HEX format';
    1:    result:= 'Экспортировать в файл прошивку в формате Intel HEX';
    end;
    exit;
    end;
        4008: // Hint
    begin
    case Lang of
    0:    result:= 'Cut|Cuts the selection and puts it on the Clipboard';
    1:    result:= 'Вырезать|Вырезать выделенное в буфер обмена';
    end;
    exit;
    end;
        4009: // Hint
    begin
    case Lang of
    0:    result:= 'Copy|Copies the selection and puts it on the Clipboard';
    1:    result:= 'Копировать|Копировать выделенное в буфер обмена';
    end;
    exit;
    end;
        4010: // Hint
    begin
    case Lang of
    0:    result:= 'Paste|Inserts Clipboard contents';
    1:    result:= 'Вставить|Вставляет содержимое из буфера обмена';
    end;
    exit;
    end;
        4011: // Hint
    begin
    case Lang of
    0:    result:= 'About|Displays program information, version number, and copyright';
    1:    result:= 'О программе|Показать информацию о программе, версию и авторские права';
    end;
    exit;
    end;
        4012: // Hint
    begin
    case Lang of
    0:    result:= 'Cascade';
    1:    result:= 'Расположить окна каскадом';
    end;
    exit;
    end;
        4013: // Hint
    begin
    case Lang of
    0:    result:= 'Tile Horizontally';
    1:    result:= 'Расположить окна плиткой горизонтально';
    end;
    exit;
    end;
        4014: // Hint
    begin
    case Lang of
    0:    result:= 'Tile Vertically';
    1:    result:= 'Расположить окна плиткой вертикально';
    end;
    exit;
    end;
        4015: // Hint
    begin
    case Lang of
    0:    result:= 'Minimize All';
    1:    result:= 'Свернуть все окна';
    end;
    exit;
    end;
        4016: // Hint
    begin
    case Lang of
    0:    result:= 'Arrange All';
    1:    result:= 'Восстановить все окна';
    end;
    exit;
    end;
        4017: // Hint
    begin
    case Lang of
    0:    result:= 'Bug report|Send bug report to developer';
    1:    result:= 'Отчет об ошибке|Отправить разработчику отчет об обнаруженной ошибке';
    end;
    exit;
    end;
        4018: // Hint
    begin
    case Lang of
    0:    result:= 'Check for updates';
    1:    result:= 'Проверить обновления';
    end;
    exit;
    end;
            4019: // Hint
    begin
    case Lang of
    0:    result:= 'Rate|It enables user to change the simulation rate';
    1:    result:= 'Скорость симуляции|Позволяет изменять скорость симуляции';
    end;
    exit;
    end;
            4020: // Hint
    begin
    case Lang of
    0:    result:= 'The interval between consecutive instructions is at user will';
    1:    result:= 'Интервал между инструкциями определяет пользователь';
    end;
    exit;
    end;
            4021: // Hint
    begin
    case Lang of
    0:    result:= 'The interval is 2000 ms (enabled synchronization with the main sumulator window)';
    1:    result:= 'Интервал между инструкциями 2000 мс (включена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4022: // Hint
    begin
    case Lang of
    0:    result:= 'The interval is 1000 ms (enabled synchronization with the main sumulator window)';
    1:    result:= 'Интервал между инструкциями 1000 мс (включена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4023: // Hint
    begin
    case Lang of
    0:    result:= 'The interval is 500 ms (enabled synchronization with the main sumulator window)';
    1:    result:= 'Интервал между инструкциями 500 мс (включена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4024: // Hint
    begin
    case Lang of
    0:    result:= 'The interval is 100 ms (enabled synchronization with the main sumulator window)';
    1:    result:= 'Интервал между инструкциями 100 мс (включена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4025: // Hint
    begin
    case Lang of
    0:    result:= 'The interval is 10 ms (enabled synchronization with the main sumulator window)';
    1:    result:= 'Интервал между инструкциями 10 мс (включена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4026: // Hint
    begin
    case Lang of
    0:    result:= 'The interval corresponds to the real device (disabled synchronization with the main sumulator window)';
    1:    result:= 'Интервал между инструкциями как в реальном устройстве (выключена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4027: // Hint
    begin
    case Lang of
    0:    result:= 'The interval corresponds to the real device x 2 (disabled synchronization with the main sumulator window)';
    1:    result:= 'Интервал между инструкциями как в реальном устройстве x 2 (выключена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4028: // Hint
    begin
    case Lang of
    0:    result:= 'Without limitation (disabled synchronization with the main sumulator window)';
    1:    result:= 'Без ограничений (выключена синхронизация с главным окном симулятора)';
    end;
    exit;
    end;
            4040: // Hint
    begin
    case Lang of
    0:    result:= 'Run|Start the simulation';
    1:    result:= 'Запуск|Начать симуляцию';
    end;
    exit;
    end;
            4041: // Hint
    begin
    case Lang of
    0:    result:= 'Pause|Suspend the simulation';
    1:    result:= 'Пауза|Приостановить симуляцию';
    end;
    exit;
    end;
            4042: // Hint
    begin
    case Lang of
    0:    result:= 'Stop|Stop the simulation';
    1:    result:= 'Стоп|Остановить симуляцию';
    end;
    exit;
    end;

                4044: // Hint
    begin
    case Lang of
    0:    result:= 'Step|Execute the next instruction';
    1:    result:= 'Шаг|Выполнить следующую инструкцию';
    end;
    exit;
    end;

                    4050: // Hint
    begin
    case Lang of
    0:    result:= 'Configuration Bits|Allows to change the configuration bits of the microcontroller';
    1:    result:= 'Биты конфигурации|Позволяет изменить биты конфигурации микроконтроллера';
    end;
    exit;
    end;

end;
End;

end.
