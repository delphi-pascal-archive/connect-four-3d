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
unit SearchThread;

interface

uses
  Classes;

type
  TSearchThread = class(TThread)
  private
    FCrntLvl,FMove,FScore:integer;
    FPlayer1Board,FPlayer2Board:int64;
  protected
    procedure Execute; override;
  public
    procedure GetVar(var Move,Score:integer);
    procedure SetVar(CrntLvl:integer;Player1Board,Player2Board:int64);
  end;

var CancelSearch:boolean = false;

implementation
uses MainForm,SearchMove;

{ SearchThread }
procedure TSearchThread.GetVar(var Move,Score:integer);
begin
  Move:=FMove;
  Score:=FScore;
end;
procedure TSearchThread.SetVar(CrntLvl:integer;Player1Board,Player2Board:int64);
begin
  FCrntLvl:=CrntLvl;
  FPlayer1Board:=Player1Board;
  FPlayer2Board:=Player2Board;
end;
procedure TSearchThread.Execute;
begin
  FindBestMove(FCrntLvl,FPlayer1Board,FPlayer2Board,FMove,FScore);
  ReturnValue:=FMove;
end;

end.
