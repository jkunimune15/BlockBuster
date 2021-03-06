/*
  BlockBuster.pde
 
 Example file using the The Meggy Jr Simplified Library (MJSL)
  from the Meggy Jr RGB library for Arduino
   
   Oh, no!  Earth is being invaded by round, stationary spaceships!  Prepare
   to take on the armada with your trusty, deadly... ping-pong paddle?
   Advance through the waves, collect powerups, and save the human race!  Just
   be sure not to lose your ball!
 
 Version 1.25 - 12/2/2008
 Copyright (c) 2008 Windell H. Oskay.  All right reserved.
 http://www.evilmadscientist.com/
 
 This library is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this library.  If not, see <http://www.gnu.org/licenses/>.
 	  
 */

 
 
 
 

/*
 * Adapted from "Blink,"  The basic Arduino example.  
 * http://www.arduino.cc/en/Tutorial/Blink
 */

#include <MeggyJrSimple.h>

struct point {int x; int y;};
struct projectile {int x; int y; int slope; int yvelocity; boolean inplay;};
projectile ball[3] = {{4, 2, 3, 1, true}};
point paddle = {3, 0};
int level;
int difficulty;
boolean moved;
boolean started;
boolean oneup;
int onfire;
int waittime;
int LED;
int timer;
int failures;


void setup()
{
  MeggyJrSimpleSetup(); 
  Serial.begin(9600);
  EditColor(White, 13, 4, 3);
  EditColor(CustomColor0, 15, 0, 0);
  EditColor(CustomColor1, 15, 0, 15);
  EditColor(CustomColor2, 15, 0, 15);
  EditColor(CustomColor3, 15, 0, 15);
  EditColor(CustomColor4, 8, 0, 8);
  failures = 0;
  level = 1;
  difficulty = 1;
  reset();
}


void loop() 
{ 
  EraseObjects();
  
  UpdateBall();
  
  UpdatePaddle();
  
  UpdatePowerups();
  
  DrawObjects();
  
  delay(waittime);
  
  if (Button_A || Button_B || Button_Up)
    started = true;
    
  while (Button_Down)
  {
    CheckButtonsDown();
  }
  
  if (YouHaveWon())
    RunVictory();
  
  timer++;
}


void reset()
{
  ClearSlate();
  for (int i = 0; i < 3; i++)
  {
    ball[i].x = 3;
    ball[i].y = 1;
    ball[i].slope = random(2)*4-2;
    ball[i].yvelocity = 1;
    ball[i].inplay = false;
  }
  ball[0].inplay = true;
  paddle.x = 3;
  paddle.y = 0;
  moved = false;
  started = false;
  oneup = false;
  onfire = 0;
  waittime = 8;
  EditColor(White, 13, 4, 3);
  timer = 0;
  switch (difficulty)
  {
    case 1:
      Level1();
      break;
    case 2:
      Level2();
      break;
    case 3:
      Level3();
      break;
    case 4:
      Level4();
      break;
    case 5:
      Level5();
  }
  DrawPx(random(8), random(5)+3, CustomColor4);
}


void EraseObjects()
{
  for (int v = 0; v < 3; v++)
    if (ball[v].inplay)
      DrawPx(ball[v].x, ball[v].y, Dark);
      
    DrawPx(paddle.x, 0, Dark);
  
  for(int j = -1; j < 2; j++)
    DrawPx(paddle.x + j, paddle.y, Dark);
}


void DrawObjects()
{
  for (int j = -1; j < 2; j++)
    DrawPx(paddle.x + j, paddle.y, Blue);
  
  DrawPx(paddle.x, 0, Blue);
    
  for (int u = 0; u < 3; u++)
    if (ball[u].inplay)
      DrawPx(ball[u].x, ball[u].y, White);
      
  DisplaySlate();
  
  LED = 0;
  for(int e = 0; e < difficulty; e++)
    LED = 2*LED + 1;
  SetAuxLEDs(LED);
}


void UpdatePowerups()
{
  for(int b = 0; b < 8; b++)
    for(int c = 0; c < 8; c++)
      if(ReadPx(b, c) == CustomColor3)
      {
        DrawPx(b, c, CustomColor2);
        Tone_Start(ToneB5, 50);
      }
      
  if (timer % 40 == 0)
  {
    for(int b = 0; b < 8; b++)
      if(ReadPx(b, 0) == CustomColor2)
        DrawPx(b, 0, Dark);
    
    for(int b = 0; b < 8; b++)
      for(int c = 1; c < 8; c++)
        if(ReadPx(b, c) == CustomColor2 && ReadPx(b, c - 1) == 0)
        {
          DrawPx(b, c, Dark);
          DrawPx(b, c - 1, CustomColor2);
        }
      
    for(int b = 0; b < 8; b++)
      for(int c = 0; c < 8; c++)
        if(ReadPx(b, c) == CustomColor1)
          DrawPx(b, c, Dark);
  }
  for (int v = -1; v < 2; v++)
    if (ReadPx(paddle.x + v, paddle.y) == CustomColor2)
      switch (random(5))
      {
        case 0:
          MultiBall();
          break;
        case 1:
          InstaLaser();
          break;
        case 2:
          OneUp();
          break;
        case 3:
          Fireball();
          break;
        default:
          Accelerate();
      }  
}


void UpdateBall()
{
  if (started)
  {
    for (int n = 0; n < 3; n++)
      if (ball[n].inplay)
      {
        if(timer % (60/ball[n].slope) == 0)
          BounceX(n);
    
        if (timer % 30 == 0)
          BounceY(n);
    
        if (timer % (60/ball[n].slope) == 0 && timer % 30 == 0)
          BounceDiagonal(n);
  
        if(timer % (60/ball[n].slope) == 0)
        {
          if (ball[n].slope > 0)
            ball[n].x++;
          if (ball[n].slope < 0)
            ball[n].x--;
        }

        if (timer % 30 == 0)
        {
          ball[n].y += ball[n].yvelocity;
        }
  
        StopTeleport(n);
          
        if (ball[n].x == paddle.x - 2)
          if (ball[n].y == 0 && paddle.y == 0)
          {
            ball[n].x--;
            ball[n].slope = -abs(ball[n].slope);
          }
            
        if (ball[n].x == paddle.x + 2)
          if (ball[n].y == 0 && paddle.y == 0)
          {
            ball[n].x++;
            ball[n].slope = abs(ball[n].slope);
          }
            
        if (ball[n].x - paddle.x < 2 && ball[n].x - paddle.x > -2)
          if (ball[n].y == paddle.y)
          {
            ball[n].y++;
            SlopeChange(n);
          }
      }
    
    if (onfire > 0)
      onfire--;
    else if (oneup)
      EditColor(White, 15, 12, 4);
    else
      EditColor(White, 13, 4, 3);
  
    if (!ball[0].inplay & !ball[1].inplay & !ball[2].inplay)
      GameOver();
  }
  
  else
  {
    ball[0].x = paddle.x;
    ball[0].y = paddle.y + 1;
  }
}


void StopTeleport(int index)
{
  if (ball[index].x > 7)
    ball[index].x = 7;
  if (ball[index].x < 0)
    ball[index].x = 0;
  if (ball[index].y > 7)
    ball[index].y = 7;
  if (ball[index].y < 0)
    ball[index].y = 0;
}


void UpdatePaddle()
{
  MovePress();
  
  if (timer % 20 == 0)
    MoveHold();
  
  CheckButtonsDown();
    
  if (Button_Up)
    paddle.y = 1;
  else
    paddle.y = 0;
}


void MovePress()
{
  CheckButtonsPress();
  
  if (Button_Right && paddle.x < 6)
  {
    paddle.x++;
    moved = true;
  }
    
  if (Button_Left && paddle.x > 1)
  {
    paddle.x--;
    moved = true;
  }
}


void MoveHold()
{
  CheckButtonsDown();
  
  if (!moved)
  {
    if (Button_Right && paddle.x < 6)
      paddle.x++;
  
    if (Button_Left && paddle.x > 1)
      paddle.x--;
  }
    
  moved = false;
}


void BounceY(int index)
{
  if (ball[index].yvelocity > 0)
  {
    if (ball[index].y > 6)
    {
      ball[index].yvelocity = -1;
      Tone_Start(ToneB4, 50);
    }
    
    if (ReadPx(ball[index].x, ball[index].y+1) > 0 && onfire == 0)
    {
      ball[index].yvelocity = -1;
      DrawPx(ball[index].x, ball[index].y+1, ReadPx(ball[index].x, ball[index].y+1) - 1);
      Tone_Start(ToneB3, 50);
    }
  }
  
  if (ball[index].yvelocity < 0)
  {
    if (ReadPx(ball[index].x, ball[index].y-1) > 0 && onfire == 0)
    {
      ball[index].yvelocity = 1;
      DrawPx(ball[index].x, ball[index].y-1, ReadPx(ball[index].x, ball[index].y-1) - 1);
      Tone_Start(ToneB3, 50);
    }
    
    if (ball[index].y < paddle.y + 2)
      SlopeChange(index);
  }
  if (ball[index].y < 1)
    ball[index].inplay = false;
}


void BounceX(int index)
{
  if (ball[index].slope > 0)
  {
    if (ball[index].x > 6)
    {
      ball[index].slope = -ball[index].slope;
      Tone_Start(ToneB4, 50);
    }
    
    if (ball[index].x == paddle.x - 2 && ball[index].y == paddle.y)
    {
      ball[index].slope = -ball[index].slope;
      Tone_Start(ToneB4, 50);
    }
    
    if (ReadPx(ball[index].x+1, ball[index].y) > 0 && onfire == 0)
    {
      ball[index].slope = -ball[index].slope;
      DrawPx(ball[index].x+1, ball[index].y, ReadPx(ball[index].x+1, ball[index].y) - 1);
      Tone_Start(ToneB3, 50);
    }  
  }
  
  if (ball[index].slope < 0)
  {
    if (ball[index].x < 1)
      ball[index].slope = abs(ball[index].slope);
      
    if (ReadPx(ball[index].x-1, ball[index].y) > 0 && onfire == 0)
    {
      ball[index].slope = abs(ball[index].slope);
      DrawPx(ball[index].x-1, ball[index].y, ReadPx(ball[index].x-1, ball[index].y) - 1);
      Tone_Start(ToneB3, 50);
    }
    
    if (ball[index].x < 1)
      Tone_Start(ToneB4, 50);
      
    if (ball[index].x == paddle.x + 2 && ball[index].y == paddle.y)
    {
      ball[index].slope = abs(ball[index].slope);
      Tone_Start(ToneB4, 50);
    }
  }
}


void BounceDiagonal(int index)
{
  if (ball[index].slope > 0 && ball[index].yvelocity > 0)
    if (ReadPx(ball[index].x+1, ball[index].y+1) > 0 && onfire == 0)
    {
      ball[index].slope = -ball[index].slope;
      ball[index].yvelocity = -1;
      DrawPx(ball[index].x+1, ball[index].y+1, ReadPx(ball[index].x+1, ball[index].y+1)-1);
      Tone_Start(ToneB3, 50);
    }
  
  if (ball[index].slope > 0 && ball[index].yvelocity < 0)
    if (ReadPx(ball[index].x+1, ball[index].y-1) > 0 && onfire == 0)
    {
      ball[index].slope = -ball[0].slope;
      ball[index].yvelocity = 1;
      DrawPx(ball[index].x+1, ball[index].y-1, ReadPx(ball[index].x+1, ball[index].y-1)-1);
      Tone_Start(ToneB3, 50);
    }
  
  if (ball[index].slope < 0 && ball[index].yvelocity > 0)
    if (ReadPx(ball[index].x-1, ball[index].y+1) > 0 && onfire == 0)
    {
      ball[index].slope = abs(ball[index].slope);
      ball[index].yvelocity = -1;
      DrawPx(ball[index].x-1, ball[index].y+1, ReadPx(ball[index].x-1, ball[index].y+1)-1);
      Tone_Start(ToneB3, 50);
    }
  
  if (ball[index].slope < 0 && ball[index].yvelocity < 0)
    if (ReadPx(ball[index].x-1, ball[index].y-1) > 0 && onfire == 0)
    {
      ball[index].slope = abs(ball[index].slope);
      ball[index].yvelocity = 1;
      DrawPx(ball[index].x-1, ball[index].y-1, ReadPx(ball[index].x-1, ball[index].y-1)-1);
      Tone_Start(ToneB3, 50);
    }
}
  

void SlopeChange(int ballindex)
{
  switch (paddle.x - ball[ballindex].x)
  {
    case -2:
      if (ball[ballindex].slope < 0)
      {
        ball[ballindex].yvelocity = 1;
        ball[ballindex].slope += 2;
        Tone_Start(ToneB4, 50);
      }
      break;
    case -1:
      ball[ballindex].yvelocity = 1;
      ball[ballindex].slope++;
      Tone_Start(ToneB4, 50);
      break;
    case 0:
      ball[ballindex].yvelocity = 1;
      Tone_Start(ToneB4, 50);
      break;
    case 1:
      ball[ballindex].yvelocity = 1;
      ball[ballindex].slope--;
      Tone_Start(ToneB4, 50);
      break;
    case 2:
      if (ball[ballindex].slope > 0)
      {
        ball[ballindex].yvelocity = 1;
        ball[ballindex].slope -= 2;
        Tone_Start(ToneB4, 50);
      }
  }
}


void MultiBall()
{
  for (int g = 0; g < 3; g++)
    if (ball[g].inplay)
    {
      ball[(g+1)%3].x = ball[g].x;
      ball[(g+1)%3].y = ball[g].y;
      ball[(g+1)%3].slope = -ball[g].slope;
      ball[(g+1)%3].yvelocity = ball[g].yvelocity;
      ball[(g+1)%3].inplay = true;
      ball[(g+2)%3].x = ball[g].x;
      ball[(g+2)%3].y = ball[g].y;
      ball[(g+2)%3].slope = ball[g].slope;
      ball[(g+2)%3].yvelocity = -ball[g].yvelocity;
      ball[(g+2)%3].inplay = true;
    }
    
  Tone_Start(ToneB5,300);
  delay(50);
  Tone_Start(ToneB4,300);
  delay(50);
  Tone_Start(ToneB5,50);  
}


void InstaLaser()
{
  DrawObjects();
  
  Tone_Start(ToneD7, 200);
  for (int h = 1; h < 8; h++)
  {
    DrawPx(paddle.x, h, FullOn);
    DisplaySlate();
    delay(15);
  }
  
  Tone_Start(ToneD6, 200);
  for (int h = 1; h < 8; h++)
  {
    DrawPx(paddle.x, h, Dark);
    DisplaySlate();
    delay(15);
  }
  
  Tone_Start(ToneB5, 200);
}


void OneUp()
{
  EditColor(White, 15, 12, 4);
  oneup = true;
  Tone_Start(ToneC6,150);
  delay(100);
  Tone_Start(ToneE6,150);
  delay(100);
  Tone_Start(ToneC6,150);
  delay(100);
  Tone_Start(ToneE6,150);
  delay(100);
  Tone_Start(ToneG6,200);
}


void Fireball()
{
  EditColor(White, 25, 1, 0);
  onfire = 2000;
  Tone_Start(ToneF5,200);
  delay(100);
  Tone_Start(ToneE5,200);
  delay(100);
  Tone_Start(ToneC5,200);
  delay(100);
  Tone_Start(ToneD5,100);
}


void Accelerate()
{
  waittime = 4;
  Tone_Start(ToneC5,300);
  delay(100);
  Tone_Start(ToneCs5,300);
  delay(100);
  Tone_Start(ToneD5,200);
}


boolean YouHaveWon()
{
  for (int p = 0; p < 8; p++)
    for (int o = 0; o < 8; o++)
      switch (ReadPx(o, p))
      {
        case 1:
          return false;
          break;
        case 2:
          return false;
          break;
        case 3:
          return false;
      }
  return true;
}


void RunVictory()
{
  for(int i=0;i<8;i++)
    for(int j=0;j<8;j++)
      DrawPx(i,j,Green);
  DisplaySlate();
  Tone_Start(ToneC5,150);
  delay(150);
  Tone_Start(ToneE5,150);
  delay(150);
  Tone_Start(ToneC6,150);
  delay(150);
  level++;
  difficulty++;
  reset();
}


void GameOver()
{
  if (oneup)
  {
    oneup = false;
    EditColor(White, 13, 4, 3);
    ball[0].inplay = true;
    ball[0].yvelocity = 1;
    ball[0].x = 3;
    ball[0].y = 2;
  }
  else
  {
    failures++;
    DisplaySlate();
    delay(200);
    for(int i=0;i<8;i++)
      for(int j=0;j<8;j++)
        DrawPx(i, j, CustomColor0);
    DisplaySlate();
    Tone_Start(ToneB2,400);
    delay(500);
    Tone_Start(ToneB2,400);
    delay(500);
    Tone_Start(ToneB2,500);
    delay(500);
    reset();
  }
}


void Level1()
{
  for (int i = 2; i < 6; i++)
    for (int k = 5; k < 8; k++)
       DrawPx(i, k, Red);
}


void Level2()
{
  for (int i = 2; i < 6; i++)
    for (int k = 5; k < 8; k++)
       DrawPx(i, k, Red);
  for (int i = 2; i < 6; i++)
    DrawPx(i, 4, Orange);
}


void Level3()
{
  for (int i = 2; i < 6; i++)
    for (int k = 5; k < 8; k++)
       DrawPx(i, k, Red);
  for (int i = 2; i < 6; i+=3)
    for (int k = 5; k < 8; k++)
       DrawPx(i, k, Orange);
  for (int i = 2; i < 6; i++)
    DrawPx(i, 4, Yellow);
  DrawPx(3, 3, Yellow);
  DrawPx(4, 3, Yellow);
}


void Level4()
{
  for (int i = 2; i < 6; i++)
    for (int k = 6; k < 8; k++)
       DrawPx(i, k, Yellow);
  for (int i = 0; i < 3; i++)
    for (int k = 3; k < 5; k++)
       DrawPx(i, k, Red);
  for (int i = 5; i < 8; i++)
    for (int k = 3; k < 5; k++)
       DrawPx(i, k, Red);
  DrawPx(2, 4, Dark);
  DrawPx(5, 4, Dark);
  DrawPx(2, 6, Dark);
  DrawPx(5, 6, Dark);
}


void Level5()
{
  for(int i=0;i<8;i++)
    for(int j=0;j<8;j++)
      DrawPx(i,j,Green);
  DisplaySlate();
  delay(600);
  Tone_Start(ToneC5,150);
  delay(150);
  Tone_Start(ToneE5,150);
  delay(150);
  Tone_Start(ToneG5,150);
  delay(150);
  Tone_Start(ToneF5,150);
  delay(150);
  Tone_Start(ToneA5,150);
  delay(150);
  Tone_Start(ToneC6,150);
  delay(150);
  Tone_Start(ToneG5,150);
  delay(150);
  Tone_Start(ToneB5,150);
  delay(150);
  Tone_Start(ToneD6,150);
  delay(150);
  Tone_Start(ToneC6,300);
  delay(600);
  ClearSlate();
  ShowNumeral(0, (failures - failures%10) /10);
  ShowNumeral(4, failures%10);
  while (true)
  {
  }
}


void ShowNumeral(int column, int digit)
{
  int color;
  if (failures < 15)
    color = 4 - failures/3;
  else
    color = 1;
    
  switch(digit)
  {
    case 0:
      for(int q = 0; q < 4; q += 3)
        for(int w = 1; w < 6; w++)
          DrawPx(q + column, w, color);
      for(int q = 0; q < 8; q += 6)
        for(int w = 1; w < 3; w++)
          DrawPx(w + column, q, color);
      break;
      
    case 1:
      for (int w = 0; w < 7; w++)
        DrawPx(2 + column, w, color);
      break;
      
    case 2:
      for (int w = 0; w < 4; w++)
        DrawPx(w + column, 0, color);
      DrawPx(column, 1, color);
      DrawPx(column, 2, color);
      DrawPx(column + 1, 3, color);
      DrawPx(column + 2, 3, color);
      DrawPx(column + 3, 4, color);
      DrawPx(column + 3, 5, color);
      DrawPx(column + 1, 6, color);
      DrawPx(column + 2, 6, color);
      DrawPx(column, 5, color);
      break;
      
    case 3:
      for (int w = 1; w < 6; w++)
        DrawPx(column + 3, w, color);
      DrawPx(column + 3, 3, Dark);
      for (int q = 1; q < 3; q++)
        for (int w = 0; w < 7; w += 3)
          DrawPx(q + column, w, color);
      DrawPx(column, 1, color);
      DrawPx(column, 5, color);
      break;
      
    case 4:
      for (int w = 0; w < 7; w++)
        DrawPx(column + 3, w, color);
      for (int w = 0; w < 4; w++)
        DrawPx(column + w, 3, color);
      for (int w = 3; w < 7; w++)
        DrawPx(column, w, color);
      break;
      
    case 5:
      for (int q = 1; q < 3; q++)
        for (int w = 0; w < 7; w += 3)
          DrawPx(column + q, w, color);
      for (int w = 1; w < 7; w++)
        DrawPx(column, w, color);
      DrawPx(column, 2, Dark);
      DrawPx(column + 3, 1, color);
      DrawPx(column + 3, 2, color);
      DrawPx(column + 3, 6, color);
      break;
      
    case 6:
      for (int w = 1; w < 6; w++)
        DrawPx(column, w, color);
      for (int q = 1; q < 3; q++)
        for (int w = 0; w < 7; w += 3)
          DrawPx(column + q, w, color);
      DrawPx(column + 3, 1, color);
      DrawPx(column + 3, 2, color);
      DrawPx(column + 3, 5, color);
      break;
      
    case 7:
      for (int w = 0; w < 4; w++)
        DrawPx(column + w, 6, color);
      for (int q = 0; q < 2; q++)
        for (int w = 0; w < 3; w++)
          DrawPx(column + 1 + w, 2*w + q, color);
      break;
      
    case 8:
      for (int q = 0; q < 4; q += 3)
        for (int w = 1; w < 6; w++)
          DrawPx(column + q, w, color);
      for (int q = 1; q < 3; q++)
        for (int w = 0; w < 7; w += 3)
          DrawPx(column + q, w, color);
      DrawPx(column, 3, Dark);
      DrawPx(column + 3, 3, Dark);
      break;
      
    case 9:
      for (int w = 1; w < 6; w++)
        DrawPx(column + 3, w, color);
      for (int q = 1; q < 3; q++)
        for (int w = 0; w < 7; w += 3)
          DrawPx(column + q, w, color);
      DrawPx(column, 1, color);
      DrawPx(column, 4, color);
      DrawPx(column, 5, color);
  }
  DisplaySlate();
}
