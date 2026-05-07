library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_div is
    Port ( 
        clk_100MHz  : in  STD_LOGIC;  -- The main clock from the Nexys A7 board
        reset       : in  STD_LOGIC;  -- Asynchronous reset from a physical button
        clk_1kHz_en : out STD_LOGIC   -- A single 1-clock-cycle pulse every 1 millisecond
    );
end clk_div;

architecture Behavioral of clk_div is

    -- Math: 100,000,000 Hz / 1,000 Hz = 100,000 clock cycles per millisecond
    -- We count from 0 to 99,999, which is exactly 100,000 cycles.
    constant MAX_COUNT : integer := 99_999;
    
    -- We define a counter signal limited to our max count to save FPGA resources
    signal counter : integer range 0 to MAX_COUNT := 0;

begin

    process(clk_100MHz, reset)
    begin
        -- Asynchronous active-high reset
        if reset = '1' then
            counter <= 0;
            clk_1kHz_en <= '0';
            
        -- Synchronous logic happens on the rising edge of the 100MHz clock
        elsif rising_edge(clk_100MHz) then
            if counter = MAX_COUNT then
                counter <= 0;         -- Reset the counter when we hit 1ms
                clk_1kHz_en <= '1';   -- Send out our "tick" for exactly ONE clock cycle
            else
                counter <= counter + 1; -- Keep counting
                clk_1kHz_en <= '0';     -- Keep the tick low
            end if;
        end if;
    end process;

end Behavioral;