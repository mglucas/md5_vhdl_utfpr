----------------------------------------------------------------------------------
-- Universidade Tecnologica Federal do Parana
-- Disciplina  Logica Reconfiguravel
-- 05/2021
-- Integrantes
-- Alexandre Matias
--    Enrico Manfron
-- Giuliana Martins
-- Lucas Ricardo
-- Victor Feitosa

-- Descricao
-- Este codigo trata da implementacao de um top level que junta todas as partes do projeto
-- tambem corrigindo alguns problemas de cincronismo entre as partes
-- 
--

----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;        -- for addition & counting
use ieee.numeric_std.all;               -- for type conversions

entity esmaga_senha is
    port (
        rs, rw ,e : out std_logic;                          -- controlam diretamente os pinos rs,rw,e do LCD
        db        : out std_logic_vector (7 downto 0);      -- responsaveis por mandar dados para o LCD
        lin       : in  std_logic_vector (3 downto 0);      -- ligam nas linhas do teclado matricial
        col       : out std_logic_vector (3 downto 0);      -- ligam nas colunas do teclado matricial
        clk , rst : in  std_logic                           -- recebem os sinais de clock e de reset geral do sistema
    ) ;
end esmaga_senha;

architecture esmaga_senha_arc of esmaga_senha is
    component teclado is                                            -- Componente que utiliza driver do teclado
        port (
            lin         : in  std_logic_vector (3 downto 0);        -- responsavel por ler linhas ativas no teclado matricial
            col         : out std_logic_vector (3 downto 0);    	-- responsavel por energizar pinos das colulas no teclado matricial 
            num         : out std_logic_vector (7 downto 0); 		-- fornece qual tecla esta sendo pressionada no momento
            md5_str     : out std_logic_vector (31 downto 0);       -- depois de 4 digitos, fornece a string que sera processada pelo lcd
            md5_trigger : out std_logic;							-- fornece sinal responsavel por fazer o md5 controler iniciar o calculo da funcao
            clk , rst   : in  std_logic 							-- pinos de clock e reset do sistema
        );
    end component teclado;
    component lcd_controler is
        port (
            clk          : in  std_logic; 							-- clock geral do sistema
            rs, rw ,e    : out std_logic;  							-- responsaveis por controlar diretamente os pinos rs,rw,e do LCD 
            db           : out std_logic_vector(7 downto 0); 		-- responsaveis por controlar os pinos de dados do LCD, serve para enviar comandos ou dados
            teclado      : in  std_logic_vector(7 downto 0);		-- recebe qual tecla esta sendo pressionada no teclado matricial 
            rst          : in  std_logic;							-- rst geral do sistema
            time_str     : in  std_logic_vector (31 downto 0); 		-- recebe quanto tempo o decodificador demorou para quebrar o hash
            decoder_flag : in  std_logic  							-- flag responsavel por avisar o lcd controler quando o decodificador conseguiu quebrar a hash proposta
        );
    end component lcd_controler;

    component MD5_controler is
        port (  
            clk        : in  STD_LOGIC; 										-- clock geral
            reset      : in  STD_LOGIC;											-- reset geral 
            entrada    : in  STD_LOGIC_VECTOR (31 downto 0);					-- entradra do md5 que recebe uma senha em ASCII para codigicar seu hash
            iniciar    : in  STD_LOGIC;											-- flag responsavel por iniciar o calculo da funcao
            saida      : out STD_LOGIC_VECTOR (63 downto 0) := (others => '0'); -- saida do hash calculado da senha correspondente 
            finalizado : out STD_LOGIC := '0'									-- flag responsavel por iniciar a decodificacao uma vez que se tenha o hash calculado
        );
    end component MD5_controler;

    component decoder is  
    port (
            clk         :  in  std_logic;							-- clock geral do sistema
            iniciar     :  in  std_logic;							-- flag responsavel por inicar o algoritmo de força bruta
            rst         :  in  std_logic;							-- reset geral do sistema
            data_in     :  in  std_logic_vector(63 downto 0);		-- responsaveis por receber o hash a ser quebrado
            saida_igual :  out std_logic;							-- flag responsavel por sinalizar quando o hash foi quebrado
            saida_tempo :  out std_logic_vector(31 downto 0)		-- apresenta quanto tempo foi necessario para quebrar a hash apresentada
    );
    end component decoder;

    signal md5_trigger_sig_1, md5_trigger_sig_2, decoder_trigger_sig, decoder_fim_sig, reset_sig, sensor_enter_sig, reset_dois, out_dec, rst_pulso: std_logic;
    signal num_sig : std_logic_vector (7 downto 0);
    signal md5_str_sig : std_logic_vector (31 downto 0); 
    signal time_str_sig  : std_logic_vector (31 downto 0);
    signal hash_str_sig : std_logic_vector (63 downto 0);
begin
    process (clk) 
    variable count_en, count_start, count_rst: natural range 0 to 10 := 0; 
    begin
        if (rising_edge(clk)) then 
            if reset_dois = '1' then -- quando reset é acionado, os contadores responsaveis por gerar um pulso são resetados
                count_en := 0;
                count_start := 0;
                count_rst := 0;
            end if;
            
            if decoder_trigger_sig = '1' then -- quando o md5 termina de calcular a hash, eh necessario fazer uma correcao na 
                count_en := 1;				  -- sincronizacao do resultado da hash e o sinal que diz quando esse finalizou os calculos
            end if;							  -- assim esse contador inicia um pulso de demora 3 ciclos de clock para ser acionado

            if count_en /= 0 and count_en <= 3  then -- pulso necessario para inicar o trabalho do decodificador
                if count_en = 3 then 				 -- esse contador espera 3 ciclos de clock para acionar o pulso que ira durar um clock
                    out_dec <= '1';
                end if;
                count_en := count_en + 1;
            else
               out_dec <= '0';
            end if; 

            if md5_trigger_sig_1 = '1' and count_start = 0 then -- quando o enter eh pressionado do teclado e esse tem 4 digitos 
                md5_trigger_sig_2 <= '1';						-- ele aciona uma flag para o md5 funcionar, porem essa flag precisou ser
                count_start := 1;								-- traduzida em forma de pulso, portanto quando é identificado esse sinal
            end if;												-- um pulso que dura 4 ciclos de clock eh acionado

            if count_start /= 0 and count_start <= 4 then		-- responsavel por deslilar o pulso depois de 4 ciclos de clock
                count_start := count_start + 1;
            else
                md5_trigger_sig_2 <= '0';
            end if;
                
            if decoder_fim_sig = '1' and count_rst = 0 then -- aqui o reser tambem precisou ser tranformado em um 
                count_rst := 1;								-- pois a flag do decodificador que avisa quando esse conseguiu quebrar a hash fica ligado até esse ser reiniciado
                rst_pulso <= '1';							-- portanto como o reset depende dessa flag esse foi traduzido em forma de pulso para nao afetar os componentes
            end if;

            if count_rst /= 0 and count_rst <= 4 then -- responsavel por desligar o reser apos 4 pulsos
                count_rst := count_rst + 1;
            else
                rst_pulso <= '0';
            end if;
        end if; 
    end process;


    reset_sig <= rst_pulso or rst;    
    reset_dois <= (sensor_enter_sig and decoder_fim_sig) or rst;
    sensor_enter_sig <= '1' when num_sig = X"FA" else
                        '0';
    
    tec : teclado port map (
        lin => lin,
        col => col,
        num => num_sig,
        clk => clk,
        rst => reset_sig,
        md5_trigger => md5_trigger_sig_1,
        md5_str => md5_str_sig
    );
    lcd_c: lcd_controler port map (
        clk     => clk, 
        rs      => rs,
        rw      => rw,
        e       => e,  
        db      => db, 
        teclado => num_sig,
        rst     => reset_dois,
        time_str => time_str_sig,
        decoder_flag => decoder_fim_sig
    );
    md5_c: MD5_controler port map (
        clk        => clk,
        reset      => reset_dois,
        entrada    => md5_str_sig,
        iniciar    => md5_trigger_sig_2,
        saida      => hash_str_sig,
        finalizado => decoder_trigger_sig
    );
    dec_c: decoder port map (
        clk         => clk,
        iniciar     => out_dec,
        rst         => reset_dois,
        data_in     => hash_str_sig,
        saida_tempo => time_str_sig,
        saida_igual => decoder_fim_sig
    );
end  esmaga_senha_arc;