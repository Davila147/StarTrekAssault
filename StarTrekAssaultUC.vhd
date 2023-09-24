---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------UNIDADE DE CONTROLE-----------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.numeric_bit.all;

entity StarTrekAssaultUC is
    port (
        clock, reset: in bit;

        setShield, resetShield, enShield: out bit; --Sinais de controle da UC: controle do shieldReg
        setHealth, resetHealth, enHealth: out bit; --Sinais de controle da UC: controle do healtheReg
        resetTurn, enTurn               : out bit; --Sinais de controle da UC: controle do turnCounter
        regen                           : out bit_vector(7 downto 0);        --Sinal da UC: regeneração do shield
        
        dam32, shield128                : in bit; --Sinais de condição do fluxo de dados
        logicWL                         : in bit_vector(1 downto 0);

        WL                              : out bit_vector(1 downto 0)
    );
end entity;

architecture mef of StarTrekAssaultUC is

    type state_t is (idle_s, start_s, reg16_s, reg2_s, endGame_s);
    signal next_state, current_state: state_t;

begin

    mef: process(clock, reset)
    begin
        if(rising_edge(clock)) then
            if(reset = '1') then
                current_state <= idle_s;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;    

--Lógica de próximo estado--
    next_state <=  
        --Idle_s
        start_s when (current_state = idle_s) and (reset = '0') else 
        idle_s when (current_state = idle_s) and (reset = '1') else
        --Start_s
        start_s when (current_state = start_s) and (dam32 = '0') else 
        reg16_s when (current_state = start_s) and (dam32 = '1') else
        --reg16_s
        reg16_s when (current_state = reg16_s) and (shield128 = '0') and (logicWL = "00") else 
        reg2_s when (current_state = reg16_s) and (shield128 = '1') and (logicWL = "00") else
        endGame_s when (current_state = reg16_s) and (logicWL /= "00") else
        --reg2_s 
        reg2_s when (current_state = reg2_s) and (logicWL = "00") else
        endGame_s when (current_state = reg2_s) and (logicWL /= "00") else
        --endGame_s
        endGame_s when (current_state = endGame_s) and (reset = '0') else
        idle_s when (current_state = endGame_s) and (reset = '1');

    --Decodifiação dos estados para gerar os sinais de controle--
    setShield <= '1' when (current_state = start_s) else '0';
    setHealth <= '1' when (current_state = start_s) else '0';

    resetShield <= '1' when (current_state = idle_s) else '0';
    resetHealth <= '1' when (current_state = idle_s) else '0';
    resetTurn <= '1' when (current_state = idle_s) else '0';

    enShield <= '1' when (current_state = reg16_s) or (current_state = reg2_s) else '0';
    enHealth <= '1' when (current_state = reg16_s) or (current_state = reg2_s) else '0';
    enTurn <= '1' when (current_state = reg16_s) or (current_state = reg2_s) or (current_state = start_s) else '0';

    regen <= "00000010" when (current_state = reg2_s) or (current_state = endGame_s) else "00010000";

    --Ligação da saída WL--
    WL <= "00" when (current_state = idle_s) else 
          logicWL when (current_state = endGame_s);

end architecture;