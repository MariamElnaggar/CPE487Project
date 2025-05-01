LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY square IS
    PORT (
        pixel_row : IN STD_LOGIC_VECTOR(10 DOWNTO 0); -- Current row on VGA
        pixel_col : IN STD_LOGIC_VECTOR(10 DOWNTO 0); -- Current column on VGA
        active    : IN STD_LOGIC; -- Active state of the squar
        x_pos     : IN INTEGER; -- X-coordinate of the squares's top-left corner
        y_pos     : IN INTEGER; -- Y-coordinate of the squares's top-left corner
        red       : OUT STD_LOGIC; -- Red color output
        green     : OUT STD_LOGIC; -- Green color output
        blue      : OUT STD_LOGIC -- Blue color output
    );
END square;

ARCHITECTURE Behavioral OF square IS
    CONSTANT hole_width  : INTEGER := 100; -- Width of each square
    CONSTANT hole_height : INTEGER := 100; -- Height of each square
BEGIN
    PROCESS (pixel_row, pixel_col)
    BEGIN
        -- Convert pixel_row and pixel_col from STD_LOGIC_VECTOR to INTEGER
        IF (TO_INTEGER(UNSIGNED(pixel_col)) >= x_pos AND 
            TO_INTEGER(UNSIGNED(pixel_col)) < x_pos + hole_width AND
            TO_INTEGER(UNSIGNED(pixel_row)) >= y_pos AND 
            TO_INTEGER(UNSIGNED(pixel_row)) < y_pos + hole_height) THEN
            
            IF active = '1' THEN
                red <= '0'; -- Hole is active (red)
                green <= '1';
                blue <= '0';
            ELSE
                red <= '1'; -- Hole is inactive (black)
                green <= '0';
                blue <= '0';
            END IF;
        ELSE
            red <= '0'; -- Outside the hole area (background color)
            green <= '0'; 
            blue <= '0';
        END IF;
    END PROCESS;
END Behavioral;
