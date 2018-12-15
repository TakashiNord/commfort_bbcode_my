unit main;

interface

uses Windows, Classes, SysUtils, Dialogs ,
     Buttons, Graphics, Controls,
     CommCtrl, ComCtrls, StdCtrls,
     messages, Types,
     frBBcode ;

type
  TCommFortProcess = procedure(dwPluginID : DWORD; dwID: DWORD; bOutBuffer : PAnsiChar; dwOutBufferSize : DWORD); stdcall;
  TCommFortGetData = function(dwPluginID : DWORD; dwID : DWORD; bInBuffer : PAnsiChar; dwInBufferSize : DWORD; bOutBuffer : PAnsiChar; dwOutBufferSize : DWORD): DWORD; stdcall;

	
function  PluginStart(dwThisPluginID : DWORD; func1 : TCommFortProcess; func2 : TCommFortGetData) : Integer; cdecl; stdcall;
procedure PluginStop(); cdecl; stdcall;
procedure PluginShowOptions(); cdecl; stdcall;
procedure PluginShowAbout(); cdecl; stdcall;
procedure PluginProcess(dwID : DWORD; bInBuffer : PAnsiChar; dwInBufferSize : DWORD); cdecl; stdcall;
function  PluginGetData(dwID : DWORD; bInBuffer : PAnsiChar;
            dwInBufferSize : DWORD; bOutBuffer : PAnsiChar; dwOutBufferSize : DWORD): DWORD; cdecl; stdcall;
//function  PluginPremoderation(dwID : DWORD; wText : PWideChar; var dwTextLength : DWORD):  Integer; cdecl; stdcall;

function  fReadInteger(bInBuffer : PAnsiChar; var iOffset : Integer): Integer;
function  fReadText(bInBuffer : PAnsiChar; var iOffset : Integer): WideString;
procedure fWriteInteger(var bOutBuffer : PAnsiChar; var iOffset  : Integer; iValue : Integer);
procedure fWriteText(bOutBuffer : PAnsiChar; var iOffset  : Integer; uValue : WideString);
function  fTextToAnsiString(uText : WideString) : AnsiString;
function  fIntegerToAnsiString(iValue : Integer) : AnsiString;

exports PluginStart, PluginStop, PluginProcess, PluginGetData, PluginShowOptions, PluginShowAbout;
//PluginPremoderation;

var
  dwPluginID : DWORD;
  CommFortProcess : TCommFortProcess;
  CommFortGetData : TCommFortGetData;

  ChatWindow : HWND;

implementation

//---------------------------------------------------------------------------
function fReadInteger(bInBuffer : PAnsiChar; var iOffset : Integer): Integer; //вспомогательная функция для упрощения работы с чтением данных
begin
	CopyMemory(@Result, bInBuffer + iOffSet, 4);
	iOffset := iOffset + 4;
end;

function fReadText(bInBuffer : PAnsiChar; var iOffset : Integer): WideString; //вспомогательная функция для упрощения работы с чтением данных
 var iLength : Integer;
begin
	CopyMemory(@iLength, bInBuffer + iOffSet, 4);
	iOffset := iOffset + 4;
	SetLength(Result, iLength);
	CopyMemory(@Result[1], bInBuffer + iOffSet, iLength * 2);
	iOffset := iOffset + iLength * 2;
end;

//---------------------------------------------------------------------------
procedure fWriteInteger(var bOutBuffer : PAnsiChar; var iOffset  : Integer; iValue : Integer); //вспомогательная функция для упрощения работы с записью данных
begin
	CopyMemory(bOutBuffer + iOffSet, @iValue, 4);
	iOffset := iOffset + 4;
end;
//---------------------------------------------------------------------------
procedure fWriteText(bOutBuffer : PAnsiChar; var iOffset  : Integer; uValue : WideString); //вспомогательная функция для упрощения работы с записью данных
	var iLength : Integer;
begin
	iLength := Length(uValue);
	CopyMemory(bOutBuffer + iOffset, @iLength, 4);
	iOffset := iOffset + 4;

	CopyMemory(bOutBuffer + iOffSet, @uValue[1], iLength * 2);
	iOffset := iOffset + iLength * 2;
end;

//---------------------------------------------------------------------------
function fTextToAnsiString(uText : WideString) : AnsiString; //вспомогательная функция для упрощения работы с данными
	var iLength : Integer;
begin
	//функция предназначена для ознакомительных целей,
	//не рекомендуется для реального применения,
	//так как при ее использовании проявляется избыточное копирование данных
	iLength := Length(uText);

	SetLength(Result, 4 + iLength * 2);

	CopyMemory(@Result[1], @iLength, 4);
	CopyMemory(PAnsiChar(Result) + 4, @uText[1], iLength * 2);
end;
//---------------------------------------------------------------------------
function fIntegerToAnsiString(iValue : Integer) : AnsiString; //вспомогательная функция для упрощения работы с данными
begin
	//функция предназначена для ознакомительных целей,
	//не рекомендуется для реального применения,
	//так как при ее использовании проявляется избыточное копирование данных

	SetLength(Result, 4);
	CopyMemory(@Result[1], @iValue, 4);
end;
//---------------------------------------------------------------------------


{start plugin}
function PluginStart(dwThisPluginID : DWORD; func1 : TCommFortProcess; func2 : TCommFortGetData) : Integer;
var
   dwId : DWORD ;
   dwProcessId : DWORD ;
   iSize, iReadOffset  : integer ;
   aData : WideString ;
   Rect : TRect ;
begin
	dwPluginID := dwThisPluginID;
	//При инициализации планину присваивается уникальный идентификатор
	//его необходимо обязательно сохранить, и указывать
	//в качестве первого параметра при инициировании событий
	CommFortProcess := func1;
        //указываем функцию обратного вызова,
	//с помощью которой плагин сможет инициировать события

	CommFortGetData := func2;
  //указываем функцию обратного вызова,
	//с помощью которой можно будет запрашивать необходимые данные от программы

  //Возвращаемые значения:
	//TRUE - запуск прошел успешно
	//FALSE - запуск невозможен
	Result := Integer(TRUE);

  //Находим нужные нам окна
  dwId := GetCurrentProcessId();
  ChatWindow := 0;
  while ( (dwId<>dwProcessId) And (ChatWindow=0) )  do begin
    ChatWindow := FindWindowExW(0, ChatWindow, 'TfChatClient', nil);
    GetWindowThreadProcessId(ChatWindow, @dwProcessId);
  end ;

  if (ChatWindow = 0) then
   begin Result := Integer(FALSE) ; exit ; end ;

 
  iReadOffset := 0;
  iSize := CommFortGetData(dwPluginID, 2010, nil, 0, nil, 0); //получаем объем буфера
  SetLength(aData, iSize);
  CommFortGetData(dwPluginID, 2010, PAnsiChar(aData), iSize, nil, 0);//заполняем буфер

  GetWindowRect( ChatWindow, Rect );
  BBcodeForm := TBBcodeForm.Create(nil);
  BBcodeForm.ParentWindow := ChatWindow;
  //BBcodeForm.Left:= 50 ; // Rect.Right - 100 ;
  //BBcodeForm.Top:= 100; // Rect.Bottom - 100 ;
  try
   BBcodeForm.Show;
  finally
   ;
  end;


end;
//---------------------------------------------------------------------------
procedure PluginStop();
begin
  //данная функция вызывается при завершении работы плагина
  //if Assigned(BBcodeForm) then begin
    BBcodeForm.Close ;
    BBcodeForm.Free ;
    //FreeAndNil(BBcodeForm);
  //end;
end;
//---------------------------------------------------------------------------
procedure PluginProcess(dwID : DWORD; bInBuffer : PAnsiChar; dwInBufferSize : DWORD);
begin
	//Функция приема событий
	//Параметры:
	//dwID - идентификатор события
	//bInBuffer - указатель на данные
	//dwInBufferSize - объем данных в байтах

  if (dwID=3) then begin
   // ShowMessage('3');

  end;
  if (dwID=9) then begin
   // ShowMessage('9');

  end;
  if (dwID=30) then begin
   // ShowMessage('30');

  end;

end;
//---------------------------------------------------------------------------
function PluginGetData(dwID : DWORD; bInBuffer : PAnsiChar; dwInBufferSize : DWORD; bOutBuffer : PAnsiChar; dwOutBufferSize : DWORD): DWORD;
var iWriteOffset, iSize : Integer; //вспомогательные переменные для упрощения работы с блоком данных
    uName : WideString;
begin

  //функция передачи данных программе
	iWriteOffset := 0;

	//при значении dwOutBufferSize равным нулю функция должна вернуть объем данных, ничего не записывая

	if (dwID = 2800) then //предназначение плагина
	begin
		if (dwOutBufferSize = 0) then
			Result := 4 //объем памяти в байтах, которую необходимо выделить программе
		else
		begin
			fWriteInteger(bOutBuffer, iWriteOffset, 2); //плагин подходит только для клиента
			Result := 4;//объем заполненного буфера в байтах
		end;
	end
	else
	if (dwID = 2810) then //название плагина (отображается в списке)
	begin
		uName := 'BBCode';//название плагина
		iSize := Length(uName) * 2 + 4;

		if (dwOutBufferSize = 0) then
			Result := iSize //объем памяти в байтах, которую необходимо выделить программе
		else
		begin
			fWriteText(bOutBuffer, iWriteOffset, uName);
			Result := iSize;//объем заполненного буфера в байтах
		end;
	end
	else
		Result := 0;//возвращаемое значение - объем записанных данных
end;

//---------------------------------------------------------------------------
procedure PluginShowOptions();
begin
	ShowMessage('Опций для настроек  - нет.');
end;

//---------------------------------------------------------------------------
procedure PluginShowAbout();
begin
	//данная функция вызывается при нажатии кнопки "О плагине" в списке плагинов
	ShowMessage('Плагин - BBCode.'
	 + #13#10 + 'Created for CommFort software Ltd.'
	 + #13#10 + 'Delphi, by Che'
	);
end;

end.
