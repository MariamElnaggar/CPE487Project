# Instructions
- From https://github.com/byett/dsd/blob/CPE487-Spring2025/projects/README.md
## Submission (80% of your project grade):
* Your final submission should be a github repository of very similar format to the labs themselves with an opening README document with the expected components as follows:
	* “Modifications” (15 points of the Submission category)
		* If building on an existing lab or expansive starter code of some kind, describe your “modifications” – the changes made to that starter code to improve the code, create entirely new functionalities, etc. Unless you were starting from one of the labs, please share any starter code used as well, including crediting the creator(s) of any code used. It is perfectly ok to start with a lab or other code you find as a baseline, but you will be judged on your contributions on top of that pre-existing code!
	* Conclude with a summary of the process itself – who was responsible for what components (preferably also shown by each person contributing to the github repository!), the timeline of work completed, any difficulties encountered and how they were solved, etc. (10 points of the Submission category)
# Our Project
## Summary
For our project we decided to work on creating a reaction test that would challege the player to react to the display as fast as they can. From when the game begins four red blocks would appear on the display and at a random time one will turn green. Once the player successfully hit the three neccessary blocks the NexysA7 100T board will display the players average reaction time. In order to accomplish this we used base code from the [clock](https://github.com/cfoote5/CPE487_FinalProject) and [whack-a-mole](https://github.com/beartwoz/Whack-A-Mole) projects. These projects provided a good starting point for implementing a clock that would display milliseconds and developing the VGA display that the player would interact with.
## Expected Behavior
![FSM](FSM1.png)
- The VGA screen will display a four blocks (positioned up, down, left, and right) and whichever block turns green the player must hit the corresponding button on the board.
- The goal is to test how fast the player can react.
- The game will play for three rounds.
- The average time over the three rounds is the players score.
- The players score will display on the board in milliseconds.
### [Demonstration](https://drive.google.com/file/d/1wT0SU7qmNwO605OzWVExHnS3_MaBIyPG/view?usp=sharing)
## Requirments
- Nexys A7 100T Board
- Micro-USB to USB Cable
- Computer with Vivado installed
- Monitor
- VGA Cable
## Program Setup
### 1. Create new RTL project React_test in Vivado Quick Start
- Create eight new source files of file type VHDL called ***clk_1kHz***, ***Clock_1Hz***, ***clk_wiz_0***, ***clk_wiz_0_clk_wiz***, ***leddec16***, ***squares***, ***vga_sync***, and ***vga_top_squares***.
- Create a new constraint file of file type XDC called ***allcons***.
- Choose Nexys A7-100T board for the project
- Click 'Finish'
- Click design sources and copy the VHDL code from the repo.
- Click contraints and copy the code from allcons.xdc
- As an alternative, you can instead download files from Github and import them into your project when creating the project. The source file or files would still be imported during the Source step, and the constraint file or files would still be imported during the Constraints step.

### 2. Run synthesis
### 3. Run implementation
### 4. Generate bitstream, open hardware manager, and program device.
- Click 'Generate Bitstream'
- Click 'Open Hardware Manager' and click "Open Target' then 'Auto Connect'
- Click 'Program Device' to download the program to the Nexys A7-100T board.
## Description of the modules
### ***clk_1kHz.vhd***
This module produces a 1 kHz clock output (clk2) from the system clock input. It uses a counter that toggles the output every 50,000 cycles. This clock pulses every millisecond and was used to for the 7-segment display.
- Input: plk_clk (from clk_wiz_0)
- Output: clk_1khz_out
### ***clk_wiz_0.vhd***
This module defines a clock management module that generates a stable system clock (clk_out1) from a primary input clock (clk_in1). This module ensures that all time-dependent components—such as the VGA synchronization (vga_sync), the 1 kHz and 1 Hz clock dividers, and display timing logic—receive a precise and reliable clock signal.
- Input: clk_in (from board)
- Output: plk_clk
### ***clk_wiz_0_clk_wiz.vhd***
This module is an auto-generated clock management module from Vivado. This module is used to help ensure that the system operates with properly derived clock signals, helping reduce timing errors.
- Input: clk_in1
- Output: clk_out1
### ***clock_1Hz***
This module creates a 1 Hz clock pulse from a faster input clock. It uses a counter that toggles an internal signal every 50 million clock cycles, effectively dividing the clock to 1 Hz for the game timing controlling the rate at which the squares appear.
- Input: pxl_clk (from clk_wiz_0)
- Output: clk_1hz_out
### ***leddec16.vhd***
This module implements a display decoder that shows 4-digit values on an 8-digit 7-segment display. It selects which digit to display using the dig input and extracts a 4-bit data point from the 16-bit data input to convert into segment outputs (seg). It also activates the corresponding anode for the selected digit.
- Input: led_mpx (used to choose the digits), seg7_data (data to display)
- Output: SEG7_anode (anodes on the display), SEG7_seg (segments to turn on based on the digits)
#### Modification
We added the code below to convert our binary data input to decmial and modified the code to display it on the 7-segment display.
```
SIGNAL decimal_value : STD_LOGIC_VECTOR (15 DOWNTO 0);
BEGIN
    -- change binary to decimal
	PROCESS(data)
		VARIABLE temp : STD_LOGIC_VECTOR(15 DOWNTO 0);
		VARIABLE decimal : UNSIGNED(15 DOWNTO 0) := (OTHERS => '0');
		VARIABLE binary : UNSIGNED(15 DOWNTO 0);
	BEGIN
		binary := unsigned(data);
		decimal := (OTHERS => '0');
		
		for i in 0 to 15 loop
			if decimal(3 downto 0) > 4 then 
				decimal(3 downto 0) := decimal(3 downto 0) + 3;
			end if;
			if decimal(7 downto 4) > 4 then 
				decimal(7 downto 4) := decimal(7 downto 4) + 3;
			end if;
			if decimal(11 downto 8) > 4 then 
				decimal(11 downto 8) := decimal(11 downto 8) + 3;
			end if;
			
			-- Shift left
			decimal := decimal(14 downto 0) & binary(15);
			binary := binary(14 downto 0) & '0';
		end loop;
		
		decimal_value <= std_logic_vector(decimal);
	END PROCESS;
	data4 <= decimal_value(3 DOWNTO 0) WHEN dig = "000" ELSE -- digit 0
		         decimal_value(7 DOWNTO 4) WHEN dig = "001" ELSE -- digit 1
		         decimal_value(11 DOWNTO 8) WHEN dig = "010" ELSE -- digit 2
		         decimal_value(15 DOWNTO 12); -- digit 3
		-- Turn on segments corresponding to 4-bit data word
		seg <= "0000001" WHEN data4 = "0000" ELSE -- 0
		       "1001111" WHEN data4 = "0001" ELSE -- 1
		       "0010010" WHEN data4 = "0010" ELSE -- 2
		       "0000110" WHEN data4 = "0011" ELSE -- 3
		       "1001100" WHEN data4 = "0100" ELSE -- 4
		       "0100100" WHEN data4 = "0101" ELSE -- 5
		       "0100000" WHEN data4 = "0110" ELSE -- 6
		       "0001111" WHEN data4 = "0111" ELSE -- 7
		       "0000000" WHEN data4 = "1000" ELSE -- 8
		       "0000100" WHEN data4 = "1001" ELSE -- 9
		       "1111111";
```
- Base code from [leddec16.vhd](https://github.com/beartwoz/Whack-A-Mole/blob/c3509649d219f83ef390502cbf7bf8d1a7126aee/leddec16.vhd) in [whack-a-mole](https://github.com/beartwoz/Whack-A-Mole)
### ***squares.vhd***
This module determines whether the current VGA pixel lies within a user-defined square. It uses input coordinates (x_pos, y_pos) as the top-left corner of the square and compares them with the current pixel column and row values. If the pixel lies within the square and the active signal is high, it outputs colored signals (red, green). This module forms the core of rendering geometric shapes on the screen.
- Input: S_pixel_row, S_pixel_col (both from vga_sync), active_holes(i), hole_positions(i)(0) (x_pos), hole_positions(i)(1) (y_pos) (the rest from vga_top_squares)
- Output: S_red(i), S_green(i), S_blue(i)
#### Modification
We changed the size of the squares and their colors
```
ARCHITECTURE Behavioral OF square IS
    CONSTANT hole_width  : INTEGER := 100; -- Width of each square
    CONSTANT hole_height : INTEGER := 100; -- Height of each square
...
            IF active = '1' THEN
                red <= '0'; -- Hole is active (green)
                green <= '1';
                blue <= '0';
            ELSE
                red <= '1'; -- Hole is inactive (red)
                green <= '0';
                blue <= '0';
            END IF;
        ELSE
            red <= '0'; -- Outside the hole area (black)
            green <= '0'; 
            blue <= '0';
```
- Base code from [ball_moles.vhd](https://github.com/beartwoz/Whack-A-Mole/blob/c3509649d219f83ef390502cbf7bf8d1a7126aee/ball_moles.vhd) in [whack-a-mole](https://github.com/beartwoz/Whack-A-Mole)
### ***vga_sync.vhd***
This module generates the necessary VGA timing signals to produce a correct image on screen. It takes a pixel clock and RGB inputs and outputs hsync, vsync, pixel row and column positions (pixel_row, pixel_col), and routed RGB signals.
### ***vga_top_squares.vhd***
This module serves as the top level entity named vga_top. This module directs the entire VGA display system receiving input from directional buttons (btnl, btnr, btnu, btnd) and driving the VGA output signals (vga_red, vga_green, vga_blue, vga_hsync, vga_vsync). It integrates submodules for clocking, synchronization, square drawing, and LED display. Additionally, it outputs data to a 7-segment display through SEG7_anode for score.
