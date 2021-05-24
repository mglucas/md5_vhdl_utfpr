----------------------------------------------------------------------------------
-- Universidade Tecnologica Federal do Parana
-- Disciplina  Logica Reconfiguravel
-- 05/2021
-- Integrantes
-- Alexandre Matias
-- Enrico Manfron
-- Giuliana Martins
-- Lucas Ricardo
-- Victor Feitosa Lourenco

-- Descricao
-- Este codigo trata da implementacao modificada do algoritmo MD5. 
-- Como principal mudanca, ressalta-se a diferenca entre a hash 64 bits
-- em relacao a 128

-- Execucao deste codigo e baseada no:
-- https://en.wikipedia.org/wiki/MD5_controler
-- https://github.com/frysztak/md5_controler

----------------------------------------------------------------------------------
-- Bibliotecas
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Entidade do MD5
--   Entradas
--     clk, reset: funcionamento padrao
--     entrada: 32 bits de mensagem (8 bits para cada caracter ASCII)
--     iniciar: apenas um bit que indica se o sistema deve comecar/continuar calculando
--   Saidas
--     saida: a hash de 64 bits
--     finalizado: oposto ao "inicar", indica que os calculos de hash foram finalizados
--     
entity MD5_controler is
    Port ( clk:         in  STD_LOGIC;
           reset:       in  STD_LOGIC;
           entrada:     in  STD_LOGIC_VECTOR (31 downto 0);
           iniciar:     in  STD_LOGIC;
           saida:       out STD_LOGIC_VECTOR (63 downto 0) := (others => '0');
           finalizado:  out STD_LOGIC := '0');
end MD5_controler;

architecture Behavioral of MD5_controler is
subtype uint32_t is unsigned(31 downto 0);

-- Esses "type"s de constantes sao apenas para auxiliar na cricao das constantes do MD5
type const_s is array (63 downto 0) of unsigned(7 downto 0);
type const_k is array (63 downto 0) of uint32_t;

-- Constantes definidas para o MD5_controler
-- S: Quantidades de shift no leftrotate, para cada rodada de calculo
constant S: const_s := (X"07", X"0C", X"11", X"16", -- 7, 12, 17, 22,
                        X"07", X"0C", X"11", X"16", 
                        X"07", X"0C", X"11", X"16", 
                        X"07", X"0C", X"11", X"16",

                        X"05", X"09", X"0E", X"14", -- 5,  9, 14, 20,
                        X"05", X"09", X"0E", X"14", 
                        X"05", X"09", X"0E", X"14", 
                        X"05", X"09", X"0E", X"14", 

                        X"04", X"0B", X"10", X"17", -- 4, 11, 16, 23,
                        X"04", X"0B", X"10", X"17", 
                        X"04", X"0B", X"10", X"17", 
                        X"04", X"0B", X"10", X"17", 

                        X"06", X"0A", X"0F", X"15", -- 6, 10, 15, 21);
                        X"06", X"0A", X"0F", X"15",
                        X"06", X"0A", X"0F", X"15", 
                        X"06", X"0A", X"0F", X"15"); 

-- K: Valores pre-calculados para a funcao seno
constant K: const_k := (X"d76aa478", X"e8c7b756", X"242070db", X"c1bdceee",
                        X"f57c0faf", X"4787c62a", X"a8304613", X"fd469501",
                        X"698098d8", X"8b44f7af", X"ffff5bb1", X"895cd7be",
                        X"6b901122", X"fd987193", X"a679438e", X"49b40821",
                        X"f61e2562", X"c040b340", X"265e5a51", X"e9b6c7aa",
                        X"d62f105d", X"02441453", X"d8a1e681", X"e7d3fbc8",
                        X"21e1cde6", X"c33707d6", X"f4d50d87", X"455a14ed",
                        X"a9e3e905", X"fcefa3f8", X"676f02d9", X"8d2a4c8a",
                        X"fffa3942", X"8771f681", X"6d9d6122", X"fde5380c",
                        X"a4beea44", X"4bdecfa9", X"f6bb4b60", X"bebfbc70",
                        X"289b7ec6", X"eaa127fa", X"d4ef3085", X"04881d05",
                        X"d9d4d039", X"e6db99e5", X"1fa27cf8", X"c4ac5665",
                        X"f4292244", X"432aff97", X"ab9423a7", X"fc93a039",
                        X"655b59c3", X"8f0ccc92", X"ffeff47d", X"85845dd1",
                        X"6fa87e4f", X"fe2ce6e0", X"a3014314", X"4e0811a1",
                        X"f7537e82", X"bd3af235", X"2ad7d2bb", X"eb86d391");


-- Sinais usados nos calculos do MD5                        
signal M : unsigned(511 downto 0) := (others => '0');
signal contador, contador_n : natural := 0;

-- Constantes iniciais para o inicio e reset dos calculos
constant a0 : uint32_t := X"67452301";
constant b0 : uint32_t := X"efcdab89";
constant c0 : uint32_t := X"98badcfe";
constant d0 : uint32_t := X"10325476";

-- Quatro quartos do MD5, sao alterados em cada rodada
-- Sinais com _n sao usadas como variavel auxiliar 
-- para atualizacao de valores em estados na maquina de estados
signal A, A_n : uint32_t := a0;
signal B, B_n : uint32_t := b0;
signal C, C_n : uint32_t := c0;
signal D, D_n : uint32_t := d0;
signal F      : uint32_t := to_unsigned(0, A'length);
signal g      : integer := 0;

-- Estados da Maquina de estados
type lista_estados is (espera,
                      carregar_dados,
                 calculo_0_15, 
                 calculo_16_31,
                 calculo_32_47, 
                 calculo_48_63,
                      atribuicao,
                 agregador, 
                 encerrado,
                 retornar);
signal estado, estado_n : lista_estados;


function leftrotate(x: in uint32_t := X"00000000"; c: in unsigned(7 downto 0)) return uint32_t is
begin
    return SHIFT_LEFT(x, to_integer(c)) or SHIFT_RIGHT(x, to_integer(32-c));
end function leftrotate;

-- O funcionamento do calculo do MD5 eh feito a partir de 3 processos distintos
begin
    -- Processo Main: este processo apenas garante que a cada novo ciclo, o estado e as quatro
	--                secoes do MD5 sao devidamente atualizados, alem de lidar com valores de reset
    main: process(reset, clk)
    begin
        if (reset = '1') then
            estado <= espera;
                contador <= 0;
                A <= a0;
            B <= b0;
            C <= c0;
            D <= d0;
        elsif (rising_edge(clk)) then
            estado <= estado_n;
            contador <= contador_n;
            A <= A_n;
            B <= B_n;
            C <= C_n;
            D <= D_n;
        end if;
    end process main;

    -- Processo FSM: este processo eh responsavel por realizar mudancas exclusivas da maquina
	--               de estados, trocando para os estados adequados quando necessario
    fsm: process(estado, iniciar, contador)
    begin
        estado_n <= estado;

        case estado is
            when espera =>
                if (iniciar = '1') then
                    estado_n <= carregar_dados;
                end if;
                     
            when carregar_dados => 
                    estado_n <= calculo_0_15;

            when calculo_0_15 =>
                estado_n <= atribuicao;

            when calculo_16_31 =>
                estado_n <= atribuicao;

            when calculo_32_47 =>
                estado_n <= atribuicao;

            when calculo_48_63 =>
                estado_n <= atribuicao;
                     
                when atribuicao =>
                     if (contador >= 0 and contador < 15) then
                    estado_n <= calculo_0_15;
                elsif (contador >= 15 and contador < 31) then
                    estado_n <= calculo_16_31;
                elsif (contador >= 31 and contador < 47) then
                    estado_n <= calculo_32_47;
                elsif (contador >= 47 and contador < 63) then
                    estado_n <= calculo_48_63;
                elsif (contador = 63) then
                    estado_n <= agregador;
                end if;
                     
            when agregador =>
                estado_n <= encerrado;

            when encerrado =>
                estado_n <= retornar;

            when retornar =>
                estado_n <= espera;

            when others => null;
        end case;
    end process fsm;

    -- Processo process: eh aqui que todos os calculos serao realizados,
	--                   levando em consideracao o estado atual
    calc: process(reset, clk, estado, contador)
    begin
        if (rising_edge(clk) and reset = '0') then 
            case estado is
                when carregar_dados =>
                    M(31 downto 0) <= unsigned(entrada);
                    M(32) <= '1';
                    M(447 downto 33) <= (others => '0');
                    M(511 downto 448) <= "0000010000000000000000000000000000000000000000000000000000000000";

                when atribuicao =>
                    A_n <= D; 
                    B_n <= B + leftrotate(A + F + K(contador) + M(g+31 downto g), s(contador));
                    C_n <= B;
                    D_n <= C;
                    contador_n <= contador + 1;

                when calculo_0_15 =>
                    F <= (B_n and C_n) or (not B_n and D_n);
                    g <= 32*contador_n;

                when calculo_16_31 =>
                    F <= (D_n and B_n) or (not D_n and C_n);
                    g <= 32*((5*contador_n + 1) mod 16);

                when calculo_32_47 =>
                    F <= B_n xor C_n xor D_n;
                    g <= 32*((3*contador_n + 5) mod 16);

                when calculo_48_63 =>
                    F <= C_n xor (B_n or not D_n);
                    g <= 32*((7*contador_n) mod 16);

                when agregador =>
                    A_n <= A_n + a0;
                    B_n <= B_n + b0;
                    C_n <= C_n + c0;
                    D_n <= D_n + d0;

                when encerrado =>
                    finalizado <= '1';

                when retornar =>
                          saida(63 downto 32) <= std_logic_vector(A and B);
                          saida(31 downto 0)  <= std_logic_vector(C and D);
                    finalizado <= '0';
                          contador_n <= 0;

                when others => null;
            end case;
        
		  -- Garantindo que os valores de calculo voltam ao valor base ao resetar o sistema
          elsif (rising_edge(clk) and reset = '1') then
                 A_n <= a0;
                 B_n <= b0;
                 C_n <= c0;
                 D_n <= d0;
                 F   <= to_unsigned(0, A'length);
                 g   <= 0;
                 contador_n <= 0;
                 M <= (511 downto 0 => '0');
             saida <= (63 downto 0 => '0');
                 
          
          end if;
    end process calc;

end Behavioral;