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
function fReadInteger(bInBuffer : PAnsiChar; var iOffset : Integer): Integer; //��������������� ������� ��� ��������� ������ � ������� ������
begin
	CopyMemory(@Result, bInBuffer + iOffSet, 4);
	iOffset := iOffset + 4;
end;

function fReadText(bInBuffer : PAnsiChar; var iOffset : Integer): WideString; //��������������� ������� ��� ��������� ������ � ������� ������
 var iLength : Integer;
begin
	CopyMemory(@iLength, bInBuffer + iOffSet, 4);
	iOffset := iOffset + 4;
	SetLength(Result, iLength);
	CopyMemory(@Result[1], bInBuffer + iOffSet, iLength * 2);
	iOffset := iOffset + iLength * 2;
end;

//---------------------------------------------------------------------------
procedure fWriteInteger(var bOutBuffer : PAnsiChar; var iOffset  : Integer; iValue : Integer); //��������������� ������� ��� ��������� ������ � ������� ������
begin
	CopyMemory(bOutBuffer + iOffSet, @iValue, 4);
	iOffset := iOffset + 4;
end;
//---------------------------------------------------------------------------
procedure fWriteText(bOutBuffer : PAnsiChar; var iOffset  : Integer; uValue : WideString); //��������������� ������� ��� ��������� ������ � ������� ������
	var iLength : Integer;
begin
	iLength := Length(uValue);
	CopyMemory(bOutBuffer + iOffset, @iLength, 4);
	iOffset := iOffset + 4;

	CopyMemory(bOutBuffer + iOffSet, @uValue[1], iLength * 2);
	iOffset := iOffset + iLength * 2;
end;

//---------------------------------------------------------------------------
function fTextToAnsiString(uText : WideString) : AnsiString; //��������������� ������� ��� ��������� ������ � �������
	var iLength : Integer;
begin
	//������� ������������� ��� ��������������� �����,
	//�� ������������� ��� ��������� ����������,
	//��� ��� ��� �� ������������� ����������� ���������� ����������� ������
	iLength := Length(uText);

	SetLength(Result, 4 + iLength * 2);

	CopyMemory(@Result[1], @iLength, 4);
	CopyMemory(PAnsiChar(Result) + 4, @uText[1], iLength * 2);
end;
//---------------------------------------------------------------------------
function fIntegerToAnsiString(iValue : Integer) : AnsiString; //��������������� ������� ��� ��������� ������ � �������
begin
	//������� ������������� ��� ��������������� �����,
	//�� ������������� ��� ��������� ����������,
	//��� ��� ��� �� ������������� ����������� ���������� ����������� ������

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
	//��� ������������� ������� ������������� ���������� �������������
	//��� ���������� ����������� ���������, � ���������
	//� �������� ������� ��������� ��� ������������� �������
	CommFortProcess := func1;
        //��������� ������� ��������� ������,
	//� ������� ������� ������ ������ ������������ �������

	CommFortGetData := func2;
  //��������� ������� ��������� ������,
	//� ������� ������� ����� ����� ����������� ����������� ������ �� ���������

  //������������ ��������:
	//TRUE - ������ ������ �������
	//FALSE - ������ ����������
	Result := Integer(TRUE);

  //������� ������ ��� ����
  dwId := GetCurrentProcessId();
  ChatWindow := 0;
  while ( (dwId<>dwProcessId) And (ChatWindow=0) )  do begin
    ChatWindow := FindWindowExW(0, ChatWindow, 'TfChatClient', nil);
    GetWindowThreadProcessId(ChatWindow, @dwProcessId);
  end ;

  if (ChatWindow = 0) then
   begin Result := Integer(FALSE) ; exit ; end ;

 
  iReadOffset := 0;
  iSize := CommFortGetData(dwPluginID, 2010, nil, 0, nil, 0); //�������� ����� ������
  SetLength(aData, iSize);
  CommFortGetData(dwPluginID, 2010, PAnsiChar(aData), iSize, nil, 0);//��������� �����

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
  //������ ������� ���������� ��� ���������� ������ �������
  //if Assigned(BBcodeForm) then begin
    BBcodeForm.Close ;
    BBcodeForm.Free ;
    //FreeAndNil(BBcodeForm);
  //end;
end;
//---------------------------------------------------------------------------
procedure PluginProcess(dwID : DWORD; bInBuffer : PAnsiChar; dwInBufferSize : DWORD);
begin
	//������� ������ �������
	//���������:
	//dwID - ������������� �������
	//bInBuffer - ��������� �� ������
	//dwInBufferSize - ����� ������ � ������

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
var iWriteOffset, iSize : Integer; //��������������� ���������� ��� ��������� ������ � ������ ������
    uName : WideString;
begin

  //������� �������� ������ ���������
	iWriteOffset := 0;

	//��� �������� dwOutBufferSize ������ ���� ������� ������ ������� ����� ������, ������ �� ���������

	if (dwID = 2800) then //�������������� �������
	begin
		if (dwOutBufferSize = 0) then
			Result := 4 //����� ������ � ������, ������� ���������� �������� ���������
		else
		begin
			fWriteInteger(bOutBuffer, iWriteOffset, 2); //������ �������� ������ ��� �������
			Result := 4;//����� ������������ ������ � ������
		end;
	end
	else
	if (dwID = 2810) then //�������� ������� (������������ � ������)
	begin
		uName := 'BBCode';//�������� �������
		iSize := Length(uName) * 2 + 4;

		if (dwOutBufferSize = 0) then
			Result := iSize //����� ������ � ������, ������� ���������� �������� ���������
		else
		begin
			fWriteText(bOutBuffer, iWriteOffset, uName);
			Result := iSize;//����� ������������ ������ � ������
		end;
	end
	else
		Result := 0;//������������ �������� - ����� ���������� ������
end;

//---------------------------------------------------------------------------
procedure PluginShowOptions();
begin
	ShowMessage('����� ��� ��������  - ���.');
end;

//---------------------------------------------------------------------------
procedure PluginShowAbout();
begin
	//������ ������� ���������� ��� ������� ������ "� �������" � ������ ��������
	ShowMessage('������ - BBCode.'
	 + #13#10 + 'Created for CommFort software Ltd.'
	 + #13#10 + 'Delphi, by Che'
	);
end;

end.
