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
unit OpenGLUtil;

interface

uses opengl;

type  TAffineVector=array[0..2] of Single;
      TVector4f = array [0..3] of GLdouble;
      TMatrix4f = array [0..3] of TVector4f;
      TGLFloat=GLFloat;
      TCamera=record
                xpos,ypos,zpos:real;
                xat,yat,zat:real;
                xtop,ytop,ztop:real;
              end;
      TLastMove=record
                  x,y,score:integer;
                end;
      TBoardPos= (Empty,Player1,Player2);

var   Camera:TCamera;
      BoardState : array[0..6,0..5] of TBoardPos;
      LastMove: TLastMove;
      BoardWinLine : array[0..6,0..5] of TBoardPos;
      LastMouseClickX,LastMouseClickY:integer;
      TimerCount:integer=0;
      Texture: array [0..2] of GLuint;
const Stone = 106;
      StonePlayer1 = 107;
      StonePlayer2 = 108;
      Marker=109;
      Side = 200;
      Floor = 201;
      Board =202;
      BoardPosZ=-1;
     (* Board *)
      MCBoard1 : array [0..3] of GLfloat = (1.0, 0.7, 0.1, 1.0);
      MCBoard2 : array [0..3] of GLfloat = (0.9, 0.2, 0.0, 1.0);
      MCBoard3 : array [0..3] of GLfloat = (0.1, 0.8, 0.3, 1.0);
     (* Player 2 *)
      Player2MC1 : array [0..3] of GLfloat = (0.9, 0.0, 0.0, 1.0);
      Player2MC2 : array [0..3] of GLfloat = (0.0, 0.0, 0.0, 1.0);
      Player2MC3 : array [0..3] of GLfloat = (0.4, 0.0, 0.0, 1.0);
     (* Player 1 *)
      Player1MC1 : array [0..3] of GLfloat = (0.0, 0.0, 0.9, 1.0);
      Player1MC2 : array [0..3] of GLfloat = (0.0, 0.0, 0.0, 1.0);
      Player1MC3 : array [0..3] of GLfloat = (0.0, 0.0, 0.4, 1.0);
     (* Border *)
      MCBorder1 : array [0..3] of GLfloat = (1.0, 1.0, 1.0, 1.0);
      MCBorder2 : array [0..3] of GLfloat = (0.0, 0.0, 0.0, 1.0);
      MCBorder3 : array [0..3] of GLfloat = (0.0, 0.0, 0.0, 1.0);
     (* Floor  *)
      MCFloor1 : array [0..3] of GLfloat = (0.0, 0.3, 0.1, 1.0);
      MCFloor2 : array [0..3] of GLfloat = (0.0, 0.1, 0.0, 1.0);
      MCFloor3 : array [0..3] of GLfloat = (0.0, 0.0, 0.0, 1.0);

  procedure SinCos(const Theta: Single; var Sin, Cos: Single); register;
  function VectorDotProduct(const V1, V2 : TAffineVector): Single; assembler; register;
  procedure VectorCombine(const V1 : TAffineVector; const V2: TAffineVector;
                          const F1, F2: Single; var vr : TAffineVector);
  function VectorRotateAroundY(const v : TAffineVector; alpha : Single) : TAffineVector;

implementation

procedure SinCos(const Theta: Single; var Sin, Cos: Single); register;
// EAX contains address of Sin
// EDX contains address of Cos
// Theta is passed over the stack
asm
  FLD  Theta
  FSINCOS
  FSTP DWORD PTR [EDX]    // cosine
  FSTP DWORD PTR [EAX]    // sine
end;
function VectorDotProduct(const V1, V2 : TAffineVector): Single; assembler; register;
// EAX contains address of V1
// EDX contains address of V2
// result is stored in ST(0)
asm
  FLD DWORD PTR [EAX]
  FMUL DWORD PTR [EDX]
  FLD DWORD PTR [EAX + 4]
  FMUL DWORD PTR [EDX + 4]
  FADDP
  FLD DWORD PTR [EAX + 8]
  FMUL DWORD PTR [EDX + 8]
  FADDP
end;
procedure VectorCombine(const V1 : TAffineVector; const V2: TAffineVector;
                        const F1, F2: Single; var vr : TAffineVector);
const X=0;Y=1;Z=2;
begin
  vr[X]:=(F1 * V1[X]) + (F2 * V2[X]);
  vr[Y]:=(F1 * V1[Y]) + (F2 * V2[Y]);
  vr[Z]:=(F1 * V1[Z]) + (F2 * V2[Z]);
end;

function VectorRotateAroundY(const v : TAffineVector; alpha : Single) : TAffineVector;
var c, s : Single;
begin
  SinCos(alpha, s, c);
  Result[1]:=v[1];
  Result[0]:=c*v[0]+s*v[2];
  Result[2]:=c*v[2]-s*v[0];
end;

end.
