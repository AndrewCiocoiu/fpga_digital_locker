library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_driver is
    Port ( 
        clk_100MHz  : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        clk_1kHz_en : in  STD_LOGIC;  
        
        digit_1     : in  STD_LOGIC_VECTOR (3 downto 0);
        digit_2     : in  STD_LOGIC_VECTOR (3 downto 0);
        digit_3     : in  STD_LOGIC_VECTOR (3 downto 0);
        digit_4     : in  STD_LOGIC_VECTOR (3 downto 0);
        show_admin  : in  STD_LOGIC; 

        seg         : out STD_LOGIC_VECTOR (6 downto 0);
        an          : out STD_LOGIC_VECTOR (7 downto 0) 
    );
end display_driver;

architecture Behavioral of display_driver is

    signal refresh_counter : unsigned(2 downto 0) := "000";
    signal current_hex_val : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    
    -- THE FIX: An internal signal to hold the anode state
    signal current_an      : STD_LOGIC_VECTOR(7 downto 0) := "11111111";

begin

    -- ==========================================
    -- PROCESS 1: The Multiplexer (Digit Selector)
    -- ==========================================
    process(clk_100MHz, reset)
    begin
        if reset = '1' then
            refresh_counter <= "000";
        elsif rising_edge(clk_100MHz) then
            if clk_1kHz_en = '1' then
                refresh_counter <= refresh_counter + 1;
            end if;
        end if;
    end process;

    -- ==========================================
    -- PROCESS 2: Anode & Data Routing
    -- ==========================================
    process(refresh_counter, digit_1, digit_2, digit_3, digit_4, show_admin)
    begin
        -- Default to everything OFF using our internal signal
        current_an <= "11111111"; 
        current_hex_val <= "0000"; 
        
        case refresh_counter is
            when "000" => 
                current_an <= "11111110";         
                current_hex_val <= digit_1;
            when "001" => 
                current_an <= "11111101";         
                current_hex_val <= digit_2;
            when "010" => 
                current_an <= "11111011";         
                current_hex_val <= digit_3;
            when "011" => 
                current_an <= "11110111";         
                current_hex_val <= digit_4;
            
            when "100" => current_an <= "11111111"; 
            when "101" => current_an <= "11111111"; 
            when "110" => current_an <= "11111111"; 
            
            when "111" => 
                if show_admin = '1' then
                    current_an <= "01111111"; 
                    current_hex_val <= x"A"; 
                else
                    current_an <= "11111111"; 
                end if;
            when others => 
                current_an <= "11111111";
        end case;
    end process;

    -- ==========================================
    -- PROCESS 3: The Hex to 7-Segment Decoder
    -- ==========================================
    process(current_hex_val, current_an)
    begin
        -- Now we read from the internal signal! No errors!
        if current_an = "11111111" then
            seg <= "1111111"; 
        else
            case current_hex_val is
                when x"0" => seg <= "1000000"; -- 0
                when x"1" => seg <= "1111001"; -- 1
                when x"2" => seg <= "0100100"; -- 2
                when x"3" => seg <= "0110000"; -- 3
                when x"4" => seg <= "0011001"; -- 4
                when x"5" => seg <= "0010010"; -- 5
                when x"6" => seg <= "0000010"; -- 6
                when x"7" => seg <= "1111000"; -- 7
                when x"8" => seg <= "0000000"; -- 8
                when x"9" => seg <= "0010000"; -- 9
                when x"A" => seg <= "0001000"; -- A
                when x"B" => seg <= "0000011"; -- b
                when x"C" => seg <= "1000110"; -- C
                when x"D" => seg <= "0100001"; -- d
                when x"E" => seg <= "0000110"; -- E
                when x"F" => seg <= "0001110"; -- F
                when others => seg <= "1111111"; 
            end case;
        end if;
    end process;

    -- ==========================================
    -- DRIVE THE PHYSICAL OUTPUT
    -- ==========================================
    -- Finally, connect the internal wire to the physical output pin
    an <= current_an;

end Behavioral;