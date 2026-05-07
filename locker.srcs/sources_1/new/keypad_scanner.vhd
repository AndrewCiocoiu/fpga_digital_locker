library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity keypad_scanner is
    Port ( 
        clk_100MHz  : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        clk_1kHz_en : in  STD_LOGIC;  -- The 1ms tick from clk_div
        Row         : in  STD_LOGIC_VECTOR (3 downto 0); -- Input from PMOD rows
        Col         : out STD_LOGIC_VECTOR (3 downto 0); -- Output to PMOD columns
        key_value   : out STD_LOGIC_VECTOR (3 downto 0); -- The Hex value of the pressed key (0-F)
        key_valid   : out STD_LOGIC                      -- A single pulse when a key is pressed
    );
end keypad_scanner;

architecture Behavioral of keypad_scanner is

    -- FSM States for scanning columns and waiting for the user to let go of the button
    type state_type is (SCAN_COL_1, SCAN_COL_2, SCAN_COL_3, SCAN_COL_4, WAIT_FOR_RELEASE);
    signal current_state : state_type := SCAN_COL_1;

begin

    process(clk_100MHz, reset)
    begin
        if reset = '1' then
            current_state <= SCAN_COL_1;
            Col <= "0000";
            key_value <= "0000";
            key_valid <= '0';
            
        elsif rising_edge(clk_100MHz) then
            
            -- Default: valid pulse is 0 unless we explicitly find a key press this cycle
            key_valid <= '0';
            
            -- We only transition states and check the keypad once every millisecond
            if clk_1kHz_en = '1' then
                
                case current_state is
                
                    -- ==========================================
                    -- SCAN COLUMN 1 (Keys: 1, 4, 7, 0)
                    -- ==========================================
                    when SCAN_COL_1 =>
                        Col <= "1000"; -- Turn on Column 1
                        
                        if Row = "1000" then key_value <= x"1"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0100" then key_value <= x"4"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0010" then key_value <= x"7"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0001" then key_value <= x"0"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        else
                            current_state <= SCAN_COL_2; -- Nothing pressed, move to next column
                        end if;

                    -- ==========================================
                    -- SCAN COLUMN 2 (Keys: 2, 5, 8, F)
                    -- ==========================================
                    when SCAN_COL_2 =>
                        Col <= "0100"; -- Turn on Column 2
                        
                        if Row = "1000" then key_value <= x"2"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0100" then key_value <= x"5"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0010" then key_value <= x"8"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0001" then key_value <= x"F"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        else
                            current_state <= SCAN_COL_3;
                        end if;

                    -- ==========================================
                    -- SCAN COLUMN 3 (Keys: 3, 6, 9, E)
                    -- ==========================================
                    when SCAN_COL_3 =>
                        Col <= "0010"; -- Turn on Column 3
                        
                        if Row = "1000" then key_value <= x"3"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0100" then key_value <= x"6"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0010" then key_value <= x"9"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0001" then key_value <= x"E"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        else
                            current_state <= SCAN_COL_4;
                        end if;

                    -- ==========================================
                    -- SCAN COLUMN 4 (Keys: A, B, C, D)
                    -- ==========================================
                    when SCAN_COL_4 =>
                        Col <= "0001"; -- Turn on Column 4
                        
                        if Row = "1000" then key_value <= x"A"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0100" then key_value <= x"B"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0010" then key_value <= x"C"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        elsif Row = "0001" then key_value <= x"D"; key_valid <= '1'; current_state <= WAIT_FOR_RELEASE;
                        else
                            current_state <= SCAN_COL_1; -- Loop back to beginning
                        end if;

                    -- ==========================================
                    -- WAIT FOR RELEASE STATE
                    -- ==========================================
                    when WAIT_FOR_RELEASE =>
                        -- Turn ALL columns on so we can easily see if ANY button is still held down
                        Col <= "1111"; 
                        
                        -- If the row is "0000", it means all buttons have been let go
                        if Row = "0000" then
                            current_state <= SCAN_COL_1; -- Go back to scanning
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;