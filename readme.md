# DungeonTaker

### About
This is the final project of Assembly Language and System Programming course of National Central University. It is an replica of Helltaker by vanripper in x86 assembly. All game design and concepts belongs to the original creator.

### Run the game
Clone the repository to any location in your computer. ~~Make sure the .wav sound effect files are in the same directory of the executable.~~ Optional background music `bgmusic.mp3` can be place in the same directory. The game will play it automatically.
### Build
MASM32 SDK was used to develope this project.  
1. Open `DungeonTaker.inc` and change the include path `include \masm32\INCLUDE\XXX.inc` and `include \masm32\INCLUDE\XXX.lib` to your masm inc and lib path.  
2. Open `make.bat` and change the path `include \masm32\BIN\XXX.exe` to your masm bin path.
3. Make sure the resource path is matched in your `DungeonTaker.rc` file.
4. Use the `make.bat` to assemble and link the object files.
  
**Note**: Using newer version of ml.exe might cause issue.

### Acknowledgement
Simple Dungeon Crawler 16x16 Pixel Art Asset Pack by o-Lobster.  
Authorized by CC0 1.0 Public Domain Dedication license.  