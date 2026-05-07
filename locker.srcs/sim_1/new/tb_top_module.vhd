library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbenches NEVER have ports!
entity tb_top_module is
end tb_top_module;

architecture Behavioral of tb_top_module is

    -- 1. DECLARE THE UUT (Unit Under Test)
    component top_module
        Port ( 
            clk_100MHz  : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            btn_scroll  : in  STD_LOGIC;
            btn_ok      : in  STD_LOGIC;
            PMOD_Row    : in  STD_LOGIC_VECTOR (3 downto 0);
            PMOD_Col    : out STD_LOGIC_VECTOR (3 downto 0);
            LED_Users   : out STD_LOGIC_VECTOR (4 downto 0);
            LED_Access  : out STD_LOGIC;
            LED_Alarm   : out STD_LOGIC;
            seg         : out STD_LOGIC_VECTOR (6 downto 0);
            an          : out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    -- 2. CREATE FAKE WIRES TO CONNECT TO THE UUT
    signal clk        : STD_LOGIC := '0';
    signal rst        : STD_LOGIC := '0';
    signal scroll     : STD_LOGIC := '0';
    signal ok         : STD_LOGIC := '0';
    signal pmod_r     : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    
    signal pmod_c     : STD_LOGIC_VECTOR(3 downto 0);
    signal leds_u     : STD_LOGIC_VECTOR(4 downto 0);
    signal led_acc    : STD_LOGIC;
    signal led_alrm   : STD_LOGIC;
    signal seg_out    : STD_LOGIC_VECTOR(6 downto 0);
    signal an_out     : STD_LOGIC_VECTOR(7 downto 0);

    -- 100MHz clock period
    constant clk_period : time := 10 ns;

begin

    -- 3. PLUG THE FAKE WIRES INTO THE UUT
    UUT: top_module port map (
        clk_100MHz => clk,
        reset      => rst,
        btn_scroll => scroll,
        btn_ok     => ok,
        PMOD_Row   => pmod_r,
        PMOD_Col   => pmod_c,
        LED_Users  => leds_u,
        LED_Access => led_acc,
        LED_Alarm  => led_alrm,
        seg        => seg_out,
        an         => an_out
    );

    -- 4. TURN ON THE FAKE CLOCK
    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- 5. WRITE THE SCRIPT TO PRESS THE BUTTONS
    stim_proc: process
    begin
        -- Hold Reset for 100ns to initialize the system
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        -- The FSM is now in IDLE state. User 1 LED should be ON.
        
        -- Let's press the SCROLL button to move to User 2.
        -- We MUST hold it for at least 10ms to pass the debouncer!
        scroll <= '1';
        wait for 15 ms; 
        scroll <= '0';
        
        -- Wait a bit before pressing the next button
        wait for 5 ms;

        -- Let's press the OK button. 
        -- Since User 2 PIN is 0000, this should move the FSM to SETUP_STEP1.
        ok <= '1';
        wait for 15 ms;
        ok <= '0';

        -- Wait a bit to observe the final state on the waveform
        wait for 5 ms;

        -- End the simulation (Wait forever)
        wait;
    end process;

end Behavioral;