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
    SIGNAL game_clk : STD_LOGIC; -- Slower clock for mole activation
    SIGNAL cnt : STD_LOGIC_VECTOR(30 DOWNTO 0); -- Counter for generating clocks
    
    SIGNAL seg7_data : STD_LOGIC_VECTOR (15 DOWNTO 0); -- Score in BCD format for the 7-segment display
    SIGNAL led_mpx : STD_LOGIC_VECTOR (2 DOWNTO 0); -- Multiplexing control for 7-segment display
    
    -- Miscellaneous Signals
    SIGNAL random_index : INTEGER RANGE 0 TO 15; -- Randomly chosen mole index
    SIGNAL game_on : STD_LOGIC := '1'; -- Indicates if the game is active
    
    -- reaction time 
    TYPE reaction_times IS ARRAY (0 TO 2) OF INTEGER; -- Store 3 reaction times
    SIGNAL rt : reaction_times := (0, 0, 0);
    SIGNAL current_trial : INTEGER RANGE 0 TO 3 := 0; -- Track current trial (0-2)
    SIGNAL timer_count : INTEGER := 0; -- Count clock cycles for reaction time
    SIGNAL measuring_time : STD_LOGIC := '0'; -- Flag for when we're measuring reaction time
    SIGNAL average_time : INTEGER := 0; -- Calculated average reaction time
    SIGNAL wait_for_next_trial: STD_LOGIC := '0';
     SIGNAL next_trial_counter: INTEGER := 0;
    
    -- states
    TYPE game_state_type IS (I, W, C, D);
    SIGNAL game_state : game_state_type := I;
    
    TYPE integer_array IS ARRAY (0 TO 1) OF INTEGER;
    TYPE position_array IS ARRAY (0 TO 3) OF integer_array;
    
    -- clock
    CONSTANT CLK_FREQ : INTEGER := 100000000; -- 100MHz clock frequency
    CONSTANT DIVIDER : INTEGER := CLK_FREQ/1000; -- Converts clock cycles to ms
    SIGNAL clk_1hz_out : STD_LOGIC;
    SIGNAL clk_1khz_out : STD_LOGIC;
    
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
    
    COMPONENT clk_1hz IS
      PORT (
        clk : IN STD_LOGIC;
        clk1 : OUT STD_LOGIC
      );
    END COMPONENT;

    COMPONENT clk_1khz IS
      PORT (
        clk : IN STD_LOGIC;
        clk2 : OUT STD_LOGIC
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
        
        -- 1Hz clock for game timing
        clock_1hz_inst : clk_1hz
        PORT MAP (
            clk => pxl_clk,      -- Input from pixel clock
            clk1 => clk_1hz_out  -- Output 1Hz signal
        );
        
        -- 1kHz clock for display 
        clock_1khz_inst : clk_1khz
        PORT MAP (
            clk => pxl_clk,       -- Input from pixel clock
            clk2 => clk_1khz_out  -- Output 1kHz signal
        );
       
        ck_proc : PROCESS (pxl_clk)
        BEGIN
            IF rising_edge(pxl_clk) THEN -- on rising edge of clock
                cnt <= cnt + 1; -- increment counter
            END IF;
        END PROCESS;
    
    
        game_clk <= clk_1hz_out; 
        btn_clk <= clk_1hz_out;     
  
    display_mpx_process: PROCESS(clk_1khz_out)
    BEGIN
        IF rising_edge(clk_1khz_out) THEN
            led_mpx <= led_mpx + 1;  -- Cycle through display digits
            IF led_mpx = "100" THEN  -- Only use first 4 digits (0-3)
                led_mpx <= "000";
            END IF;
        END IF;
    END PROCESS;

    game_logic_proc: PROCESS(pxl_clk)
        VARIABLE rng_seed : INTEGER := 42; -- Seed for random number generation
        VARIABLE random_index : INTEGER := 0; -- Random value holder
    BEGIN
        IF rising_edge(pxl_clk) THEN
            CASE game_state IS
                    WHEN I =>
                        -- start game
                        current_trial <= 0;
                        rt <= (0, 0, 0);
                        measuring_time <= '0';
                        
                        -- activate one square
                        rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768;
                        random_index := rng_seed MOD 4;
                        active_holes <= (OTHERS => '0');
                        active_holes(random_index) <= '1';
                        
                        game_state <= W;
                        measuring_time <= '1';
                        timer_count <= 0;
                    
                    WHEN W =>
                        IF measuring_time = '1' THEN
                            timer_count <= timer_count + 1;
                        END IF;
                    
                        IF wait_for_next_trial = '1' THEN
                            next_trial_counter <= next_trial_counter + 1;
                            IF next_trial_counter = 100000000 THEN
                                rng_seed := (rng_seed * 1103515245 + 12345) MOD 32768;
                                random_index := rng_seed MOD 4;
                                active_holes(random_index) <= '1';
                                measuring_time <= '1';
                                timer_count <= 0;
                                wait_for_next_trial <= '0';
                                next_trial_counter <= 0;
                            END IF;
                        ELSIF (btnu = '1' AND active_holes(0) = '1') OR
                              (btnl = '1' AND active_holes(1) = '1') OR
                              (btnr = '1' AND active_holes(2) = '1') OR
                              (btnd = '1' AND active_holes(3) = '1') THEN
                    
                            rt(current_trial) <= timer_count / DIVIDER;
                            measuring_time <= '0';
                            active_holes <= (OTHERS => '0');
                    
                            IF current_trial < 2 THEN
                                current_trial <= current_trial + 1;
                                wait_for_next_trial <= '1';
                            ELSE
                                game_state <= C;
                            END IF;
                        END IF;
                        
                       WHEN C =>
                            -- get average time
                            average_time <= ((rt(0)-5000) + rt(1) + rt(2)) / 3;
                            game_state <= D;
                    
                        WHEN D =>
                            -- display average time on board
                            seg7_data <= std_logic_vector(to_unsigned(average_time, 16));
                            --seg7_data <= x"0123";
                            
                            -- reset the game if any button is pressed
                            --IF btnu = '1' OR btnl = '1' OR btnr = '1' OR btnd = '1' THEN
                                --game_state <= I;
                    --END IF;
            END CASE;
        END IF;
    END PROCESS game_logic_proc;

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
