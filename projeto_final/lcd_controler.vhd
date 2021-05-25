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
-- Este codigo implementa uma maquina de estados que inicializa e depois escreve
-- todos os digitos necessarios no display
--

----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;        -- for addition & counting
use ieee.numeric_std.all;               -- for type conversions


entity lcd_controler is
generic (fclk: natural := 50_000_000); -- 50MHz , cristal do kit e03

port (
       clk          : in  std_logic; 
       rs, rw ,e    : out std_logic;  
       db           : out std_logic_vector(7 downto 0); 
       teclado      : in  std_logic_vector(7 downto 0);
       rst          : in  std_logic;
       time_str     : in  std_logic_vector (31 downto 0);
       decoder_flag : in  std_logic
);
end lcd_controler;

architecture lcd_controler_arq of lcd_controler is
    ---- estados da maquina de estados descritas como um novo tipo de variavel
    type state is (inicio, inicializa_lcd, escreve_senha, espera_pressionar, espera_soltar, escreve_char, clear_processando, escreve_processando, espera_tempo, trava,
                   clear_tempo,escreve_tempo_1,escreve_tempo_2,escreve_tempo_3,escreve_tempo_4,escreve_ms);
    ---- variaveis utilizaadas para as mudancas de estado
    signal pr_state, nx_state: state; 
    -- pr_state: estado atual
    -- nx_state: proximo estado

    ---- define um novo tipo de variavel sneod um vetor de std_logic_vector de 8 bits
    type arr is array (natural range <>) of std_logic_vector(7 downto 0); 
    
    constant str_ms : arr :=             (X"30",X"20",X"75",X"73"); -- array com os codigos em ascii
    constant str_senha : arr :=          (X"53",X"65",X"6e",X"68",X"61",X"3a",X"20"); -- array com os codigos em ascii para a palavra senha
    constant datas : arr :=              (X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"38",X"01",X"0c",X"06"); ---- array com os codigos em ascii para a inicializacao do display                                            
    constant str_processando : arr :=    (X"50",X"72",X"6f",X"63",X"65",X"73",X"73",X"61",X"6e",X"64",X"6f",X"2e",X"2e",X"2e"); -- array com os codigos em ascii para que escreve a frase "Processando..."
    signal action, action2, escreve : std_logic := '0';
    -- action: clock de 500Hz
    --

begin
        e <= action and escreve; -- quando o clock estiver em alto e o estado for de escrita (escreve = 1), enable eh ativado
        action2 <= not action;  -- action_2 eh o inverso do clock de 500Hz
---— Gerador de clock de 500 Hz ---------
        process (clk)
        variable count: natural range 0 to fclk/1000; 
        begin
            if (clk' event and clk = '1') then 
                count := count + 1;
                if (count = fclk/1000) then 
                 action <= not action; -- alterna action que sera utilizado como clock mais lento
                 count := 0; 
                end if; 
            end if; 
        end process;
        
--------------------
        process (action) 
        begin
            if (action' event and action = '1') then 
                if (rst = '1') then -- se o sistema for reiniciado, volta para o inicio
                    pr_state <= inicio;
                else -- se nao vai para o proximo estado
                    pr_state <= nx_state; 
                end if; 
            end if; 
        end process;
        
-----Maquina de estados---------------
        process (pr_state,action2) 
            variable j : integer := 1; -- contador utilizado para percorrer os array definidos e tambem na insercao da senha
        begin

            if action2'event and action2 = '1' then
            --- estado inicial, LCD ainda nao foi ligado
                if pr_state = inicio then
                    rs<= '0'; rw<= '0'; escreve <= '0';
                    db <= "00000000";
                    nx_state <= inicializa_lcd;
                    j := 0;
        
            --- inicializacao do LCD
                elsif pr_state = inicializa_lcd then 
                    rs<= '0'; rw<= '0'; escreve <= '1'; -- RS  '0' pois serao enviados comandos para o LCD
                    db <= datas(j)(7 downto 0);
                    if (j < 21) then                    -- enquanto ainda houverem codigos de inicializacao a serem executados, permanece no mesmo estado
                        j := j + 1;
                        nx_state <= inicializa_lcd;
                    else                                -- se nao, passa para o proximo estado e zera o contador
                        j := 0;
                        nx_state <= escreve_senha; 
                    end if;

            --- escreve a palavra senha
                 elsif pr_state = escreve_senha then 
                    rs<= '1'; rw<= '0'; escreve <= '1'; -- RS eh '1' pois eh uma operacao de escrita do LCD
                    db <= str_senha(j)(7 downto 0);
                    if (j < 6) then                     -- enquanto ainda houverem letras a serem escritas, continua no mesmo estado
                        j := j + 1;
                        nx_state <= escreve_senha;
                    else                                -- se nao vai para o proximo estado
                        j := 0;
                        nx_state <= espera_pressionar; 
                    end if;

            --- insercao da senha
                elsif pr_state = espera_pressionar then
                    rs<= '1'; rw<= '0'; escreve <= '0';
                    db <= "10101010";
                    if teclado = "11111010" and j = 4  then     -- se insercao de senha tiver finalizada e usuario apertar 'enter' vai para clear processndo
                        j := 0;
                        nx_state <= clear_processando;
                    elsif teclado = "11111111" or teclado = X"FA" or j = 4 then  -- se nenhum botao estiver pressionado ou ja tiver completado 4 digitos
                        nx_state <= espera_pressionar;
                    else                                -- se tecla pressionada, vai para proximo estado
                        nx_state <= escreve_char; 
                    end if;
                elsif pr_state = escreve_char then      -- escreve ascii correspondente a tecla pressionada no LCD
                    rs<= '1'; rw<= '0'; escreve <= '1';
                    db <= teclado;                    
                    nx_state  <= espera_soltar; 
                    j := j + 1;
                elsif pr_state = espera_soltar then    -- espera soltar tecla pressionada
                    rs<= '1'; rw<= '0'; escreve <= '0';
                    if teclado = "11111111" then           -- quando soltar, volta para estado espera_pressionar
                        nx_state <= espera_pressionar ;
                    else                                    -- se nao, continua no mesmoe estado
                        nx_state <= espera_soltar; 
                    end if;    

            --- escreve mensagem 'Processando...'
                elsif pr_state = clear_processando then 
                    rs<= '0'; rw<= '0'; escreve <= '1';
                    db <= X"01";                           --- limpa o display
                    nx_state <= escreve_processando;
                elsif pr_state = escreve_processando then 
                    rs<= '1'; rw<= '0'; escreve <= '1';
                    db <= str_processando(j)(7 downto 0);   
                    if (j < 13) then                        -- enquanto ainda houver caracteres a serem escritos, permanece no mesmo estado
                        j := j + 1;
                        nx_state <= escreve_processando;
                    else                                    -- se não, vai para espera_tempo
                        nx_state <= espera_tempo; 
                    end if;    

            --- espera tempo vindo do quebrador de hash
                elsif pr_state = espera_tempo then 
                    rs<= '0'; rw<= '0'; escreve <= '0';
                    db <= X"00";
                    j := 0;
                    if (decoder_flag = '1') then    -- se mensagem com o tempo chegar, vai para clear tempo
                        nx_state <= clear_tempo;
                    else                            -- se nao permanece no estado
                        nx_state <= espera_tempo;
                    end if;
                elsif pr_state = clear_tempo then       -- limpa LCD
                    rs<= '0'; rw<= '0'; escreve <= '1';
                    db <= X"01";
                    j := 0;
                    nx_state <= escreve_tempo_1;
                elsif pr_state = escreve_tempo_1 then  -- escreve primeiro caracter do tempo
                    rs<= '1'; rw<= '0'; escreve <= '1';
                    db <= time_str(31 downto 24);                    
                    nx_state  <= escreve_tempo_2; 

                elsif pr_state = escreve_tempo_2 then   -- escreve segundo caracter do tempo
                    rs<= '1'; rw<= '0'; escreve <= '1';
                    db <= time_str(23 downto 16);                    
                    nx_state  <= escreve_tempo_3; 

                elsif pr_state = escreve_tempo_3 then   -- escreve terceiro caracter do tempo
                    rs<= '1'; rw<= '0'; escreve <= '1';
                    db <= time_str(15 downto 8);                    
                    nx_state  <= escreve_tempo_4;  

                elsif pr_state = escreve_tempo_4 then   -- escreve quarto caracter do tempo
                    rs<= '1'; rw<= '0'; escreve <= '1';
                    db <= time_str(15 downto 8);                    
                    nx_state  <= escreve_ms;  
                
                elsif pr_state = escreve_ms then        -- escreve unidade de tempo
                    rs<= '1'; rw<= '0'; escreve <= '1';
                    db <= str_ms(j)(7 downto 0);
                    if (j < 3) then
                        j := j + 1;
                        nx_state <= escreve_ms;
                    else  
                        nx_state <= trava; 
                    end if;
            
            --- trava LCD
                elsif pr_state = trava then             -- permanece nesse estado ate o sistema ser resetado
                    rs<= '1'; rw<= '0'; escreve <= '0';
                    db <= "00000000";
                    nx_state <= trava;
                end if;
            end if; 
        end process;        
    end lcd_controler_arq;

    