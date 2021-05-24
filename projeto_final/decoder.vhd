-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II 64-Bit"
-- VERSION		"Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition"
-- CREATED		"Sat May 22 23:30:44 2021"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY decoder IS 
	PORT
	(
		clk :  IN  STD_LOGIC;
		iniciar :  IN  STD_LOGIC;
		rst :  IN  STD_LOGIC;
		data_in :  IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
		saida_igual :  OUT  STD_LOGIC;
		saida_tempo :  OUT  STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END decoder;

ARCHITECTURE bdf_type OF decoder IS 

COMPONENT md5
	PORT(clk : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 iniciar : IN STD_LOGIC;
		 entrada : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 finalizado : OUT STD_LOGIC;
		 iniciar_en : OUT STD_LOGIC;
		 debug : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		 saida : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
	);
END COMPONENT;

COMPONENT comparador
	PORT(clock : IN STD_LOGIC;
		 dataa : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		 datab : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		 aeb : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT contador
	PORT(clock : IN STD_LOGIC;
		 aclr : IN STD_LOGIC;
		 q : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT output
	PORT(clock : IN STD_LOGIC;
		 reset : IN STD_LOGIC;
		 done : IN STD_LOGIC;
		 count : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 igual : OUT STD_LOGIC;
		 tempo : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT to_ascii
	PORT(clock : IN STD_LOGIC;
		 count : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ascii : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC_VECTOR(63 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_5 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_6 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_7 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_8 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_9 :  STD_LOGIC_VECTOR(31 DOWNTO 0);


BEGIN 



b2v_inst : md5
PORT MAP(clk => clk,
		 reset => rst,
		 iniciar => SYNTHESIZED_WIRE_0,
		 entrada => SYNTHESIZED_WIRE_1,
		 finalizado => SYNTHESIZED_WIRE_3,
		 iniciar_en => SYNTHESIZED_WIRE_7,
		 saida => SYNTHESIZED_WIRE_2);


b2v_inst1 : comparador
PORT MAP(clock => clk,
		 dataa => data_in,
		 datab => SYNTHESIZED_WIRE_2,
		 aeb => SYNTHESIZED_WIRE_4);


b2v_inst2 : contador
PORT MAP(clock => SYNTHESIZED_WIRE_3,
		 aclr => rst,
		 q => SYNTHESIZED_WIRE_6);


b2v_inst3 : output
PORT MAP(clock => clk,
		 reset => rst,
		 done => SYNTHESIZED_WIRE_4,
		 count => SYNTHESIZED_WIRE_5,
		 igual => saida_igual,
		 tempo => SYNTHESIZED_WIRE_9);


b2v_inst4 : to_ascii
PORT MAP(clock => clk,
		 count => SYNTHESIZED_WIRE_6,
		 ascii => SYNTHESIZED_WIRE_1);


SYNTHESIZED_WIRE_0 <= SYNTHESIZED_WIRE_7 OR iniciar;


SYNTHESIZED_WIRE_8 <= iniciar OR rst;


b2v_inst7 : contador
PORT MAP(clock => clk,
		 aclr => SYNTHESIZED_WIRE_8,
		 q => SYNTHESIZED_WIRE_5);


b2v_inst8 : to_ascii
PORT MAP(clock => clk,
		 count => SYNTHESIZED_WIRE_9,
		 ascii => saida_tempo);


END bdf_type;