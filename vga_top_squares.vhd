LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY vga_top IS
    PORT (
        clk_in    : IN STD_LOGIC;
        vga_red   : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
        vga_green : OUT STD_LOGIC_VECTOR (2 DOWNTO 0);
        vga_blue  : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
        vga_hsync : OUT STD_LOGIC;
        vga_vsync : OUT STD_LOGIC;
        --
        btnl : IN STD_LOGIC;
        btnr : IN STD_LOGIC;
        btnu : IN STD_LOGIC;
        btnd : IN STD_LOGIC;
        --
        SEG7_anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- 7-segment anode outputs
        SEG7_seg   : OUT STD_LOGIC_VECTOR (0 TO 6)  -- 7-segment segment outputs
    );
END vga_top;

ARCHITECTURE Behavioral OF vga_top IS
    -- VGA Signals
    SIGNAL pxl_clk : STD_LOGIC;
    SIGNAL S_red, S_green, S_blue : STD_LOGIC_VECTOR (15 DOWNTO 0);
    SIGNAL combined_red, combined_green, combined_blue : STD_LOGIC;
    SIGNAL S_pixel_row, S_pixel_col : STD_LOGIC_VECTOR (10 DOWNTO 0);
    
    -- Mole Signals
    SIGNAL active_holes : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0'); -- Active mole holes
    
    -- Clock Signals
    SIGNAL btn_clk : STD_LOGIC; -- Button clock
    SIGNAL kp_clk : STD_LOGIC; -- Faster clock for the keypad process
    SIGNAL game_clk : STD_LOGIC; -- Slower clock for mole activation
    SIGNAL cnt : STD_LOGIC_VECTOR(30 DOWNTO 0); -- Counter for generating clocks
    
    -- Score and Display Signals
    SIGNAL score : INTEGER RANGE 0 TO 999 := 0; -- Current score
    SIGNAL seg7_data : STD_LOGIC_VECTOR (15 DOWNTO 0); -- Score in BCD format for the 7-segment display
    SIGNAL led_mpx : STD_LOGIC_VECTOR (2 DOWNTO 0); -- Multiplexing control for 7-segment display
    
    -- Miscellaneous Signals
    SIGNAL random_index : INTEGER RANGE 0 TO 15; -- Randomly chosen mole index
    SIGNAL game_on : STD_LOGIC := '1'; -- Indicates if the game is active
    SIGNAL btnc : STD_LOGIC; -- Button control signal
    SIGNAL speed_bit : INTEGER RANGE 10 TO 26 := 26; -- Clock bit controlling the mole activation speed
    
    -- RNG (Random Number Generator) Variables
    SIGNAL lfsr : STD_LOGIC_VECTOR (3 DOWNTO 0) := "1001"; -- Linear feedback shift register for RNG
    SIGNAL rng_counter : INTEGER RANGE 0 TO 80000000 := 0; -- RNG counter
    SIGNAL rng_limit : INTEGER RANGE 100000 TO 80000000 := 80000000; -- Initial RNG limit
    
    TYPE integer_array IS ARRAY (0 TO 1) OF INTEGER;
    TYPE position_array IS ARRAY (0 TO 3) OF integer_array;
    TYPE keypad_map_type IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(3 DOWNTO 0);

    CONSTANT hole_positions : position_array := (
        (350, 100),  -- up
        (200, 250),  -- left
        (500, 250),  -- right
        (350, 400)   -- down
    );

    COMPONENT vga_sync IS
        PORT (
            pixel_clk : IN STD_LOGIC;
            red_in    : IN STD_LOGIC;
            green_in  : IN STD_LOGIC;
            blue_in   : IN STD_LOGIC;
            red_out   : OUT STD_LOGIC;
            green_out : OUT STD_LOGIC;
            blue_out  : OUT STD_LOGIC;
            hsync     : OUT STD_LOGIC;
            vsync     : OUT STD_LOGIC;
            pixel_row : OUT STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT clk_wiz_0 IS
        PORT (
            clk_in1  : IN STD_LOGIC;
            clk_out1 : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT leddec16 IS
        PORT (
            dig   : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- Multiplexing digit selector
            data  : IN STD_LOGIC_VECTOR (15 DOWNTO 0); -- 16-bit data to display
            anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- Active anode control
            seg   : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)  -- Segment control
        );
    END COMPONENT;

    COMPONENT square IS
        PORT (
            pixel_row : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
            pixel_col : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
            active    : IN STD_LOGIC;
            x_pos     : IN INTEGER;
            y_pos     : IN INTEGER;
            red       : OUT STD_LOGIC;
            green     : OUT STD_LOGIC;
            blue      : OUT STD_LOGIC
        );
    END COMPONENT;

    FUNCTION or_reduce(signal_vector : STD_LOGIC_VECTOR) RETURN STD_LOGIC IS
        VARIABLE result : STD_LOGIC := '0';
    BEGIN
        FOR i IN signal_vector'RANGE LOOP
            result := result OR signal_vector(i);
        END LOOP;
        RETURN result;
    END FUNCTION;
    

BEGIN
    -- VGA synchronization
    vga_driver : vga_sync
        PORT MAP (
            pixel_clk => pxl_clk,
            red_in    => combined_red,
            green_in  => combined_green,
            blue_in   => combined_blue,
            red_out   => vga_red(2),
            green_out => vga_green(2),
            blue_out  => vga_blue(1),
            pixel_row => S_pixel_row,
            pixel_col => S_pixel_col,
            hsync     => vga_hsync,
            vsync     => vga_vsync
        );

    -- Clock wizard
    clk_wiz_0_inst : clk_wiz_0
        PORT MAP (
            clk_in1 => clk_in,
            clk_out1 => pxl_clk
        );
        
        
--    game_on_control_proc: PROCESS (btn_clk, kp_hit)
--    BEGIN
--        IF rising_edge(btn_clk) THEN
--            -- Toggle game_on when the button is pressed
--            IF btnc = '1' THEN
--                game_on <= NOT game_on;
--            END IF;
--        ELSIF kp_hit = '1' THEN
--            -- End the game on incorrect hit
--            IF TO_INTEGER(unsigned(kp_value)) /= current_mole THEN
--                game_on <= '0';
--            END IF;
--        END IF;
--    END PROCESS;

 
        ck_proc : PROCESS (pxl_clk)
        BEGIN
            IF rising_edge(pxl_clk) THEN -- on rising edge of clock
                cnt <= cnt + 1; -- increment counter
            END IF;
        END PROCESS;
    
    
        game_clk <= cnt(25);
        -- Derive button clock
        btn_clk <= cnt(25); 
  
        
    hole_and_keypad_logic_proc: PROCESS (cnt)
        VARIABLE rng_seed : INTEGER := 42; -- Seed for random number generation
        VARIABLE random_index : INTEGER := 0; -- Random value holder
        CONSTANT kp_clk_bit : INTEGER := 10; -- Fast clock bit for updating
        VARIABLE debounce_counter : INTEGER RANGE 0 TO 10 := 0; -- Debounce counter
        VARIABLE kp_hit_debounced : STD_LOGIC := '0'; -- Debounced key press signal
    BEGIN
        IF rising_edge(cnt(kp_clk_bit)) THEN
            -- Ensure at least one hole is active at the start of the game
            IF active_holes = (3 DOWNTO 0 => '0') THEN
                -- Initialize the first active mole
                rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768; -- Initialize RNG
                random_index := rng_seed MOD 4; -- Generate a random mole
                active_holes <= (3 DOWNTO 0 => '0'); -- Deactivate all holes
                active_holes(random_index) <= '1'; -- Activate the random mole
            END IF;
            
            IF btnu = '1' THEN
                IF active_holes(0) = '1' THEN
                    -- Correct
                    active_holes <= (3 DOWNTO 0 => '0'); -- Deactivate current hole
    
                    -- Generate and Activate a New Mole
                    rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768; -- Update RNG
                    random_index := rng_seed MOD 4; -- Choose new mole
                    active_holes(random_index) <= '1'; -- Activate new mole
                END IF;
            
            ELSIF btnl = '1' THEN
                IF active_holes(1) = '1' THEN
                    active_holes <= (3 DOWNTO 0 => '0'); -- Deactivate current hole
    
                    -- Generate and Activate a New Mole
                    rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768; -- Update RNG
                    random_index := rng_seed MOD 4; -- Choose new mole
                    active_holes(random_index) <= '1'; -- Activate new mole
                    -- Correct
                    
                END IF;
            ELSIF btnr = '1' THEN
                IF active_holes(2) = '1' THEN
                    -- Correct
                    active_holes <= (3 DOWNTO 0 => '0'); -- Deactivate current hole
    
                    -- Generate and Activate a New Mole
                    rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768; -- Update RNG
                    random_index := rng_seed MOD 4; -- Choose new mole
                    active_holes(random_index) <= '1'; -- Activate new mole
                END IF;
            ELSIF btnd = '1' THEN
                IF active_holes(3) = '1' THEN
                    -- Correct
                    active_holes <= (3 DOWNTO 0 => '0'); -- Deactivate current hole
    
                    -- Generate and Activate a New Mole
                    rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768; -- Update RNG
                    random_index := rng_seed MOD 4; -- Choose new mole
                    active_holes(random_index) <= '1'; -- Activate new mole
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Instantiate squares
    gen_squares: FOR i IN 0 TO 3 GENERATE
        ball_inst : square
            PORT MAP (
                pixel_row => S_pixel_row,
                pixel_col => S_pixel_col,
                active    => active_holes(i),
                x_pos     => hole_positions(i)(0),
                y_pos     => hole_positions(i)(1),
                red       => S_red(i),
                green     => S_green(i),
                blue      => S_blue(i)
            );
    END GENERATE;

    -- Combine signals for VGA
    combined_red <= or_reduce(S_red);
    combined_green <= or_reduce(S_green);
    combined_blue <= or_reduce(S_blue);

    -- Instantiate 7-segment display driver
    led_driver : leddec16
        PORT MAP (
            dig => led_mpx,
            data => seg7_data,
            anode => SEG7_anode,
            seg => SEG7_seg
        );
END Behavioral;
