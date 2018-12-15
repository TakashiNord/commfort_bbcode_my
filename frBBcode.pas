unit frBBcode;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls,
  Clipbrd;

type
  TBBcodeForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ButtonAllClick(Sender: TObject ; mode: integer);
  end;

var
  BBcodeForm: TBBcodeForm;

implementation

{$R *.dfm}


procedure TBBcodeForm.ButtonAllClick(Sender: TObject ; mode: integer);
var
    s : WideString ; // UnicodeString  WideString
    H: THandle;
    TWPtr: PWideChar;
    ChatWindow : HWND; //Главное окно чата
    ChannelEdit : HWND;
    id, i : integer ;
    selFirst , selLast : integer ;
begin
  ChatWindow:=BBcodeForm.ParentWindow ;

 // получаем хендл текущего окна
  ChannelEdit := 0 ;

  ChannelEdit := FindWindowEx(ChatWindow, ChannelEdit, 'TRichViewEdit', nil);
  id:=integer(IsWindowVisible(ChannelEdit));
  while ((ChannelEdit <> 0) or (id=0) ) do begin
    ChannelEdit := FindWindowEx(ChatWindow, ChannelEdit, 'TRichViewEdit', nil);
    if ChannelEdit <> 0 then begin
       id:=integer(IsWindowVisible(ChannelEdit));
       if (id=1) then Break ;
    end;
  end;

  selFirst:= 0;
  selLast := 0;
  SendMessage(ChannelEdit, EM_GETSEL, Longint(@selFirst), Longint(@selLast) );
  if (selFirst = selLast) then exit ;

  // Copy to Clipboard - WM_COPY   WM_CUT   EM_GETTEXTRANGE
  SendMessage(ChannelEdit, WM_COPY, 0, 0);


 if Clipboard.HasFormat(CF_BITMAP) then begin
  // Clear the Selection
  Clipboard.clear ;
  Exit ;
 end;

  S:='' ;

  ClipBoard.Open;
try
 if Clipboard.HasFormat(CF_UNICODETEXT) then begin
   H := Clipboard.GetAsHandle(CF_UNICODETEXT);
   TWPtr := GlobalLock(H);
   S := WideCharToString(TWPtr);
   GlobalUnlock(H);
  end
  else begin
    if Clipboard.HasFormat(CF_TEXT) then S:=Clipboard.AsText ;
  end;
 finally
  Clipboard.clear ;
  Clipboard.Close;
end;

  //if (Length(S)<>0) then begin
    case mode of
      0: S:='[b]' + S + '[/b]' ;
      1: S:='[u]' + S + '[/u]' ;
      2: S:='[i]' + S + '[/i]' ;
      3: S:='[s]' + S + '[/s]' ;
      4: S:='[url]' + S + '[/url]' ;
      5: begin
           Exit ;
         end;
    end;
    //SendMessage(ChannelEdit, EM_SETSEL, 0, -1); // выделение всего
    //SendMessage(ChannelEdit, EM_SETSEL, -1, 0); // снятие
    SendMessage(ChannelEdit, EM_SETSEL, selFirst, selLast);
    SendMessage(ChannelEdit, WM_CLEAR, 0, 0 );
    for i := 1 to Length(s) do
    begin
      SendMessage(ChannelEdit, WM_CHAR, Ord(s[i]), 0);
    end;

    // WM_SETFOCUS SetWindowFocus SetFocus
    SendMessage(ChannelEdit, WM_SETFOCUS, 1, 0);
  //end ;


end;


procedure TBBcodeForm.Button1Click(Sender: TObject);
begin
 ButtonAllClick(Sender, 0);
end;

procedure TBBcodeForm.Button2Click(Sender: TObject);
begin
 ButtonAllClick(Sender, 1);
end;

procedure TBBcodeForm.Button3Click(Sender: TObject);
begin
 ButtonAllClick(Sender, 2);
end;

procedure TBBcodeForm.Button4Click(Sender: TObject);
begin
 ButtonAllClick(Sender, 3);
end;

procedure TBBcodeForm.Button5Click(Sender: TObject);
begin
  ButtonAllClick(Sender, 4);
end;

end.
