LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY leddec16 IS
	PORT (
		dig : IN STD_LOGIC_VECTOR (2 DOWNTO 0); -- which digit to currently display
		data : IN STD_LOGIC_VECTOR (15 DOWNTO 0); -- 16-bit (4-digit) data
		anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0); -- which anode to turn on
		seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)); -- segment code for current digit
END leddec16;

ARCHITECTURE Behavioral OF leddec16 IS
	SIGNAL data4 : STD_LOGIC_VECTOR (3 DOWNTO 0); -- binary value of current digit
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
	-- Select digit data to be displayed in this mpx period
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
	-- Turn on anode of 4-segment display addressed by 3-bit digit selector dig
	anode <= "11111110" WHEN dig = "000" ELSE -- 0
	         "11111101" WHEN dig = "001" ELSE -- 1
	         "11111011" WHEN dig = "010" ELSE -- 2
	         "11110111" WHEN dig = "011" ELSE -- 3
	         "11111111";
END Behavioral;
