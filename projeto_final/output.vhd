LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.ALL;

ENTITY output IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		reset    : IN STD_LOGIC; 
		count		: IN UNSIGNED (31 DOWNTO 0);
		done     : IN STD_LOGIC;
		tempo		: OUT UNSIGNED (31 DOWNTO 0);
		igual    : OUT STD_LOGIC
	);
END output;


ARCHITECTURE SYN OF output IS

BEGIN
	main: process(clock, reset, count, done)
   begin
		if(rising_edge(clock)) then
			if(reset = '0') then
				if(done = '1') then
					tempo <= count / 500; --dividir pela frequência do clock
					igual <= '1';
				end if;
			else
				tempo <= X"00000000";
				igual <= '0';
			end if;
		end if;
	end process main;
END SYN;
