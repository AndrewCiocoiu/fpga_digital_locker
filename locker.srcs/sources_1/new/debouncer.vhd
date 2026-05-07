library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debouncer is
    Port ( 
        clk_100MHz  : in  STD_LOGIC;  -- Main system clock
        reset       : in  STD_LOGIC;  -- Asynchronous reset
        btn_in      : in  STD_LOGIC;  -- The raw, bouncy signal from the physical button
        clk_1kHz_en : in  STD_LOGIC;  -- The slow 1ms tick from our clk_div module
        btn_pulse   : out STD_LOGIC   -- A clean, single 1-clock-cycle pulse when pressed
    );
end debouncer;

architecture Behavioral of debouncer is

    -- A shift register to record the history of the button state
    signal shift_reg : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    
    -- Internal signals to track the stable state and detect the edge
    signal stable_btn       : STD_LOGIC := '0';
    signal stable_btn_delay : STD_LOGIC := '0';

begin

    process(clk_100MHz, reset)
    begin
        if reset = '1' then
            shift_reg <= (others => '0');
            stable_btn <= '0';
            stable_btn_delay <= '0';
            btn_pulse <= '0';
            
        elsif rising_edge(clk_100MHz) then
            
            -- STEP 1: DEBOUNCING (Runs only every 1ms)
            if clk_1kHz_en = '1' then
                -- Shift all bits to the left and pull the current button state into the right-most bit
                shift_reg <= shift_reg(8 downto 0) & btn_in;
                
                -- If the last 10 readings (10 milliseconds) are all '1', the button is solidly pressed
                if shift_reg = "1111111111" then
                    stable_btn <= '1';
                -- If the last 10 readings are all '0', the button is solidly released
                elsif shift_reg = "0000000000" then
                    stable_btn <= '0';
                end if;
            end if;
            
            -- STEP 2: EDGE DETECTION (Runs at 100MHz to generate exactly a 1-cycle pulse)
            stable_btn_delay <= stable_btn; -- Save the state from the previous clock cycle
            
            -- If it is high NOW, but was low ONE CYCLE AGO, it means the button was JUST pressed
            if stable_btn = '1' and stable_btn_delay = '0' then
                btn_pulse <= '1';
            else
                btn_pulse <= '0';
            end if;
            
        end if;
    end process;

end Behavioral;