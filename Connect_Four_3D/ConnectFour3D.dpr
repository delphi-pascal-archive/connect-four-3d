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
program ConnectFour3D;

uses
  Forms,
  BoardForm in 'BoardForm.pas' {Form1},
  SearchThread in 'SearchThread .pas',
  AboutBoxForm in 'AboutBoxForm.pas' {AboutBox};

{$R *.res}
{$R book.res}           
{$R help.res}
                         
begin           
  Application.Initialize;
  Application.Title := 'Connect Four 3D';
  Application.CreateForm(TFormBoard, FormBoard);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
