LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

ENTITY to_ascii IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		count		: IN UNSIGNED (31 DOWNTO 0);
		ascii		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END to_ascii;

ARCHITECTURE SYN OF to_ascii IS

signal temp1, temp2, temp3 : UNSIGNED (31 DOWNTO 0);
signal dig1, dig2, dig3, dig4 : UNSIGNED (31 DOWNTO 0);

BEGIN
	main: process(clock, count)
   begin
		if(rising_edge(clock)) then
			dig1  <= (count rem 10) + 48;
			temp1 <= count / 10;
			dig2  <= (temp1 rem 10)  + 48;
			temp2 <= temp1 / 10;
			dig3  <= (temp2 rem 10)  + 48;
			temp3 <= temp2 / 10;
			dig4  <= (temp3 rem 10)  + 48;
			ascii <= std_logic_vector(dig4(7 DOWNTO 0) & dig3(7 DOWNTO 0) & dig2(7 DOWNTO 0) & dig1(7 DOWNTO 0));
		end if;
	end process main;
END SYN;
