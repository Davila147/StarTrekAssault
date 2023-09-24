---------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------PROJETO COMPLETO (INTERLIGAÇÃO)-------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------

entity StartTrekAssault is
    port (
    clock, reset: in bit; -- sinais de controle globais
    damage: in bit_vector(7 downto 0); -- Entrada de dados: dano
    shield: out bit_vector(7 downto 0); -- Saída: shield atual
    health: out bit_vector(7 downto 0); -- Saída: health atual
    turn: out bit_vector(4 downto 0); -- Saída: rodada atual
    WL: out bit_vector(1 downto 0) -- Saída: vitória e/ou derrota
    );
   end entity StartTrekAssault;
  
  architecture structural of StartTrekAssault is
    --FLUXO DE DADOS--
    component StarTrekAssaultFD is
        port(
          clock                             : in bit;                    --ENTRADAS DA ENTIDADE DO PROJETO
          damage                            : in bit_vector(7 downto 0); 
      
          setShield, resetShield, enShield  : in bit; --Sinais de controle da UC: controle do shieldReg
          setHealth, resetHealth, enHealth  : in bit; --Sinais de controle da UC: controle do healtheReg
          resetTurn, enTurn                 : in bit; --Sinais de controle da UC: controle do turnCounter
          regen                             : in bit_vector(7 downto 0); --Sinal de controle da UC: regeneração do shield
  
          dam32, shield128                  : out bit; --Sinais de condição do fluxo de dados
          logicWL                           : out bit_vector(1 downto 0);
      
          shield                            : out bit_vector(7 downto 0); --SAÍDAS DA ENTIDADE DO PROJETO
          health                            : out bit_vector(7 downto 0);
          turn                              : out bit_vector(4 downto 0)
        );
      end component;
  
    --UNIDADE DE CONTROLE--
    component StarTrekAssaultUC is
        port (
            clock, reset                     : in bit; --ENTRADAS DA ENTIDADE DO PROJETO
    
            setShield, resetShield, enShield : out bit; --Sinais de controle da UC: controle do shieldReg
            setHealth, resetHealth, enHealth : out bit; --Sinais de controle da UC: controle do healtheReg
            resetTurn, enTurn                : out bit; --Sinais de controle da UC: controle do turnCounter
            regen                            : out bit_vector(7 downto 0); --Sinal da UC: regeneração do shield
  
            dam32, shield128                 : in bit; --Sinais de condição do fluxo de dados
            logicWL                          : in bit_vector(1 downto 0);
    
            WL                               : out bit_vector(1 downto 0) --SAÍDA DA ENTIDADE DO PROJETO
        );
    end component;
  
    -----------SINIAIS INTERNOS--------------
    signal setShield, setHealth                : bit; --Sinais de controle (set)
    signal resetShield, resetHealth, resetTurn : bit; --Sinais de controle (reset)
    signal enShield, enHealth, enTurn          : bit; --Sinais de controle (enable)
    signal regen                               : bit_vector(7 downto 0);  --Sinal de controle (regeneração)
    signal dam32, shield128                    : bit; --Sinais de condição
    signal logicWL                             : bit_vector(1 downto 0); --Sinal de condição (lógica Win/Loose)
    signal clock_n                             : bit; -- Clock negado
    -----------------------------------------
  
  begin
    clock_n <= not(clock);
  
    fd: StarTrekAssaultFD
        port map(clock_n, damage,
                setShield, resetShield, enShield,
                setHealth, resetHealth, enHealth,
                resetTurn, enTurn, 
                regen,
                dam32, shield128, logicWl, 
                shield, health, turn);
    
    uc: StarTrekAssaultUC
        port map(clock, reset,
                setShield, resetShield, enShield,
                setHealth, resetHealth, enHealth,
                resetTurn, enTurn, 
                regen,
                dam32, shield128, logicWl,
                WL);
  
  end architecture structural;