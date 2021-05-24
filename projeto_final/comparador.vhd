LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY lpm;
USE lpm.all;

ENTITY comparador IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
		aeb		: OUT STD_LOGIC 
	);
END comparador;


ARCHITECTURE SYN OF comparador IS
BEGIN
	main: process(clock, dataa, datab)
   begin
		if(rising_edge(clock)) then
			if(datab = X"0000000000000000") then
				aeb <= '0';
			elsif(dataa = datab) then
				aeb <= '1';
			else
				aeb <= '0';
			end if;
		end if;
	end process main;
END SYN;
