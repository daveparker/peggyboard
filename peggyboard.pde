/* Peggy2 - Peggyboard 1.0.1

   Electronic message board. Leave notes up to 24 characters long! ...like
   "Dinner at Store" or "Rinse Lather Repeat".

   Written by Dave Parker http://daveparker42.blogspot.com/
   Some snippets of code were based on the Meggy Jr. library and Peggy2 
   "Game of Life" code by Windell Oskay (and others).
   
   Requires peggy 2.x by Evil Mad Science Laboratories (http://www.evilmadscientist.com/)
   with optional buttons installed for cursor movement and character selection.
   
   Uses the Peggy2 Library version 0.3b (http://code.google.com/p/peggy/).
   Tested with a Peggy 2.1 with an ATMega168. Compiled using arduino-014 and all the
   various goodies within.
   
   Note: The message is stored in the Peggy's EEPROM so it persists after the
   peggy is switched off. The EEPROM is only updated when a character is
   changed to maximize the life of the EEPROM.

   Usage:
  
   - Press SELECT or a DIRECTION KEY to enter EDIT MODE (with flashing cursor).
     Note: If there is no message or a blank message stored on the Peggy's 
     EEPROM it will start off in EDIT MODE.
   - Use DIRECTION KEYS to move the cursor. Hold down to scroll.
   - Press SELECT to edit the character. Character will be underlined.
   -- LEFT and RIGHT to move between characters. Hold down to scroll.
   -- UP to cycle through 'L', 'l', '5', and '*'. To jump around the character set.
   -- DOWN to clear the character.
   -- SELECT to save the change.
   -- ANY to abort the change.
   - While in EDIT MODE, press ANY to turn off the cursor (DISPLAY MODE).
   - While in DISPLAY MODE, hold down both ANY and SELECT for 4 seconds to clear
     the message.

   Versions

   1.0.1 - One line change to only write characters that have actually been changed
           to the EEPROM.

   1.0 - Initial release with all the juicy features listed above.
     
  Copyright (c) 2009 Dave Parker.  All right reserved.

  This example is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This software is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this software; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

*/

#include <Peggy2.h>
#include <avr/pgmspace.h>
#include <EEPROM.h>

#define EEPROM_HEADER_H 0x1
#define EEPROM_HEADER_L 0x2

#define CHAR_WIDTH 3
#define CHAR_HEIGHT 5
#define ROWS 4
#define COLS 6
#define MAX_X 5
#define MAX_Y 3

#define CURSOR_DELAY_TIME 150
#define SCROLL_INITIAL_DELAY_TIME 500
#define SCROLL_REPEAT_DELAY_TIME 300
#define CHAR_SCROLL_INITIAL_DELAY_TIME 500
#define CHAR_SCROLL_REPEAT_DELAY_TIME 100
#define RESET_DELAY_TIME 4000

#define ANY_PRESSED    (gButtonsPressed & 1)
#define LEFT_PRESSED   (gButtonsPressed & 2)
#define DOWN_PRESSED   (gButtonsPressed & 4)
#define UP_PRESSED     (gButtonsPressed & 8)
#define RIGHT_PRESSED  (gButtonsPressed & 16)
#define SELECT_PRESSED (gButtonsPressed & 32)

#define ANY_RELEASED    (gButtonsReleased & 1)
#define LEFT_RELEASED   (gButtonsReleased & 2)
#define DOWN_RELEASED   (gButtonsReleased & 4)
#define UP_RELEASED     (gButtonsReleased & 8)
#define RIGHT_RELEASED  (gButtonsReleased & 16)
#define SELECT_RELEASED (gButtonsReleased & 32)

#define ANY_HELD    (gButtonState & 1)
#define LEFT_HELD   (gButtonState & 2)
#define DOWN_HELD   (gButtonState & 4)
#define UP_HELD     (gButtonState & 8)
#define RIGHT_HELD  (gButtonState & 16)
#define SELECT_HELD (gButtonState & 32)

char gMessage[COLS * ROWS];
char gTempChar;

#define FIRST_CHAR ' '
#define LAST_CHAR  '~'

PROGMEM word characters[] = {
  0x0000, //  0000 0000 0000 0000
  0x2092, //! 0010 0000 1001 0010
  0x002D, //" 0000 0000 0010 1101
  0x5F7D, //# 0101 1111 0111 1101
  0x3DDE, //$ 0011 1101 1101 1110
  0x42A1, //% 0100 0010 1010 0001
  0x6AAA, //& 0110 1010 1010 1010
  0x0012, //' 0000 0000 0001 0010
  0x4494, //( 0100 0100 1001 0100
  0x1491, //) 0001 0100 1001 0001
  0x55D5, //* 0101 0101 1101 0101
  0x05D0, //+ 0000 0101 1101 0000
  0x1400, //, 0001 0100 0000 0000
  0x01C0, //- 0000 0001 1100 0000
  0x2000, //. 0010 0000 0000 0000
  0x02A0, /// 0000 0010 1010 0000
  0x7B6F, //0 0111 1011 0110 1111
  0x749A, //1 0111 0100 1001 1010
  0x73E7, //2 0111 0011 1110 0111
  0x79A7, //3 0111 1001 1010 0111
  0x49ED, //4 0100 1001 1110 1101
  0x79CF, //5 0111 1001 1100 1111
  0x7BCF, //6 0111 1011 1100 1111
  0x4927, //7 0100 1001 0010 0111
  0x7BEF, //8 0111 1011 1110 1111
  0x79EF, //9 0111 1001 1110 1111
  0x0410, //: 0000 0100 0001 0000
  0x1410, //; 0001 0100 0001 0000
  0x4454, //< 0100 0100 0101 0100
  0x0E38, //= 0000 1110 0011 1000
  0x1511, //> 0001 0101 0001 0001
  0x20A7, //? 0010 0000 1010 0111
  0x62EA, //@ 0110 0010 1110 1010
  0x5BEA, //A 0101 1011 1110 1010
  0x3AEB, //B 0011 1010 1110 1011  
  0x624E, //C 0110 0010 0100 1110
  0x3B6B, //D 0011 1011 0110 1011
  0x72CF, //E 0111 0010 1100 1111
  0x12CF, //F 0001 0010 1100 1111
  0x6B4E, //G 0110 1011 0100 1110
  0x5BED, //H 0101 1011 1110 1101
  0x7497, //I 0111 0100 1001 0111
  0x2B27, //J 0010 1011 0010 0111
  0x5AED, //K 0101 1010 1110 1101
  0x7249, //L 0111 0010 0100 1001
  0x5BFD, //M 0101 1011 1111 1101
  0x5B6F, //N 0101 1011 0110 1111
  0x2B6A, //O 0010 1011 0110 1010
  0x12EB, //P 0001 0010 1110 1011
  0x4D6A, //Q 0100 1101 0110 1010
  0x5AEB, //R 0101 1010 1110 1011
  0x388E, //S 0011 1000 1000 1110
  0x2497, //T 0010 0100 1001 0111
  0x7B6D, //U 0111 1011 0110 1101
  0x2B6D, //V 0010 1011 0110 1101
  0x5FED, //W 0101 1111 1110 1101
  0x5AAD, //X 0101 1010 1010 1101
  0x24AD, //Y 0010 0100 1010 1101
  0x72A7, //Z 0111 0010 1010 0111
  0x6496, //[ 0110 0100 1001 0110
  0x0888, //\ 0000 1000 1000 1000
  0x3493, //] 0011 0100 1001 0011
  0x002A, //^ 0000 0000 0010 1010
  0x7000, //_ 0111 0000 0000 0000
  0x0011, //` 0000 0000 0001 0001
  0x7B80, //a 0111 1011 1000 0000
  0x3AC9, //b 0011 1010 1100 1001
  0x6380, //c 0110 0011 1000 0000
  0x6BA4, //d 0110 1011 1010 0100
  0x6770, //e 0110 0111 0111 0000
  0x25D4, //f 0010 0101 1101 0100
  0x3D50, //g 0011 1101 0101 0000
  0x5AC9, //h 0101 1010 1100 1001
  0x2482, //i 0010 0100 1000 0010
  0x1482, //j 0001 0100 1000 0010
  0x5748, //k 0101 0111 0100 1000
  0x7493, //l 0111 0100 1001 0011
  0x5FC0, //m 0101 1111 1100 0000
  0x5AC0, //n 0101 1010 1100 0000
  0x2A80, //o 0010 1010 1000 0000
  0x1750, //p 0001 0111 0101 0000
  0x4D50, //q 0100 1101 0101 0000
  0x13C0, //r 0001 0011 1100 0000
  0x3580, //s 0011 0101 1000 0000
  0x65D0, //t 0110 0101 1101 0000
  0x6B40, //u 0110 1011 0100 0000
  0x2B40, //v 0010 1011 0100 0000
  0x7F40, //w 0111 1111 0100 0000
  0x5540, //x 0101 0101 0100 0000
  0x39E8, //y 0011 1001 1110 1000
  0x64C0, //z 0110 0100 1100 0000
  0x64D6, //{ 0110 0100 1101 0110
  0x2492, //| 0010 0100 1001 0010
  0x3593, //} 0011 0101 1001 0011
  0x001E, //~ 0000 0000 0001 1110
};

Peggy2 gFrame;
char gXCursor = 0;
char gYCursor = 0;
boolean gCursorOn = true;
boolean gScrolling = false;
unsigned long gCursorLastUpdatedTime;
unsigned long gTimeOfInterest; 
byte gButtonState = 0;
byte gPreviousButtonState = 0;
byte gButtonsPressed = 0;
byte gButtonsReleased = 0;
enum ScrollDirection_e { NO_DIRECTION, UP, DOWN, LEFT, RIGHT } gScrollDirection = NO_DIRECTION;
enum ProgramState_e { NO_STATE, DISPLAYING, EDITING, CHAR_EDIT } gProgramState, gNextProgramState;
ProgramState_e gOldProgramState = NO_STATE;


void setup()
{
  gFrame.HardwareInit();
  
  DDRB = 254U;  // B0 is an input ("OFF/SELECT" button)
  DDRC = 0;     // All inputs
  PORTB = 1;    // Pull up on ("OFF/SELECT" button)
  PORTC = 255U; // Pull-ups on C
  
  LoadMessage();
  DisplayMessage();
  
  if (MessageIsBlank()) {
    gNextProgramState = EDITING;
  } else {
    gNextProgramState = DISPLAYING;
  }
  
  UpdateButtonState();
}


void loop()
{
  gProgramState = gNextProgramState;
  UpdateButtonState();
  
  switch (gProgramState) {
    case DISPLAYING:
      DisplayLoop();
      break;
    case EDITING:
      EditingLoop();
      break;
    case CHAR_EDIT:
      CharEditLoop();
      break;
  }
  
  gFrame.RefreshAll(64);
  gOldProgramState = gProgramState;
}

// PROGRAM MODE SPECIFIC LOOPS -----------------------------------------------------------

void DisplayLoop()
{
  unsigned long currentTime = millis();

  if (gOldProgramState != DISPLAYING) {
    DrawRect(getXPos(gXCursor), getYPos(gYCursor), CHAR_WIDTH + 2, CHAR_HEIGHT + 2, false);       
  }
  
  if (ANY_PRESSED || SELECT_PRESSED) {
    gTimeOfInterest = currentTime;
  }
  
  if (SELECT_RELEASED) {
    gNextProgramState = EDITING;
  }
  
  if (UP_PRESSED || DOWN_PRESSED || LEFT_PRESSED || RIGHT_PRESSED) {
    gNextProgramState = EDITING;
  }
  
  if (ANY_HELD && SELECT_HELD) {
    if ((currentTime - gTimeOfInterest) > RESET_DELAY_TIME) {
      ClearMessage();
      SaveMessage();
      DisplayMessage();
      gNextProgramState = EDITING;
    }
  }
}


void EditingLoop()
{  
  unsigned long currentTime = millis();
  char oldXCursor = gXCursor;
  char oldYCursor = gYCursor;
  
  if (gOldProgramState != EDITING) {
    gCursorLastUpdatedTime = millis();
  }
  
  if (ANY_PRESSED) {
    gNextProgramState = DISPLAYING;
  }
  
  if (SELECT_PRESSED) {
    gNextProgramState = CHAR_EDIT;
  }
  
  if (UP_PRESSED) {
    gScrolling = false;
    gScrollDirection = UP;
    gTimeOfInterest = currentTime;
    gYCursor--;
    if(gYCursor < 0) {
      gYCursor = MAX_Y;
    }
  }
  
  if (UP_RELEASED && gScrollDirection == UP) {
    gScrolling = false;
  }
  
  if (DOWN_PRESSED) {
    gScrolling = false;
    gScrollDirection = DOWN;
    gTimeOfInterest = currentTime;
    gYCursor++;
    if(gYCursor > MAX_Y) {
      gYCursor = 0;
    }
  }

  if (DOWN_RELEASED && gScrollDirection == DOWN) {
    gScrolling = false;
  }

  if (LEFT_PRESSED) {
    gScrolling = false;
    gScrollDirection = LEFT;
    gTimeOfInterest = currentTime;
    gXCursor--;
    if(gXCursor < 0) {
      gXCursor = MAX_X;
    }
  }

  if (LEFT_RELEASED && gScrollDirection == LEFT) {
    gScrolling = false;
  }
  
  if (RIGHT_PRESSED) {
    gScrolling = false;
    gScrollDirection = RIGHT;
    gTimeOfInterest = currentTime;
    gXCursor++;
    if(gXCursor > MAX_X) {
      gXCursor = 0;
    }
  }

  if (RIGHT_RELEASED && gScrollDirection == RIGHT) {
    gScrolling = false;
  }

  int scrollDelay = (gScrolling) ? SCROLL_REPEAT_DELAY_TIME : SCROLL_INITIAL_DELAY_TIME;

  if (UP_HELD && gScrollDirection == UP) {
    if ((currentTime - gTimeOfInterest) > scrollDelay) {
      gScrolling = true;
      gYCursor--; // move up
      if(gYCursor < 0) {
        gYCursor = MAX_Y;
      }
      gTimeOfInterest = currentTime;
    }
  }
    
  if (DOWN_HELD && gScrollDirection == DOWN) {
    if ((currentTime - gTimeOfInterest) > scrollDelay) {
      gScrolling = true;
      gYCursor++; // move down
      if(gYCursor > MAX_Y) {
        gYCursor = 0;
      }
      gTimeOfInterest = currentTime;
    }
  }
  
  if (LEFT_HELD && gScrollDirection == LEFT) {
    if ((currentTime - gTimeOfInterest) > scrollDelay) {
      gScrolling = true;
      gXCursor--;
      if(gXCursor < 0) {
        gXCursor = MAX_X;
      }
      gTimeOfInterest = currentTime;
    }
  }
  
  if (RIGHT_HELD && gScrollDirection == RIGHT) {
    if ((currentTime - gTimeOfInterest) > scrollDelay) {
      gScrolling = true;
      gXCursor++;
      if(gXCursor > MAX_X) {
        gXCursor = 0;
      }
      gTimeOfInterest = currentTime;
    }
  }

  if (oldXCursor != gXCursor || oldYCursor != gYCursor) {
    DrawRect(getXPos(oldXCursor), getYPos(oldYCursor), CHAR_WIDTH + 2, CHAR_HEIGHT + 2, false);       
    //Immediately redraw cursor in new location.
    DrawRect(getXPos(gXCursor), getYPos(gYCursor), CHAR_WIDTH + 2, CHAR_HEIGHT + 2, gCursorOn); 
  }

  if ((currentTime - gCursorLastUpdatedTime) > CURSOR_DELAY_TIME) {
   gCursorOn = !gCursorOn;
   DrawRect(getXPos(gXCursor), getYPos(gYCursor), CHAR_WIDTH + 2, CHAR_HEIGHT + 2, gCursorOn); 
   gCursorLastUpdatedTime = currentTime;
  }
}


void CharEditLoop()
{  
  unsigned long currentTime = millis();
  
  if (gOldProgramState != CHAR_EDIT) {
    DrawRect(getXPos(gXCursor), getYPos(gYCursor), CHAR_WIDTH + 2, CHAR_HEIGHT + 2, false);       
    DrawRect(getXPos(gXCursor), getYPos(gYCursor) + CHAR_HEIGHT + 1, CHAR_WIDTH + 2, 1, true);
    gTempChar = gMessage[gXCursor + gYCursor * COLS];
  }
  
  if (RIGHT_PRESSED) {
    gScrolling = false;
    gScrollDirection = RIGHT;
    gTimeOfInterest = currentTime;
    gTempChar++;
    if (gTempChar > LAST_CHAR) {
      gTempChar = FIRST_CHAR;
    }
  }
  
  if (RIGHT_RELEASED && gScrollDirection == RIGHT) {
    gScrolling = false;
  }

  if (LEFT_PRESSED) {
    gScrolling = false;
    gScrollDirection = LEFT;
    gTimeOfInterest = currentTime;
    gTempChar--;
    if (gTempChar < FIRST_CHAR) {
      gTempChar = LAST_CHAR;
    }
  }
  
  if (LEFT_RELEASED && gScrollDirection == LEFT) {
    gScrolling = false;
  }

  if (UP_PRESSED) {
    if (gTempChar >= 'A' && gTempChar <= 'Z') {
      gTempChar = 'l';
    } else if (gTempChar >= 'a' && gTempChar <= 'z') {
      gTempChar = '5';
    } else if (gTempChar >= '0' && gTempChar <= '9') {
      gTempChar = '*';
    } else {
      gTempChar = 'L';
    }
  }
  
  if (DOWN_PRESSED) {
    gTempChar = ' ';
  }

  int scrollDelay = (gScrolling) ? CHAR_SCROLL_REPEAT_DELAY_TIME : CHAR_SCROLL_INITIAL_DELAY_TIME;
  
  if (RIGHT_HELD && gScrollDirection == RIGHT) {
    if ((currentTime - gTimeOfInterest) > scrollDelay) {
      gScrolling = true;
      gTempChar++;
      if (gTempChar > LAST_CHAR) {
        gTempChar = FIRST_CHAR;
      }
      gTimeOfInterest = currentTime;
    }
  }

  if (LEFT_HELD && gScrollDirection == LEFT) {
    if ((currentTime - gTimeOfInterest) > scrollDelay) {
      gScrolling = true;
      gTempChar--;
      if (gTempChar < FIRST_CHAR) {
        gTempChar = LAST_CHAR;
      }
      gTimeOfInterest = currentTime;
    }
  }
  
  if (SELECT_PRESSED) {
    gNextProgramState = EDITING;
    if (gMessage[gXCursor + gYCursor * COLS] != gTempChar) {
      gMessage[gXCursor + gYCursor * COLS] = gTempChar;
      SaveChar(gTempChar);
    }
  }
  
  if (ANY_PRESSED) {
    gNextProgramState = EDITING;
    gTempChar = gMessage[gXCursor + gYCursor * COLS];
  }
  
  printChar(gTempChar, getXPos(gXCursor) + 1, getYPos(gYCursor) + 1);
}

// UTILITY FUNCTIONS  --------------------------------------------------------------

void UpdateButtonState()
{
  gPreviousButtonState = gButtonState;
  gButtonState =  ~(((PINB & 1) << 5) | (PINC & 31));  // Select, Right, Up, Down, Left, Any
  byte changedInputs = gButtonState ^ gPreviousButtonState;
  gButtonsPressed = changedInputs & gButtonState;
  gButtonsReleased = changedInputs & ~gButtonState;
}


void LoadMessage()
{  
  // First check to see if a two byte header is present giving some assurance that the
  // subsequent bytes are actually a peggyboard message.
  // Returns a blank (all spaces) message if a header is not found.
  if (EEPROM.read(0) != EEPROM_HEADER_H || EEPROM.read(1) != EEPROM_HEADER_L) {
    ClearMessage();
    return;
  }
  
  char tmpChar;
  for (byte i = 0; i < ROWS * COLS; i++) {
    tmpChar = EEPROM.read(i + 2);
    if (tmpChar < FIRST_CHAR || tmpChar > LAST_CHAR) {
      tmpChar = ' ';
    }
    gMessage[i] = tmpChar;
  }
}


void SaveMessage()
{
  EEPROM.write(0, EEPROM_HEADER_H);
  EEPROM.write(1, EEPROM_HEADER_L);
  for (byte i = 0; i < ROWS * COLS; i++) {
    EEPROM.write(i + 2, gMessage[i]);
  }
}


void SaveChar(char aChar)
{
  // Check to see if the eeprom is initialized for messages before writing a single byte
  if (EEPROM.read(0) != EEPROM_HEADER_H || EEPROM.read(1) != EEPROM_HEADER_L) {
    SaveMessage();
  } 
  EEPROM.write(2 + gXCursor + gYCursor * COLS, aChar);
}


void ClearMessage()
{
  for (byte i = 0; i < ROWS * COLS; i++) {
    gMessage[i] = ' ';
  }
}


boolean MessageIsBlank()
{
  for (byte i = 0; i < ROWS * COLS; i++) {
    if (gMessage[i] != ' ') {
      return false;
    }
  }
  return true;
}


void DisplayMessage()
{
  gFrame.Clear();
  byte x, y;
  for (y = 0; y <= MAX_Y; y++) {
    for (x = 0; x <= MAX_X; x++) {
      printChar(gMessage[x + y * COLS], getXPos(x) + 1, getYPos(y) + 1);
    }
  }
}


char getXPos(char x)
{
 return x * (CHAR_WIDTH + 1);
}


char getYPos(char y)
{
 return y * (CHAR_HEIGHT + 1);
}


void printChar(char c, byte xPos, byte yPos)
{
  byte i, x, y;
  for (i = 0; i < 15; i++ ) {
    y = yPos + i / CHAR_WIDTH;
    x = xPos + i % CHAR_WIDTH;
    if (pgm_read_word_near(characters + c - FIRST_CHAR) & 1 << i) {
      gFrame.SetPoint(x, y);
    } else {
      gFrame.ClearPoint(x, y);
    }
  }
}


void DrawRect(char x1, char y1, byte rectWidth, byte rectHeight, boolean state)
{
  char x, y;
  byte x2 = x1 + rectWidth - 1;
  byte y2 = y1 + rectHeight - 1;
  for (x = x1; x <= x2; x++) {
    gFrame.WritePoint(x, y1, state);
  }
  for (x = x1; x <= x2; x++) {
    gFrame.WritePoint(x, y2, state);
  }
  for (y  = y1; y <= y2; y++) {
    gFrame.WritePoint(x1, y, state);
  }  
  for (y  = y1; y <= y2; y++) {
    gFrame.WritePoint(x2, y, state);
  }
}
