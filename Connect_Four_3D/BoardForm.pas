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
unit BoardForm;

interface
               
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,MainForm,OpenGL, ExtCtrls{,jpeg}, ImgList;

type
  TFormBoard = class(TFormMain)
    Timer1: TTimer;
    Timer2: TTimer;
    ImageListSmiley: TImageList;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FormPaint(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
  private
    Palette: HPALETTE;
    DC: HDC;
    hrc: HGLRC;
    procedure SetDCPixelFormat;
    function ScreenVectorIntersectWithPlaneXY(const ScreenX,ScreenY,z : Single;
                                               var Xintersect,Yintersect : Single) : Boolean;
  public
    procedure InitScene;
    procedure FreeScene;
    procedure DrawScene;
    procedure SetSquare(x,y,Player,Score:integer);override;
  end;

var FormBoard: TFormBoard;

procedure glGenTextures(n: GLsizei; var textures: GLuint); stdcall; external opengl32;
procedure glBindTexture(target: GLenum; texture: GLuint); stdcall; external opengl32;

implementation

{$R *.dfm}
uses OpenGLUtil;

function TFormBoard.ScreenVectorIntersectWithPlaneXY(const ScreenX,ScreenY,Z : Single;
                                               var Xintersect,Yintersect : Single) : Boolean;
var
   wx, wy, wz : Double;
   ViewPort : array[0..3]of gluint;
   ProjectionMatrix:TMatrix4f;
   ModelViewMatrix:TMatrix4f;
   d,t:Single;
   rayStart,rayVector,planeNormal,planePoint,intersectPoint:TAffineVector;
begin
  result:=false;
  wglMakeCurrent(DC, hrc);
  glpushmatrix;
  glGetIntegerv(GL_VIEWPORT, @ViewPort);
  glGetDoublev(GL_MODELVIEW_MATRIX, @ModelViewMatrix);
  glGetDoublev(GL_PROJECTION_MATRIX, @ProjectionMatrix);
  gluUnProject(ScreenX, ViewPort[3]-ScreenY, 0,
               @ModelViewMatrix, @ProjectionMatrix, @ViewPort,
               wx, wy, wz);
  rayStart[0]:=Camera.xpos;
  rayStart[1]:=Camera.ypos;
  rayStart[2]:=Camera.zpos;
  rayVector[0]:=wx-Camera.xpos;
  rayVector[1]:=wy-Camera.ypos;
  rayVector[2]:=wz-Camera.zpos;
  planePoint[0]:=-Camera.xpos;
  planePoint[1]:=-Camera.ypos;
  planePoint[2]:=z-Camera.zpos;
  planeNormal[0]:=0;
  planeNormal[1]:=0;
  planeNormal[2]:=1;
  d:=VectorDotProduct(rayVector, planeNormal);
  if abs(d) > 0.0001 then
  begin
    d:=1/d;
    t:=VectorDotProduct(planePoint, planeNormal)*d;
    if t>0 then
    begin
      VectorCombine(rayStart, rayVector, 1, t, intersectPoint);
      Xintersect:=intersectPoint[0];
      Yintersect:=intersectPoint[1];
      result:=true;
    end;
  end;
  glpopmatrix;
  wglMakeCurrent(0, 0);
end;
//---------------------------------------------------------------------------
const MinFilter=GL_LINEAR;
      MaxFilter=GL_LINEAR;
procedure LoadTex(Filename:string);

function RoundUpToPowerOf2(value : Integer) : Integer;
begin
   Result:=1;
   while (Result<value) do Result:=Result*2;
end;

procedure DoBGRtoRGB(data : Pointer; size : Integer);
asm  //  swap blue with red to go from bgr to rgb
     //  data in eax
     //  size in edx
@@loop: mov cl,[eax]    // red
        mov ch,[eax+2]  // blue
        mov [eax+2],cl
        mov [eax],ch
        add eax,3
        dec edx
        jnz @@loop
end;
type PPixelArray  = ^TByteArray;
var bmp24,bmp : TBitmap;
//    jp    : TJPEGImage;
    BMInfo: TBitmapInfo;
    Buffer: PPixelArray;
    ImageSize : Integer;
    MemDC     : HDC;
begin
 { if ExtractFileExt(Filename)='.jpg' then
  begin
    jp := TJPEGImage.Create;
    jp.LoadFromFile(Filename);
    bmp24:=TBitmap.Create;
    bmp24.PixelFormat:=pf24Bit;
    bmp24.Width:=jp.Width;
    bmp24.Height:=jp.Height;
    bmp24.Canvas.Draw(0, 0, jp);
    jp.Free;
  end else  }
  if ExtractFileExt(Filename)='.bmp' then
  begin
    bmp := TBitmap.Create;
    bmp.LoadFromFile(Filename);
    bmp24:=TBitmap.Create;
    bmp24.PixelFormat:=pf24Bit;
    bmp24.Width:=bmp.Width;
    bmp24.Height:=bmp.Height;
    bmp24.Canvas.Draw(0, 0, bmp);
    bmp.Free;
  end else
  if ExtractFileExt(Filename)='.IL' then
  begin
    bmp := TBitmap.Create;
    FormBoard.ImageListSmiley.GetBitmap(StrtoInt(ChangeFileExt(Filename,'')),bmp);
    bmp24:=TBitmap.Create;
    bmp24.PixelFormat:=pf24Bit;
    bmp24.Width:=bmp.Width;
    bmp24.Height:=bmp.Height;
    bmp24.Canvas.Draw(0, 0, bmp);
    bmp.Free;
  end else exit;

  // create description of the required image format
  FillChar(BMInfo, sizeof(BMInfo),0);
  BMInfo.bmiHeader.biSize:=sizeof(TBitmapInfoHeader);
  BMInfo.bmiHeader.biBitCount:=24;
  BMInfo.bmiHeader.biWidth:=RoundUpToPowerOf2(bmp24.Width);
  BMInfo.bmiHeader.biHeight:=RoundUpToPowerOf2(bmp24.Height);
  BMInfo.bmiHeader.biPlanes:=1;
  BMInfo.bmiHeader.biCompression:=BI_RGB;
  ImageSize:=BMInfo.bmiHeader.biWidth*BMInfo.bmiHeader.biHeight;
  Getmem(Buffer, ImageSize*3);
  MemDC:=CreateCompatibleDC(0);
  // get the actual bits of the image
  GetDIBits(MemDC, bmp24.Handle, 0, BMInfo.bmiHeader.biHeight, Buffer, BMInfo, DIB_RGB_COLORS);
  // swap blue with red to go from bgr to rgb
  DoBGRtoRGB(Buffer,ImageSize);
  glTexImage2d(GL_TEXTURE_2D,0, 3, BMInfo.bmiHeader.biWidth,BMInfo.bmiHeader.biHeight,0, GL_RGB, GL_UNSIGNED_BYTE, Buffer);
  FreeMem(Buffer);
  DeleteDC(MemDC);
  bmp24.Free;
end;

//---------------------------------------------------------------------------
procedure InitTex;
type PPixelArray  = ^TByteArray;
procedure MakeWood(Buffer:PPixelArray;ImageSize:integer);
var
  red,green,blue: byte;
  b:byte;
  i : Integer;
begin
  red := 147;
  green := 110;
  blue := 58;
  {$IFOPT R+} {$DEFINE RangeCheck} {$R-} {$ENDIF}
  for i:=0 TO ImageSize-1 do
  begin
    b:=i mod 9;
    Buffer^[I*3] := red+b;
    Buffer^[I*3+1] := green+b;
    Buffer^[I*3+2] := blue+b;
  end;
  {$IFDEF RangeCheck} {$UNDEF RangeCheck} {$R+} {$ENDIF}
end;
var Buffer: PPixelArray;
    ImageSize,biWidth,biHeight : Integer;
begin
  glGenTextures(3,texture[0]);
  glBindTexture(GL_TEXTURE_2D, texture[0]);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,MinFilter);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,MaxFilter);
  biWidth:=64;
  biHeight:=64;
  ImageSize:=biWidth*biHeight;
  Getmem(Buffer, ImageSize*3);
  MakeWood(Buffer,ImageSize);
  glTexImage2d(GL_TEXTURE_2D,0, 3, biWidth,biHeight,0, GL_RGB, GL_UNSIGNED_BYTE, Buffer);
  FreeMem(Buffer);
  glBindTexture(GL_TEXTURE_2D, texture[1]);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,MinFilter);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,MaxFilter);
//  LoadTex('smileyHappy4.bmp');
  LoadTex('0.IL');
  glBindTexture(GL_TEXTURE_2D, texture[2]);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,MinFilter);
  glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,MaxFilter);
  LoadTex('1.IL');
//  LoadTex('smileySad4.bmp');
end;

//---------------------------------------------------------------------------
procedure TFormBoard.InitScene;
var aQuad: gluQuadricObj;
const lightcolor : array[0..3] of glfloat =(0.7,0.7,0.7,1);
const lightpos   : array[0..3] of glfloat =(0.0,10,0.0,0);

procedure MakePlank(x,y,z : glFloat);
var aQuadVertex:array[0..7,0..2] of glfloat;
const aQuadPoints:array[0..7,0..2] of glfloat=
 (( 1, 1, 1),
  (-1, 1, 1),
  ( 1,-1, 1),
  (-1,-1, 1),
  ( 1, 1,-1),
  (-1, 1,-1),
  ( 1,-1,-1),
  (-1,-1,-1));
const aQuadTexture:array[0..7,0..2] of glfloat=
 (( 1, 1, 1),
  ( 0, 1, 1),
  ( 1, 0, 1),
  ( 0, 0, 1),
  ( 1, 1,-1),
  (-1, 1,-1),
  ( 1,-1,-1),
  (-1,-1,-1));
const Surface : array[0..5,0..3] of integer =
      ((1,2,4,3),
       (2,1,5,6),
       (6,5,7,8),
       (8,7,3,4),
       (1,3,7,5),
       (2,6,8,4));

const Normals : array[0..5,0..2] of glfloat =
       (( 0, 0, 1),
        ( 0, 1, 0),
        ( 0, 0,-1),
        ( 0,-1, 0),
        ( 1, 0, 0),
        (-1, 0, 0));
var i,j : integer;
begin
  for i := 0 to 7 do
  begin
    aQuadvertex[i,0]:=aQuadPoints[i,0]*x/2;
    aQuadvertex[i,1]:=aQuadPoints[i,1]*y/2;
    aQuadvertex[i,2]:=aQuadPoints[i,2]*z/2;
  end;
  glbegin(GL_QUADs);
  for i := 0 to 5 do
  begin
    glnormal3fv(@normals[i,0]);
    for j :=0 to 3 do
    begin
      glTexCoord2f(aQuadTexture[Surface[i,j]-1,0],aQuadTexture[Surface[i,j]-1,1]);
      glvertex3fv(@aQuadvertex[Surface[i,j]-1,0]);
    end;
  end;
  glend;
end;
//---------------------------------------------------------------------------
procedure MakeStone(FMinorRadius,FMajorRadius:glFloat;FRings,FSides:integer);
var
   I, J,start         : Integer;
   Theta, Phi, Theta1, cosPhi, sinPhi, dist : TGLFloat;
   cosTheta, sinTheta: TGLFloat;
   cosTheta1, sinTheta1, cosTheta2, sinTheta2: TGLFloat;
   ringDelta, sideDelta: TGLFloat;
const c2PI :      Single =  6.283185307;
begin
   // handle texture generation
   ringDelta:=c2PI/FRings;
   sideDelta:=c2PI/FSides;
   theta:=0;
   cosTheta:=1;
   sinTheta:=0;
   start:=FSides div 4 ;
   FSides:=FSides-start ;
   for I:=FRings-1 downto 0 do  begin
      theta1:=theta+ringDelta;
      SinCos(theta1, sinTheta1, cosTheta1);
      SinCos(theta1+ringDelta, sinTheta2, cosTheta2);
      glBegin(GL_QUAD_STRIP);
      phi:=sideDelta*(FSides-1);
      SinCos(phi+sideDelta, sinPhi, cosPhi);
      glNormal3f(-1, 0, 0);
      glTexCoord2f(0.5, 0.5);
      glVertex3f(0, 0, FMinorRadius*sinPhi);
//      glNormal3f(-1, 0, 0);
//      glVertex3f(0,0, FMinorRadius*sinPhi);
      for J:=FSides downto start do begin
         phi:=phi+sideDelta;
         SinCos(phi, sinPhi, cosPhi);
         dist:=FMajorRadius+FMinorRadius*cosPhi;
         glTexCoord2f((sinTheta2+1)/2, (cosTheta2+1)/2);
         glNormal3f(cosTheta1*cosPhi, -sinTheta1*cosPhi, sinPhi);
         glVertex3f(cosTheta1*dist, -sinTheta1*dist, FMinorRadius*sinPhi);
         glTexCoord2f((sinTheta1+1)/2, (cosTheta1+1)/2);
         glNormal3f(cosTheta*cosPhi, -sinTheta*cosPhi, sinPhi);
         glVertex3f(cosTheta*dist, -sinTheta*dist, FMinorRadius*sinPhi);
      end;
      glNormal3f(1, 0, 0);
      glTexCoord2f(0.5, 0.5);
      glVertex3f(0, 0, FMinorRadius*sinPhi);
//      glNormal3f(1, 0, 0);
//      glVertex3f(0,0, FMinorRadius*sinPhi);
      glEnd;
      theta:=theta1;
      cosTheta:=cosTheta1;
      sinTheta:=sinTheta1;
   end;
end;
//---------------------------------------------------------------------------
procedure MakeBoard1;
var i:integer;
const Square:glFloat=1.;
      Radius:glFloat=0.4;
      Thickness:glFloat=0.1;

procedure MakeCylinders(x,y,z : glFloat);
var j:integer;
begin
  gluQuadricOrientation(aquad,GLU_INSIDE);
  glpushmatrix;
  gltranslatef(0,Radius,0);
  for j:=0 to 6 do
  begin
    gltranslatef(Square,0,0);
    gluCylinder(aquad,Radius,Radius,Thickness,4*3,2);
  end;
  glpopmatrix;
  gluQuadricOrientation(aquad,GLU_OUTSIDE);
end;

procedure MakeRow(Radius,Border:glFloat;Holes,Stripes:integer);
var
   I,J: Integer;
   Phi,cosPhi,sinPhi,stripeDelta,y,x: TGLFloat;
const c2PI: Single =  6.283185307;
begin
  stripeDelta:=c2PI/Stripes/2;
  glBegin(GL_QUAD_STRIP);
  phi:=-stripeDelta;
  for J:=Stripes downto 0 do begin
     phi:=phi+stripeDelta;
     SinCos(phi, sinPhi, cosPhi);
     y:=Radius*(1+cosPhi);
     x:=Border-Radius*sinPhi;
     glVertex3f(0,y,0);
     glVertex3f(x, y,0);
  end;
  glEnd;
  for i:=1 to Holes-1 do
  begin
    glBegin(GL_QUAD_STRIP);
    phi:=-stripeDelta;
    for J:=Stripes downto 0 do begin
      phi:=phi+stripeDelta;
      SinCos(phi, sinPhi, cosPhi);
      y:=Radius*(1+cosPhi);
      x:=Border-Radius*sinPhi;
      glVertex3f(i*Border+Radius*sinPhi,y,0);
      glVertex3f(i*Border+x, y,0);
    end;
    glEnd;
  end;
  glBegin(GL_QUAD_STRIP);
  phi:=-stripeDelta;
  for J:=Stripes downto 0 do begin
    phi:=phi+stripeDelta;
    SinCos(phi, sinPhi, cosPhi);
    y:=Radius*(1+cosPhi);
    glVertex3f(Holes*Border+Radius*sinPhi,y,0);
    glVertex3f((Holes+1)*Border, y,0);
  end;
  glEnd;
end;

begin
 glMaterialfv(GL_FRONT, GL_AMBIENT, @MCBoard1);
 glMaterialfv(GL_FRONT, GL_diffuse, @MCBoard2);
 glMaterialfv(GL_FRONT, GL_specular,@MCBoard3);
 glpushmatrix;
 for i:=0 to 5 do   //front
 begin
   MakeCylinders(1,1,1);
   MakeRow(Radius,Square,7,2*3);
   glrectf(0,0,8*Square,-(Square-2*Radius));
   gltranslatef(0,Square,0);
 end;
 glrectf(0,0,8*Square,-(Square-2*Radius));
 glpopmatrix;
 glpushmatrix;
 glrotatef(180,0,1,0);
 gltranslatef(-8*Square,0,-0.1);
 for i:=0 to 5 do   //back
 begin
   MakeRow(Radius,Square,7,2*3);
   glrectf(0,0,8*Square,-(Square-2*Radius));
   gltranslatef(0,Square,0);
 end;
 glrectf(0,0,8*Square,-(Square-2*Radius));
 glpopmatrix;

 glpushmatrix;
 gltranslatef(0,Square*6,Thickness*0.5);
 glrotatef(90,0,1,0);
 gluCylinder(aquad,Thickness*0.5,Thickness*0.5,Square*8,8,2);
 glrotatef(90,1,0,0);
 gluCylinder(aquad,Thickness*0.5,Thickness*0.5,Square*8,8,2);
 gluSphere(aquad,Thickness*0.5,8,8);
 gltranslatef(0,Square*8,0);
 gluCylinder(aquad,Thickness*0.5,Thickness*0.5,Square*8,8,2);
 gluSphere(aquad,Thickness*0.5,18,8);
 glpopmatrix;
end;


begin
 inherited;
 aquad :=gluNewQuadric;

 gluQuadricDrawStyle(aquad,GLU_Fill);

 glNewList(Side,GL_COMPILE);
 glpushmatrix;
 gltranslatef(0,1,0);
 gltranslatef(10,0,0);
 glMaterialfv(GL_FRONT, GL_AMBIENT, @MCBorder1);
 glMaterialfv(GL_FRONT, GL_diffuse, @MCBorder2);
 glMaterialfv(GL_FRONT, GL_specular,@MCBorder3);
 makePlank(0.1,2,20);
 gltranslatef(-20,0,0);
 makePlank(0.1,2,20);
 gltranslatef(10,0,10);
 makePlank(20,2,0.1);
 gltranslatef(0,0,-20);
 makePlank(20,2,0.1);
 glpopmatrix;
 glEndlist;

 glNewList(Floor,GL_COMPILE);
 glbegin(gl_quads);
 glMaterialfv(GL_FRONT, GL_AMBIENT, @MCFloor1);
 glMaterialfv(GL_FRONT, GL_diffuse, @MCFloor2);
 glMaterialfv(GL_FRONT, GL_specular,@MCFloor3);
 glnormal3f(0,1,0);
 glvertex3f(-10,0,-10);
 glvertex3f(-10,0, 10);
 glvertex3f( 10,0, 10);
 glvertex3f( 10,0,-10);
 glend;
 glEndlist;



 gluQuadricDrawStyle(aquad,GLU_Fill);

 glNewList(Board,GL_COMPILE);
 glpushmatrix;
 gltranslatef(-4,1,-BoardPosZ+1);
 MakeBoard1;
 gltranslatef(0,0,-0.2);
 MakeBoard1;
 glpopmatrix;
 glEndlist;

 glNewList(Marker,GL_COMPILE);
 glpushmatrix;
 gltranslatef(-0.2,1.39,{-2.360}-BoardPosZ+0.64);
 glBegin(GL_POLYGON);
 glVertex2f(0.4, 0.2);
 glVertex2f(0.2, 0);
 glVertex2f(0, 0.2);
 glEnd;
 glpopmatrix;
 glEndlist;

 glNewList(Stone,GL_COMPILE);
 glpushmatrix;
 glMaterialfv(GL_FRONT, GL_AMBIENT, @Player2MC1);
 glMaterialfv(GL_FRONT, GL_diffuse, @Player2MC2);
 glMaterialfv(GL_FRONT, GL_specular,@Player2MC3);
 gltranslatef(-3,1,-BoardPosZ+1);
 gltranslatef(0,0,-0.2);
 MakeStone(0.05,0.35,16,20);
 glpopmatrix;
 glEndlist;

 glNewList(StonePlayer1,GL_COMPILE);
 glpushmatrix;
 glMaterialfv(GL_FRONT, GL_AMBIENT, @Player1MC1);
 glMaterialfv(GL_FRONT, GL_diffuse, @Player1MC2);
 glMaterialfv(GL_FRONT, GL_specular,@Player1MC3);
 gltranslatef(-0,1,-BoardPosZ+1);
 gltranslatef(0,0,-0.2);
 MakeStone(0.05,0.35,16,20);
 glpopmatrix;
 glEndlist;
 glNewList(StonePlayer2,GL_COMPILE);
 glpushmatrix;
 glMaterialfv(GL_FRONT, GL_AMBIENT, @Player2MC1);
 glMaterialfv(GL_FRONT, GL_diffuse, @Player2MC2);
 glMaterialfv(GL_FRONT, GL_specular,@Player2MC3);
 gltranslatef(-0,1,-BoardPosZ+1);
 gltranslatef(0,0,-0.2);
 MakeStone(0.05,0.35,16,20);
 glpopmatrix;
 glEndlist;

 gluDeleteQuadric(aquad);

 glenable(gl_lighting);
 glLightfv(GL_LIGHT0,GL_DIFFUSE,@Lightcolor);
 glLightfv(GL_LIGHT0,GL_AMBIENT,@Lightcolor);
 glLightfv(GL_LIGHT0,GL_POSITION,@Lightpos);
 glEnable(GL_LIGHT0);
 //InitTextures;
 InitTex;

 glclearcolor(0.5,0.5,0.7,0);
 glenable(gl_depth_test);
end;
//---------------------------------------------------------------------------
function CountStones(Player:TBoardPos):integer;
var i,j:integer;
begin
  result:=0;
  for i:=0 to 6 do
    for j:=0 to 5 do
      if BoardState[i,j]=Player then inc(result);
end;
//---------------------------------------------------------------------------
procedure TFormBoard.DrawScene;
var i,j,k,g : integer;
begin
  inherited;
  glEnable(GL_TEXTURE_2D);
  glShadeModel(GL_SMOOTH);
//  glClearColor(0.0, 0.0, 0.0, 0.5);
  glClearDepth(1.0);
  glEnable(GL_DEPTH_TEST);
  glDepthFunc(GL_LEQUAL);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);

  glfrontface(gl_ccw);    //orientation of front-facing polygons
  glenable(gl_cull_face); //enable facet culling
  glpushmatrix;

  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, texture[0]);
  glcalllist(Side);
  glDisable(GL_TEXTURE_2D);

  glpushName(18);
  glLoadName(18);
  glcalllist(Floor);
  glpopmatrix;

  glpushmatrix;
  glcalllist(Board);
  glpushName(21);
  glLoadName(21);
  glpopmatrix;

  glpushmatrix;
  k:=CountStones(Player1);
  j:=CountStones(Player2);
  g:=k-j;
  k:=k+1-g;
  j:=j+g;
  gltranslatef(5,0.75-BoardPosZ,-BoardPosZ);
  glrotatef(90,1,0,0);
  for i:=1 to 21-j do
  begin
    gltranslatef(0,0,-0.13);
    glcalllist(StonePlayer2);
  end;
  if g=1 then
  begin
    glrotatef(-90,1,0,0);
    gltranslatef(0.9,-0.5+BoardPosZ,BoardPosZ);
    glrotatef(65,0,0,1);
    if LastMove.score<>0 then
    begin
      glEnable(GL_TEXTURE_2D);
      if LastMove.score<0 then
      glBindTexture(GL_TEXTURE_2D, texture[1]) else
      glBindTexture(GL_TEXTURE_2D, texture[2]);
    end;
    glcalllist(StonePlayer2);
    glDisable(GL_TEXTURE_2D);
  end;
  glpopmatrix;

  glpushmatrix;
  gltranslatef(-5,0.75-BoardPosZ,-BoardPosZ);
  glrotatef(90,1,0,0);
  for i:=1 to 21-k do
  begin
    gltranslatef(0,0,-0.13);
    glcalllist(StonePlayer1);
  end;
  if g=0 then
  begin
    glrotatef(-90,1,0,0);
    gltranslatef(1,-0.5+BoardPosZ,BoardPosZ);
    glrotatef(65,0,0,1);
    if LastMove.score<>0 then
    begin
      glEnable(GL_TEXTURE_2D);
      if LastMove.score<0 then
      glBindTexture(GL_TEXTURE_2D, texture[1]) else
      glBindTexture(GL_TEXTURE_2D, texture[2]);
    end;
    glcalllist(StonePlayer1);
    glDisable(GL_TEXTURE_2D);
  end;
  glpopmatrix;
  for j:=0 to 6 do
  begin
    for i:=0 to 5 do
    begin
      if BoardState[j,i]<>Empty then
      if (BoardWinLine[j,i]=Empty) or (TimerCount mod 2=0) then
      begin
        glpushmatrix;
        gltranslatef(3-j*1,i*1+0.40,0.15);
        if BoardState[j,i]=Player1 then
           glcalllist(StonePlayer1) else
           glcalllist(StonePlayer2);
        if (LastMove.x=j) and (LastMove.y=i) then  glcalllist(Marker);
        glpopmatrix;
      end;
    end;
  end;
end;
//---------------------------------------------------------------------------
procedure TFormBoard.FreeScene;
begin
end;
//---------------------------------------------------------------------------
procedure TFormBoard.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  LastMouseClickX:=X;
  LastMouseClickY:=Y;
end;
//---------------------------------------------------------------------------
procedure TFormBoard.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var v : TAffineVector;
    r : Single;
begin
   if Shift=[ssLeft] then
   begin
     r:= LastMouseClickX-x;
     v[0]:=Camera.xpos;
     v[1]:=Camera.ypos;
     v[2]:=Camera.zpos;
     v:=VectorRotateAroundY(v,r*0.01);
     Camera.xpos:=v[0];
     Camera.ypos:=v[1];
     Camera.zpos:=v[2];
     v[0]:=Camera.xtop;
     v[1]:=Camera.ytop;
     v[2]:=Camera.ztop;
     v:=VectorRotateAroundY(v,r*0.01);
     Camera.xtop:=v[0];
     Camera.ytop:=v[1];
     Camera.ztop:=v[2];
     r:= LastMouseClickY-y;
     Camera.ypos:=Camera.ypos+r*0.1;
     if Camera.ypos<4.1 then Camera.ypos:=4.1;
     InvalidateRect(Handle, nil, False);
   end else
     if Shift=[ssRight] then
     begin
{     r:= LastMouseClickX-x;
     Camera.xtop:=v[0];
     Camera.ytop:=v[1];
     Camera.ztop:=Camera.ztop+r;
     InvalidateRect(Handle, nil, False); }
     end;
     LastMouseClickX:=X;
     LastMouseClickY:=Y;

end;
//---------------------------------------------------------------------------
procedure TFormBoard.FormPaint(Sender: TObject);
begin
  wglMakeCurrent(DC, hrc);
  try
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_ACCUM_BUFFER_BIT);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glulookat(Camera.xpos,Camera.ypos,Camera.zpos,Camera.xat,Camera.yat,Camera.zat,Camera.xtop,Camera.ytop,Camera.ztop);
    DrawScene;
    swapbuffers(DC);
  finally
    wglMakeCurrent(0, 0);
  end;
end;
//---------------------------------------------------------------------------
procedure TFormBoard.FormResize(Sender: TObject);
var x,y:integer;
begin
  inherited;
  wglMakeCurrent(DC, hrc);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  glViewport(0, 0,ClientWidth,ClientHeight);
  x:=ClientWidth;
  y:=ClientHeight;
  glShadeModel(GL_SMOOTH); //Enables Smooth Color Shading
  InvalidateRect(Handle, nil, False);
  gluPerspective(45.0,           // Field-of-view angle
                 x/y,            // Aspect ratio of viewing volume
                 1.0,            // Distance to near clipping plane
                 200.0);         // Distance to far clipping plane
  wglMakeCurrent(0, 0);
end;
//---------------------------------------------------------------------------
procedure TFormBoard.SetDCPixelFormat;
var
  hHeap: THandle;
  nColors, i: Integer;
  lpPalette: PLogPalette;
  byRedMask, byGreenMask, byBlueMask: Byte;
  nPixelFormat: Integer;
  pfd: TPixelFormatDescriptor;
begin
  FillChar(pfd, SizeOf(pfd), 0);

  with pfd do begin
    nSize     := sizeof(pfd);                               // Size of this structure
    nVersion  := 1;                                         // Version number
    dwFlags   := PFD_DRAW_TO_WINDOW or
                 PFD_SUPPORT_OPENGL or
                 PFD_DOUBLEBUFFER;                          // Flags
    iPixelType:= PFD_TYPE_RGBA;                             // RGBA pixel values
    cColorBits:= 24;                                        // 24-bit color
    cDepthBits:= 32;                                        // 32-bit depth buffer
    iLayerType:= PFD_MAIN_PLANE;                            // Layer type
  end;

  nPixelFormat := ChoosePixelFormat(DC, @pfd);
  SetPixelFormat(DC, nPixelFormat, @pfd);

  DescribePixelFormat(DC, nPixelFormat, sizeof(TPixelFormatDescriptor), pfd);

  if ((pfd.dwFlags and PFD_NEED_PALETTE) <> 0) then begin
    nColors   := 1 shl pfd.cColorBits;
    hHeap     := GetProcessHeap;
    lpPalette := HeapAlloc(hHeap, 0, sizeof(TLogPalette) + (nColors * sizeof(TPaletteEntry)));

    lpPalette^.palVersion := $300;
    lpPalette^.palNumEntries := nColors;

    byRedMask   := (1 shl pfd.cRedBits) - 1;
    byGreenMask := (1 shl pfd.cGreenBits) - 1;
    byBlueMask  := (1 shl pfd.cBlueBits) - 1;

    for i := 0 to nColors - 1 do begin
      lpPalette^.palPalEntry[i].peRed   := (((i shr pfd.cRedShift)   and byRedMask)   * 255) DIV byRedMask;
      lpPalette^.palPalEntry[i].peGreen := (((i shr pfd.cGreenShift) and byGreenMask) * 255) DIV byGreenMask;
      lpPalette^.palPalEntry[i].peBlue  := (((i shr pfd.cBlueShift)  and byBlueMask)  * 255) DIV byBlueMask;
      lpPalette^.palPalEntry[i].peFlags := 0;
    end;

    Palette := CreatePalette(lpPalette^);
    HeapFree(hHeap, 0, lpPalette);

    if (Palette <> 0) then begin
      SelectPalette(DC, Palette, False);
      RealizePalette(DC);
    end;
  end;
end;
//---------------------------------------------------------------------------
procedure TFormBoard.FormCreate(Sender: TObject);
begin
  inherited;
  DC := GetDC(Handle);
  SetDCPixelFormat;
  hrc := wglCreateContext(DC);
  wglMakeCurrent(DC, hrc);
  InitScene;
  wglMakeCurrent(0, 0);
  Camera.xpos:=0;
  Camera.ypos:=16;
  Camera.zpos:=-12;
  Camera.xat :=0;
  Camera.yat :=4;
  Camera.zat :=-2*0;
  Camera.xtop:=0;
  Camera.ytop:=10+2;
  Camera.ztop:=16;
end;
//---------------------------------------------------------------------------
procedure TFormBoard.FormDestroy(Sender: TObject);
begin
  inherited;
  Timer1.Enabled := False;
  FreeScene;
  wglMakeCurrent(0, 0);
  wglDeleteContext(hrc);
  ReleaseDC(Handle, DC);
  if (Palette <> 0) then
    DeleteObject(Palette);
end;
//---------------------------------------------------------------------------
function IsBoardWon:boolean;
var i,j:integer;

function CheckGetWinLine(xd,yd:integer;Player:TBoardPos;GetIt:boolean):boolean;
var  x,y,k:integer;
begin
  x:=i;y:=j;k:=0;
  if GetIt then BoardWinLine[x,y]:=Player;
  while BoardState[x,y]=Player do
  begin
    x:=x+xd;y:=y+yd;
    if (x>=0) and (x<=6) and (y>=0) and (y<=5) and (BoardState[x,y]=Player) then
    begin
      if GetIt then BoardWinLine[x,y]:=Player;
      inc(k)
    end else break;
  end;
  x:=i;y:=j;
  while BoardState[x,y]=Player do
  begin
    x:=x-xd;y:=y-yd;
    if (x>=0) and (x<=6) and (y>=0) and (y<=5) and (BoardState[x,y]=Player) then
    begin
      if GetIt then BoardWinLine[x,y]:=Player;
      inc(k)
    end else break;
  end;
  if k>=3 then result:=true
   else result:=false;
end;

function IsWinLine(xd,yd:integer):boolean;
begin
  result:=true;
  if CheckGetWinLine(xd,yd,Player1,false) then
  begin
    CheckGetWinLine(xd,yd,Player1,true);
    exit;
  end;
  if CheckGetWinLine(xd,yd,Player2,false) then
  begin
    CheckGetWinLine(xd,yd,Player2,true);
    exit;
  end;
  result:=false;
end;
begin
  for i:=0 to 6 do
    for j:=0 to 5 do
      BoardWinLine[i,j]:=empty;
  result:=true;
  for i:=0 to 6 do
    for j:=0 to 5 do
    begin
      if IsWinline(0,1) then exit;
      if IsWinline(1,0) then exit;
      if IsWinline(1,1) then exit;
      if IsWinline(-1,1) then exit;
    end;
  result:=false;
end;
//---------------------------------------------------------------------------
function GetPlayer:TBoardPos;
var i,j,k:integer;
begin
  k:=0;
  for i:=0 to 6 do
    for j:=0 to 5 do
      if BoardState[i,j]<> empty then inc(k);
  if k mod 2 =0 then result:=Player1 else result:=Player2;
end;
//---------------------------------------------------------------------------
procedure TFormBoard.FormClick(Sender: TObject);
  var i,j:integer;
  x,y:single;
begin
  inherited;
  if not ScreenVectorIntersectWithPlaneXY(LastMouseClickX,LastMouseClickY,0.9-BoardPosZ,x,y) then exit;
  j:=0;
  i:=round(3-x);
  if (i>=0) and (i<=6) then
  begin
    while (j<6) and (BoardState[i,j]<> empty) do inc(j);
    if (j<6) and not Timer1.Enabled and TrySquareSet(i,j) then
    begin
      LastMove.x:=i;
      LastMove.y:=j;
      LastMove.Score:=0;
      BoardState[i,j]:=GetPlayer;
      Timer1.Enabled:=IsBoardWon;
      InvalidateRect(Handle, nil, False);
    end;
  end;
end;
//---------------------------------------------------------------------------
procedure TFormBoard.SetSquare(x,y,Player,Score:integer);
var ActPlayer:TBoardPos;
begin
  inherited;
  case Player of
   0:ActPlayer:=empty;
   else ActPlayer:=GetPlayer;
  end;
  LastMove.x:=x;
  LastMove.y:=y;
  LastMove.Score:=Score;
  BoardState[x,y]:=ActPlayer;
  Timer1.Enabled:=IsBoardWon;
  InvalidateRect(Handle, nil, False);
end;
procedure TFormBoard.Timer1Timer(Sender: TObject);
begin
  inherited;
  if TimerCount<1000000 then
  inc(TimerCount)
  else TimerCount:=0;
  InvalidateRect(Handle, nil, False);
end;

procedure TFormBoard.Timer2Timer(Sender: TObject);
begin
  inherited;
  if TimerCount<25 then
  begin
    inc(TimerCount);
    Camera.ypos:=Camera.ypos-0.51;
    if Camera.ypos<4.1 then Camera.ypos:=4.1;
    FormPaint(nil);
  end
  else
  begin
    TimerCount:=0;
    Timer2.Enabled:=false;
  end;
end;

end.
