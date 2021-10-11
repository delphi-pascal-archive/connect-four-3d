{ **************************************************************************** }
{ Project: ConnectFour3D
{ Module:
{ Author:  Josef Schuetzenberger
{ E-Mail:  schutzenberger@hotmail.com
{ WWW:     http://members.fortunecity.com/schutzenberger/download/en.html#ConnectFour3D
{ **************************************************************************** }
{ Copyright ©2006 Josef Schuetzenberger
{ This programme is free software; you can redistribute it and/or modify it
{ under the terms of the GNU General Public License as published by the Free
{ Software Foundation; either version 2 of the License, or any later version.
{
{ This programme is distributed for educational purposes in the hope that it
{ will be useful, but WITHOUT ANY WARRANTY. See the GNU General Public License
{ for more details at http://www.gnu.org/licenses/gpl.html
{ **************************************************************************** }
unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ComCtrls, ToolWin, ImgList, SearchThread, ActnList,
  StdActns;

type
  TFormMain = class(TForm)
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    ToolButtonNewGame: TToolButton;
    ToolButtonLoadGame: TToolButton;
    ToolButton5: TToolButton;
    ToolButtonMoveBack: TToolButton;
    ToolButtonMoveForward: TToolButton;
    ToolButtonFindBoardScore: TToolButton;
    ToolButtonCancelComputerMove: TToolButton;
    ToolButton3: TToolButton;
    ImageList1: TImageList;
    ImageList2: TImageList;
    MainMenu: TMainMenu;
    ToolButton1: TToolButton;
    ToolButtonComputerMove: TToolButton;
    HumanVersComp: TMenuItem;
    HumanVersHuman: TMenuItem;
    Level1: TMenuItem;
    Level2: TMenuItem;
    Level3: TMenuItem;
    Level4: TMenuItem;
    Level5: TMenuItem;
    Level6: TMenuItem;
    Level7: TMenuItem;
    Level8: TMenuItem;
    Level9: TMenuItem;
    Level10: TMenuItem;
    Level11: TMenuItem;
    Level12: TMenuItem;
    Level13: TMenuItem;
    Level14: TMenuItem;
    Level15: TMenuItem;
    Level16: TMenuItem;
    Level17: TMenuItem;
    Level20: TMenuItem;
    Level25: TMenuItem;
    Level26: TMenuItem;
    Level30: TMenuItem;
    Level42: TMenuItem;
    AudibleAlert: TMenuItem;
    ActionList1: TActionList;
    MenuLoadGame: TAction;
    LoadGame1: TMenuItem;
    MenuNewGame: TAction;
    NewGame1: TMenuItem;
    MenuMoveBack: TAction;
    MenuFile: TMenuItem;
    MenuMoveForward: TAction;
    MenuComputerMove: TAction;
    MenuCalcBestMove: TAction;
    Menu1CancelComputerMove: TAction;
    Menu1SaveGame: TAction;
    ShowAnalysis: TMenuItem;
    MenuAbout: TAction;
    MenuContent: TAction;
    Contents: TMenuItem;
    Website: TMenuItem;
    procedure ToolButtonMoveBackClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ToolButtonMoveForwardClick(Sender: TObject);
    procedure SaveGameClick(Sender: TObject);
    procedure ToolButtonLoadGameClick(Sender: TObject);
    procedure ToolButtonNewGameClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure ToolButtonComputerMoveClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LevelClick(Sender: TObject);
    procedure ToolButtonCancelComputerMoveClick(Sender: TObject);
    procedure ToolButtonFindBoardScoreClick(Sender: TObject);
    procedure MenuAboutExecute(Sender: TObject);
    procedure MenuContentExecute(Sender: TObject);
    procedure WebsiteClick(Sender: TObject);
  private
    FMoveListPos:integer;
    FMoveList:array [0..42] of integer;
    FSearchThread:TSearchThread;
    FLevel:integer;
    procedure SearchThreadDone(Sender: TObject);
    procedure SaveIniFile;
  protected
    function TrySquareSet(x,y:integer):boolean;
  public
    procedure SetSquare(x,y,Player,Score:integer); virtual;
  end;

implementation

{$R *.dfm}
uses IniFiles, AboutBoxForm, ShellAPI;

procedure TFormMain.SetSquare(x,y,Player,Score:integer);
begin
// do Nothing
end;
procedure TFormMain.SaveIniFile;
var
  IniFileVar: TIniFile;
begin
  if GetDriveType(PChar(ExtractFileDrive(ParamStr(0)))) = DRIVE_CDROM then exit;
  IniFileVar := TIniFile.create(ExtractFileDir(ParamStr(0))+'\Config.ini');
  try
    IniFileVar.WriteInteger('Form', 'Height', Height);
    IniFileVar.WriteInteger('Form', 'Width', Width);
    IniFileVar.WriteInteger('Form', 'Top', Top);
    IniFileVar.WriteInteger('Form', 'Left', Left);
    IniFileVar.WriteBool('Form', 'WindowState', WindowState=wsMaximized);
    IniFileVar.WriteInteger('Menue', 'Level', FLevel);
    IniFileVar.WriteBool('Menue', 'HumanVersComp', HumanVersComp.Checked);
    IniFileVar.WriteBool('Menue', 'HumanVersHuman', HumanVersHuman.Checked);
    IniFileVar.WriteBool('Menue', 'AudibleAlert', AudibleAlert.Checked);
    IniFileVar.WriteBool('Menue', 'ShowAnalysis', ShowAnalysis.Checked);
  except
  end;
  IniFileVar.Free;
end;
procedure TFormMain.FormDestroy(Sender: TObject);
begin
  if GetDriveType(PChar(ExtractFileDrive(ParamStr(0)))) = DRIVE_REMOVABLE then exit;
  SaveIniFile;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var i:integer;
    IniFileVar: TIniFile;
begin
  IniFileVar := TIniFile.create(ExtractFileDir(ParamStr(0))+'\Config.ini');
  FLevel := IniFileVar.ReadInteger('Menue', 'Level', 42);
  if IniFileVar.ReadBool('Form', 'WindowState', false) then WindowState:=wsMaximized else
  begin
    Height := IniFileVar.ReadInteger('Form', 'Height', Height);
    Width := IniFileVar.ReadInteger('Form', 'Width', Width);
    Top := IniFileVar.ReadInteger('Form', 'Top', Top);
    Left := IniFileVar.ReadInteger('Form', 'Left', Left);
  end;
  HumanVersComp.Checked := IniFileVar.ReadBool('Menue', 'HumanVersComp', true);
  HumanVersHuman.Checked := IniFileVar.ReadBool('Menue', 'HumanVersHuman', false);
  AudibleAlert.Checked := IniFileVar.ReadBool('Menue', 'AudibleAlert', true);
  ShowAnalysis.Checked:=IniFileVar.ReadBool('Menue', 'ShowAnalysis', false);
  case FLevel of
  1:Level1.Checked:=true;
  2:Level2.Checked:=true;
  3:Level3.Checked:=true;
  4:Level4.Checked:=true;
  5:Level5.Checked:=true;
  6:Level6.Checked:=true;
  7:Level7.Checked:=true;
  8:Level8.Checked:=true;
  9:Level9.Checked:=true;
  10:Level10.Checked:=true;
  11:Level11.Checked:=true;
  12:Level12.Checked:=true;
  13:Level13.Checked:=true;
  14:Level14.Checked:=true;
  15:Level15.Checked:=true;
  16:Level16.Checked:=true;
  17:Level17.Checked:=true;
  20:Level20.Checked:=true;
  25:Level25.Checked:=true;
  26:Level26.Checked:=true;
  30:Level30.Checked:=true;
  42:Level42.Checked:=true;
  end;
  IniFileVar.Free;
  if GetDriveType(PChar(ExtractFileDrive(ParamStr(0)))) = DRIVE_CDROM then
     Menu1SaveGame.Enabled:=false;
  for i:=0 to 41 do FMoveList[i]:=-1;
  FMoveListPos:=0;
  MenuMoveForward.Enabled:=false;
  MenuMoveBack.Enabled:=false;

end;

procedure TFormMain.ToolButtonMoveBackClick(Sender: TObject);
var x,y:integer;
begin
  Application.ShowHint:=true;
  if FMoveListPos=0 then exit;
  dec(FMoveListPos);
  x:=FMoveList[FMoveListPos] and $ff;
  y:=FMoveList[FMoveListPos] shr 8;
  SetSquare(x,y,0,0);
  if FMoveListPos=0 then MenuMoveBack.Enabled:=false;
  MenuMoveForward.Enabled:=true;
end;
function TFormMain.TrySquareSet(x,y:integer):boolean;
var i:integer;
begin
  result:=false;
  if not MenuComputerMove.Enabled  then exit;
  if FMoveList[FMoveListPos]<>x+y shl 8 then
  begin
    for i:=FMoveListPos to 42 do FMoveList[i]:=-1;
    MenuMoveForward.Enabled:=false;
  end;
  FMoveList[FMoveListPos]:=x+y shl 8;
  inc(FMoveListPos);
  MenuMoveBack.Enabled:=true;
  if HumanVersComp.Checked then ToolButtonComputerMoveClick(nil);
  result:=true;
end;
procedure TFormMain.ToolButtonMoveForwardClick(Sender: TObject);
var x,y:integer;
begin
  if FMoveList[FMoveListPos]=-1 then exit;
  x:=FMoveList[FMoveListPos] and $ff;
  y:=FMoveList[FMoveListPos] shr 8;
  SetSquare(x,y,1,0);
  inc(FMoveListPos);
  if FMoveList[FMoveListPos]=-1 then MenuMoveForward.Enabled:=false;
  MenuMoveBack.Enabled:=true;
end;

procedure TFormMain.SaveGameClick(Sender: TObject);
var
  FilePath: string;
  fs: TFileStream;
  i:integer;
begin
  SaveIniFile;
  FilePath := ExtractFilePath(Application.ExeName);
  fs:=nil;
  try
    fs := TFileStream.Create(FilePath + 'savegame.dat', fmCreate or fmOpenWrite);
    fs.Write(FMoveListPos,4);
    for i:=0 to 42 do fs.Write(FMoveList[i],4);
    MenuLoadGame.Enabled:=true;
  except
    Application.MessageBox('It is not possible to save the game.', 'Error', 16);
  end;
  fs.Free;
end;


procedure TFormMain.ToolButtonLoadGameClick(Sender: TObject);
var
  FileName: string;
  fs: TFileStream;
  i,x,y:integer;
begin
  FileName := ExtractFilePath(Application.ExeName)+'savegame.dat';
  if not FileExists(FileName) then exit;
  ToolButtonNewGameClick(nil);
  fs := TFileStream.Create(FileName, fmOpenRead);
  try
    fs.Read(FMoveListPos,4);
    for i:=0 to 42 do
    begin
      fs.Read(FMoveList[i],4);
      if i>=FMoveListPos then continue;
      x:=FMoveList[i] and $ff;
      y:=FMoveList[i] shr 8;
      SetSquare(x,y,1,0);
    end;
  except
    Application.MessageBox('file load error', 'Error', 16);
  end;
  MenuMoveBack.Enabled:=FMoveListPos>0;
  MenuMoveForward.Enabled:=FMoveList[FMoveListPos]<>-1 ;
  fs.Free;
end;

procedure TFormMain.ToolButtonNewGameClick(Sender: TObject);
var  x,y:integer;
begin
  FMoveListPos:=0;
  for x:=0 to 6 do
    for y:=0 to 5 do
      SetSquare(x,y,0,0);
  MenuMoveBack.Enabled:=false;
end;

procedure TFormMain.ToolButtonComputerMoveClick(Sender: TObject);
const BRD_FULL=$000003FFFFFFFFFF;
var Player1Board,Player2Board,b:int64;
    y,x,i:integer;
begin
//  Statusbar1.Panels[0].Text:=inttostr(FMoveListPos);
  Player1Board:=0;
  Player2Board:=0;
  for i:=0 to FMoveListPos-1 do
  begin
    x:=FMoveList[i] and $ff;
    y:=FMoveList[i] shr 8;
    b:=int64(1) shl (x+y*7);
    if i mod 2 =0 then
      Player1Board:=Player1Board or b
    else
      Player2Board:=Player2Board or b;
  end;
  if Player1Board or Player2Board = BRD_FULL then exit;
  MenuComputerMove.Enabled:=false;
  MenuCalcBestMove.Enabled:=false;
  MenuMoveBack.Enabled:=false;
  MenuMoveForward.Enabled:=false;
  MenuLoadGame.Enabled:=false;
  MenuNewGame.Enabled:=false;
  Menu1CancelComputerMove.Enabled:=true;
  FSearchThread:=TSearchThread.Create(true);
  FSearchThread.FreeOnTerminate:=true;
  FSearchThread.OnTerminate:=SearchThreadDone;
  FSearchThread.SetVar(FLevel,Player1Board,Player2Board);
  FSearchThread.Resume;
  Cursor := crHourGlass;
end;

procedure TFormMain.SearchThreadDone(Sender: TObject);
var Move,Score:integer;
  x,y,i:integer;
begin
  Cursor := crDefault;
  if AudibleAlert.Checked then Beep;
  Menu1CancelComputerMove.Enabled:=false;
  MenuComputerMove.Enabled:=true;
  MenuCalcBestMove.Enabled:=true;
  MenuMoveBack.Enabled:=true;
  MenuNewGame.Enabled:=true;
  MenuLoadGame.Enabled:=true;
  CancelSearch:=false;
  FSearchThread.GetVar(Move,Score);
  if Move=-2 then exit;
  y:=0;
  x:=Move mod 7;
  for i:=0 to FMoveListPos-1 do
    if FMoveList[i] and $ff = x then inc(y);
  if Move div 7<>y then
  assert(Move div 7=y,'y='+inttostr(y)+' move='+inttostr(move));
  assert((y<6) and (y>=0),'y='+inttostr(y));
  assert((x<7) and (x>=0),'x='+inttostr(x));
  if not ShowAnalysis.Checked then Score:=0;
  SetSquare(x,y,1,Score);

  if FMoveList[FMoveListPos]<>x+y shl 8 then
  begin
    for i:=FMoveListPos to 42 do FMoveList[i]:=-1;
    MenuMoveForward.Enabled:=false;
  end;
  FMoveList[FMoveListPos]:=x+y shl 8;
  inc(FMoveListPos);

  Statusbar1.Panels[0].Text:=inttostr(Score);
 end;

procedure TFormMain.ToolButtonFindBoardScoreClick(Sender: TObject);
var Level:integer;
begin
  Level:=FLevel;
  FLevel:=42;
  ToolButtonComputerMoveClick(nil);
  FLevel:=Level;
end;

procedure TFormMain.ExitClick(Sender: TObject);
begin
  Application.Terminate;
end;



procedure TFormMain.LevelClick(Sender: TObject);
begin
  // Each level menu item has an integer tag property that stores the required
  // search depth
  with Sender as TMenuItem do
    FLevel := Tag;
end;

procedure TFormMain.ToolButtonCancelComputerMoveClick(Sender: TObject);
begin
  CancelSearch:=true;
end;


procedure TFormMain.MenuAboutExecute(Sender: TObject);
begin
 AboutBox.Show;
end;

function HelpFileFromResource(aFile : string) : string;

function TempFileName(const pref : string) : string;
var tempP,tempF : array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, tempP);
  GetTempFileName(tempP, pchar(pref), 0, tempF);
  Result := StrPas(TempF);
end;

var
  HGlobal: THandle;
  Size: Integer;
  P: PByteArray;
  F: file;
  TempF,ResFile : string;
  Ext:string;
  HResInfo:HRSRC;
begin
  Result :='';
  ext:=Uppercase(ExtractFileExt(aFile));
  ext:=Copy(ext, 2, 3);
  ResFile := ChangeFileExt(aFile,'');
  HResInfo := FindResource(HInstance, PChar(ResFile), PChar(ext));
  if HResInfo = 0 then exit;
  HGlobal  := LoadResource(HInstance, HResInfo);
  if HGlobal = 0 then exit;
  Size:= SizeOfResource(HInstance, HResInfo);
  P:= LockResource(HGlobal);
  TempF := TempFileName(aFile);
  TempF := ChangeFileExt(TempF,'.chm');
  AssignFile(F, TempF);
  Rewrite(F, 1);
  BlockWrite(F, P^, Size);
  CloseFile(F);
  result:=TempF;
end;                          

procedure HtmlHelpA(hwndCaller: THandle; pszFile: PChar; uCommand: cardinal; dwData: longint); stdcall; external 'HHCTRL.OCX';

procedure TFormMain.MenuContentExecute(Sender: TObject);
const HH_DISPLAY_TOC = $0001;
var tempF:string;
begin
  tempF:=HelpFileFromResource('Help.chm');
//  tempF:='Help.chm';
  if tempF='' then exit;
  HtmlHelpA(Application.handle, pchar(tempF), HH_DISPLAY_TOC, 0);  //show table of contents
  DeleteFile(tempF);
end;                   

procedure TFormMain.WebsiteClick(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open',
  PChar('http://members.fortunecity.com/schutzenberger/download/en.html#ConnectFour3D'), nil, nil, 0);
end;

end.
