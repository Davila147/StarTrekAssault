------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------ FLUXO DE DADOS ---------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

-- Registrador de 8 bits capaz de somar seu conteúdo à entrada. Satura-se em 0-255
entity adderSaturated8 is
  port (
    clock, set, reset: in bit;					-- Controle global: clock, set e reset (síncrono)
	 enableAdd: 	  in bit;						-- Se 1, conteúdo do registrador é somado a parallel_add (síncrono)
    parallel_add: in  bit_vector(8 downto 0);   -- Entrada a ser somada (inteiro COM sinal): -256 a +255
    parallel_out: out bit_vector(7 downto 0)	-- Conteúdo do registrador: 8 bits, representando 0 a 255
  );
end entity;

architecture arch of adderSaturated8 is
  signal internal: signed(9 downto 0); -- 10 bits com sinal: captura valores entre -512 e 511 na soma
  signal extIn: signed(9 downto 0); -- entrada convertida para 10 bits
  signal preOut: bit_vector(9 downto 0);  -- pré-saida: internal convertido para bit_vector
begin
  extIn <= signed(parallel_add(8) & parallel_add); -- extensão de sinal
  
  process(clock, reset)
  begin
    if (rising_edge(clock)) then
      if set = '1' then						  -- set síncrono
         internal <= (9|8 => '0', others=>'1'); -- Carrega 255 no registrador
	  elsif reset = '1' then				 -- reset síncrono
		 internal <= (others=>'0'); 		 -- Carrega 0s no registrador
	  elsif enableAdd = '1' then			 -- add síncrono
         -- Resultado fica na faixa entre -256 (se parallel_add = -256 e internal = 0) 
         -- e 510 (se parallel_add = 255 e internal = 255)
         if    (internal + extIn < 0)   then internal <= "0000000000"; -- negativo: satura em 0
         elsif (internal + extIn > 255) then internal <= "0011111111"; -- positivo 255+: satura em 255
         else                                internal <= internal + extIn; -- entre 0 e 255
         end if; 
      end if;
    end if;
  end process;
  
  preOut <= bit_vector(internal);
  parallel_out <= preOut(7 downto 0);
end architecture;

--------------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;
-- Contador de 0 a 16. Quando atinge 16, mantém a contagem em 16--
entity counter0to16 is
  port (
      clock   : in bit;                     -- Sinal de clock
      reset   : in bit;                     -- Sinal de reset
      enable  : in bit;
      count   : out bit_vector(4 downto 0);
      rco     : out bit
  );
end entity counter0to16;

architecture arch of counter0to16 is
  signal counter : unsigned(4 downto 0);  -- Sinal interno para o contador
  signal rcoAux  : bit;
begin
  process(clock, reset)
  begin
      if reset = '1' then
          counter <= (others => '0');  -- Reinicia o contador para 0 quando o sinal de reset está ativo
      elsif (rising_edge(Clock) and enable = '1') then
          if counter = 16 then
            counter <= counter;
            rcoAux <= '1';   
          else
            counter <= counter + 1;    -- Incrementa o contador
            rcoAux <= '0';
          end if;
      end if;
  end process;

  Count <= bit_vector(counter);  -- Converte o sinal unsigned para std_logic_vector
  rco <= rcoAux; --sinal que vale 1 quando o contador atinge 16
end architecture arch;

-----------------------------------FLUXO DE DADOS----------------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity StarTrekAssaultFD is
  port(
    clock                             :  in bit;                     --Entradas da entidade do projeto
    damage                            : in bit_vector(7 downto 0); 

    setShield, resetShield, enShield  : in bit; --Sinais de controle da UC: controle do shieldReg
    setHealth, resetHealth, enHealth  : in bit; --Sinais de controle da UC: controle do healtheReg
    resetTurn, enTurn                 : in bit;               --Sinais de controle da UC: controle do turnCounter
    regen                             : in bit_vector(7 downto 0);        --Sinal da UC: regeneração do shield
    dam32, shield128                  : out bit;
    logicWL                           : out bit_vector(1 downto 0);

    shield                            : out bit_vector(7 downto 0); --Saídas do entidade do projeto
    health                            : out bit_vector(7 downto 0);
    turn                              : out bit_vector(4 downto 0)
  );
end entity;

architecture dataflow of StarTrekAssaultFD is

----------COMPONENTES----------------------

component adderSaturated8 is
  port (
    clock, set, reset: in bit;					-- Controle global: clock, set e reset (síncrono)
	  enableAdd: 	  in bit;						-- Se 1, conteúdo do registrador é somado a parallel_add (síncrono)
    parallel_add: in  bit_vector(8 downto 0);   -- Entrada a ser somada (inteiro COM sinal): -256 a +255
    parallel_out: out bit_vector(7 downto 0)	-- Conteúdo do registrador: 8 bits, representando 0 a 255
  );
end component;


component counter0to16 is
  port (
      clock   : in bit;                    
      reset   : in bit;  
      enable  : in bit;                     
      count   : out bit_vector(4 downto 0);
      rco     : out bit
  );
end component;

---------- Sinais internos ----------
signal shieldInt: bit_vector(7 downto 0);
signal healthInt: bit_vector(7 downto 0);
signal healthDec: bit_vector(8 downto 0);
signal regenMinDamage: bit_vector(8 downto 0);
signal turn16: bit;

signal aux: signed(8 downto 0);
signal extShield: signed(8 downto 0);
signal extRegen: signed(8 downto 0);
signal extDamage: signed(8 downto 0);
-------------------------------------

begin
  -- LIGANDO OS COMPONENTES --

  shieldReg: adderSaturated8      
    port map(clock, setShield, resetShield, 
            enShield,
            regenMinDamage,
            shieldInt);

  healthReg: adderSaturated8
    port map(clock, setHealth, resetHealth,
            enHealth,
            healthDec,
            healthInt);
  
  turnCounter: counter0to16
    port map(clock, resetTurn, enTurn, turn, turn16);

  
  -- Operações com as entradas--
  extShield <= signed('0' & shieldInt); --Extensões de sinal
  extRegen <= signed('0' & regen);
  extDamage <= signed('0' & damage);

  regenMinDamage <= bit_vector(extRegen - extDamage); --(regen - dano)

  aux <= extShield + extRegen - extDamage;

  healthDec <= bit_vector(aux) when (aux < 0) else "000000000";

  --LIGANDO AS SAÍDAS SHIELD E HEALTH--
  health <= healthInt;
  shield <= shieldInt;

  --SINAIS DE CONDIÇÃO PARA A UC--
  dam32 <= '1' when (unsigned(damage) >= "00100000") else '0';
  shield128 <= '1' when(unsigned(shieldInt) < "10000000") else '0';

  --VERIFICAÇÕES DE VITÓRIA E/OU DERROTA--
  logicWL <= "11" when (turn16 = '1' and healthInt = "00000000") else 
        "10" when (turn16 = '0' and healthInt = "00000000") else 
        "01" when (turn16 = '1' and healthInt > "00000000") else 
        "00" when (turn16 = '0' and healthInt > "00000000");

end architecture dataflow;
