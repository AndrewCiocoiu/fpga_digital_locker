library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity keypad_scanner is
    Port ( 
        clk_100MHz  : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        clk_1kHz_en : in  STD_LOGIC;  
        Row         : in  STD_LOGIC_VECTOR (3 downto 0); 
        Col         : out STD_LOGIC_VECTOR (3 downto 0); 
        key_value   : out STD_LOGIC_VECTOR (3 downto 0); 
        key_valid   : out STD_LOGIC                      
    );
end keypad_scanner;

architecture Behavioral of keypad_scanner is

    type state_type is (SCAN_COL_1, SCAN_COL_2, SCAN_COL_3, SCAN_COL_4, DEBOUNCE_PRESS, WAIT_RELEASE, DEBOUNCE_RELEASE);
    signal current_state : state_type := SCAN_COL_1;

    signal temp_key_val  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal delay_count   : integer range 0 to 30 := 0; 

begin

    process(clk_100MHz, reset)
    begin
        if reset = '1' then
            current_state <= SCAN_COL_1;
            Col <= "1111"; 
            key_value <= "0000";
            key_valid <= '0';
            delay_count <= 0;
            
        elsif rising_edge(clk_100MHz) then
            
            key_valid <= '0';
            
            if clk_1kHz_en = '1' then
                
                case current_state is
                
                    -- ==========================================
                    -- SCAN COLUMN 1 (Physically mapped to Col 4: A, B, C, D)
                    -- ==========================================
                    when SCAN_COL_1 =>
                        Col <= "1110"; 
                        if Row = "1110" then temp_key_val <= x"A"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1101" then temp_key_val <= x"B"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1011" then temp_key_val <= x"C"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "0111" then temp_key_val <= x"D"; current_state <= DEBOUNCE_PRESS;
                        else current_state <= SCAN_COL_2; end if;

                    -- ==========================================
                    -- SCAN COLUMN 2 (Physically mapped to Col 1: 1, 4, 7, 0)
                    -- ==========================================
                    when SCAN_COL_2 =>
                        Col <= "1101"; 
                        if Row = "1110" then temp_key_val <= x"1"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1101" then temp_key_val <= x"4"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1011" then temp_key_val <= x"7"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "0111" then temp_key_val <= x"0"; current_state <= DEBOUNCE_PRESS;
                        else current_state <= SCAN_COL_3; end if;

                    -- ==========================================
                    -- SCAN COLUMN 3 (Physically mapped to Col 2: 2, 5, 8, F)
                    -- ==========================================
                    when SCAN_COL_3 =>
                        Col <= "1011"; 
                        if Row = "1110" then temp_key_val <= x"2"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1101" then temp_key_val <= x"5"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1011" then temp_key_val <= x"8"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "0111" then temp_key_val <= x"F"; current_state <= DEBOUNCE_PRESS;
                        else current_state <= SCAN_COL_4; end if;

                    -- ==========================================
                    -- SCAN COLUMN 4 (Physically mapped to Col 3: 3, 6, 9, E)
                    -- ==========================================
                    when SCAN_COL_4 =>
                        Col <= "0111"; 
                        if Row = "1110" then temp_key_val <= x"3"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1101" then temp_key_val <= x"6"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "1011" then temp_key_val <= x"9"; current_state <= DEBOUNCE_PRESS;
                        elsif Row = "0111" then temp_key_val <= x"E"; current_state <= DEBOUNCE_PRESS;
                        else current_state <= SCAN_COL_1; end if;

                    -- ==========================================
                    -- DEBOUNCE LOGIC 
                    -- ==========================================
                    when DEBOUNCE_PRESS =>
                        if delay_count < 20 then
                            delay_count <= delay_count + 1;
                        else
                            delay_count <= 0;
                            key_value <= temp_key_val;
                            key_valid <= '1'; 
                            current_state <= WAIT_RELEASE;
                        end if;

                    when WAIT_RELEASE =>
                        Col <= "0000"; 
                        if Row = "1111" then
                            current_state <= DEBOUNCE_RELEASE;
                        end if;

                    when DEBOUNCE_RELEASE =>
                        Col <= "0000";
                        if Row = "1111" then
                            if delay_count < 20 then
                                delay_count <= delay_count + 1;
                            else
                                delay_count <= 0;
                                current_state <= SCAN_COL_1;
                            end if;
                        else
                            delay_count <= 0;
                            current_state <= WAIT_RELEASE;
                        end if;

                end case;
            end if;
        end if;
    end process;

end Behavioral;