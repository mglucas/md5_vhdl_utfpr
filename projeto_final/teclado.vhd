----------------------------------------------------------------------------------
-- Universidade Tecnologica Federal do Parana
-- Disciplina  Logica Reconfiguravel
-- 05/2021
-- Integrantes
-- Alexandre Matias
-- Enrico Manfron
-- Giuliana Martins
-- Lucas Ricardo
-- Victor Feitosa

-- Descricao
-- Este codigo trata da implementacao de um driver para um teclado matricial 
-- assim fazendo a varredura de suas linhas e colunas para determinar a tecla pressionada
-- e tambem armazenando essas teclas em um buffer para enviar ao mds posteriormente
--

----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;        -- for addition & counting
use ieee.numeric_std.all;               -- for type conversions

entity teclado is
	port (
		lin : in std_logic_vector (3 downto 0);   -- responsavel por realizar a leitura da linha pressionada
		col : out std_logic_vector (3 downto 0);  -- responsavel por energizar uma coluna para efetuar a varredura
		num : out std_logic_vector (7 downto 0);  -- apresenta o digito pressionado 
		md5_str : out std_logic_vector (31 downto 0); -- apresenta os 4 digitos pressionados de uma senha para entrada do md5
		md5_trigger : out std_logic;                  -- responsavel por sinalizar ao md5 que inicie o calculo do hash
		clk , rst: in std_logic 					  -- clock e reset gerais do sistema
	) ;
end teclado;

architecture teclado_arc of teclado is
	-- estados responsaveis por controlar o armazenamento da senha e o bounce do teclado
	type state is (inicio, espera_pressionar, espera_bounce, aciona_lin_event,espera_soltar);
    signal pr_state, nx_state: state; 
	
	-- buffer responsavel por armazenar 4 digitos para o md5
	type arr is array (0 to 3) of std_logic_vector(7 downto 0);
	signal pass_buffer : arr := (X"00",X"00",X"00",X"00"); 


	signal count : std_logic_vector (4 downto 0);
	signal out_col : std_logic_vector (3 downto 0);
	signal out_num : std_logic_vector (7 downto 0);
    signal lin_event, md5_trigger_sig, action : std_logic := '0';
    

begin
	-- liga o buffer da senha para uma saida diretamente ligada ao md5
	md5_str(31 downto 24) <= pass_buffer(0);
	md5_str(23 downto 16) <= pass_buffer(1);
	md5_str(15 downto 8)  <= pass_buffer(2);
	md5_str(7 downto 0)   <= pass_buffer(3);
	
	process(clk) -- esse processo eh resposavel por realizar a varredura das colunas no teclado matricial e tambem por mudar o estado da maquina de estados
			variable trava : integer := 0;
	begin
		if rising_edge(clk) then
			if rst = '1' or count = "10000" then
				count <= "00001";
			elsif md5_trigger_sig = '1' and trava = 0 then
				count <= "00000";
				trava := 1;
			elsif md5_trigger_sig = '0' and trava = 1 then
				trava := 0;	
			elsif lin = "0000" then
				count <= count + count;
			else
				count <= count;
			end if;

			if (rst = '1') then
				 pr_state <= inicio; 
			else
				 pr_state <= nx_state; 
			end if; 
		end if;
	end process;
	
	process(lin_event) -- esse processo eh responsavel por armazenar a senha se houver menos de 4 digitos ou entao se houver 4 digitos acionar o md5 quando o enter eh pressionado 
		variable j : integer := 0;
	begin
		if (lin_event'event and lin_event = '1') then
			if (out_num >= X"30" and out_num <= X"39" and j < 4 )then  
				pass_buffer(j) <= out_num;
				md5_trigger_sig  <= '0';
				j:= j + 1;
			elsif (out_num = X"FA" and j <= 4 and md5_trigger_sig = '0') then
				md5_trigger_sig  <= '1';
				j:= 0;
			end if;
		end if;
	end process;

	process (action) -- essa maquina de estados eh responsavel por gerenciar o bounce para a o armazenamento e ativacao corretos do md5 
        variable j : integer := 1;
    begin
    	if action'event and action = '1' then
    		if pr_state = inicio then
    			lin_event <= '0'; 
    			nx_state <= espera_pressionar;
    		elsif (pr_state = espera_pressionar) then
    			lin_event <= '0';
    			if ((out_num >= X"30" and out_num<= X"39") or out_num = X"FA") then
    				nx_state <= espera_bounce;
    				j := 0;
    			else
    				nx_state <= espera_pressionar;
    			end if;
    		elsif (pr_state = espera_bounce) then
    			lin_event <= '0';
    			if (j <= 10_000_000 ) then
    				j:= j + 1;
    				nx_state <= espera_bounce;
    			else
    				nx_state <= aciona_lin_event;
    			end if;
			
    		elsif (pr_state = aciona_lin_event) then
    			lin_event <= '1';
    			nx_state <= espera_soltar;
    		
			elsif (pr_state = espera_soltar) then
				lin_event <= '1';
				if (out_num /= X"FF") then
					nx_state <= espera_soltar;
				else 
					nx_state <= espera_pressionar;
				end if;
			end if;
        end if;
    end process;

	action <= not clk;
	
	md5_trigger <= md5_trigger_sig; -- sinal que ativa o md5 controler

	
	-- parte responsavel por decodificar qual tecla esta sendo pressionada dados sinais de linha e coluna 
	
	col <= out_col;
	num <= out_num;
	out_col <= count(3 downto 0) when lin = "0000" else out_col;
	out_num <=  X"31" when count = "1000" and lin = "1000" else
				X"32" when count = "0100" and lin = "1000" else
				X"33" when count = "0010" and lin = "1000" else
				X"34" when count = "1000" and lin = "0100" else
				X"35" when count = "0100" and lin = "0100" else
				X"36" when count = "0010" and lin = "0100" else
				X"37" when count = "1000" and lin = "0010" else
				X"38" when count = "0100" and lin = "0010" else
				X"39" when count = "0010" and lin = "0010" else
				X"30" when count = "0100" and lin = "0001" else
				X"FA" when count = "0010" and lin = "0001" else
				X"FF";
end  teclado_arc;
