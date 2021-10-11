{ **************************************************************************** }
{ Project: ConnectFour3D
{ Module:  AboutBoxForm.pas
{ Author:  Josef Schuetzenberger
{ E-Mail:  schutzenberger@hotmail.com
{ WWW:     http://members.fortunecity.com/schutzenberger/download/en.html#ConnectFour3D
{ This unit is based on work by J.T. Deuter
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

unit AboutBoxForm;

interface

uses
  Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls, Buttons,
  ExtCtrls, ShellAPI;

type
  TAboutBox = class(TForm)
    Pnl: TPanel;
    PrgrmIcn: TImage;
    Product: TLabel;
    Version: TLabel;
    Cpyrght: TLabel;
    Cmnts1: TLabel;
    OKBtn: TButton;
    Cmnts2: TLabel;
    Dlph: TImage;
    WbLnk: TLabel;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure WbLnkClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.dfm}

procedure TAboutBox.FormCreate(Sender: TObject);
var
  dwInfSz, dwVerSz, dwWnd: DWORD;
  FI: PVSFixedFileInfo;
  pVerBuf: Pointer;
  sVersion, sExePath: string;
begin

  // Extract the file version from the VersionInfo and populate caption
  sExePath := Application.ExeName;
  dwInfSz := GetFileVersionInfoSize(PChar(sExePath), dwWnd);
  GetMem(pVerBuf, dwInfSz);
  try
    if GetFileVersionInfo(PChar(sExePath), dwWnd, dwInfSz, pVerBuf) then
      if VerQueryValue(pVerBuf, '\', Pointer(FI), dwVerSz) then
        sVersion := Format('%d.%d%d', [HiWord(FI.dwFileVersionMS),
                                   LoWord(FI.dwFileVersionMS),
                                   HiWord(FI.dwFileVersionLS)]);
  finally             
    FreeMem(pVerBuf);
  end;
  Version.Caption := 'Version ' + sVersion;
end;

procedure TAboutBox.WbLnkClick(Sender: TObject);
begin
  ShellExecute(Application.Handle, 'open',
               PChar('http://www.gnu.org/licenses/gpl.html'), nil, nil, 0);
end;

procedure TAboutBox.OKBtnClick(Sender: TObject);
begin
 Hide;
end;

end.

