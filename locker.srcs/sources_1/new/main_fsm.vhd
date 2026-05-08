library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main_fsm is
    Port ( 
        clk_100MHz   : in  STD_LOGIC;
        reset        : in  STD_LOGIC;
        clk_1kHz_en  : in  STD_LOGIC; 
        
        scroll_pulse : in  STD_LOGIC;
        ok_pulse     : in  STD_LOGIC;
        key_value    : in  STD_LOGIC_VECTOR (3 downto 0);
        key_valid    : in  STD_LOGIC;
        
        digit_1      : out STD_LOGIC_VECTOR (3 downto 0);
        digit_2      : out STD_LOGIC_VECTOR (3 downto 0);
        digit_3      : out STD_LOGIC_VECTOR (3 downto 0);
        digit_4      : out STD_LOGIC_VECTOR (3 downto 0);
        show_admin   : out STD_LOGIC;
        led_users    : out STD_LOGIC_VECTOR (4 downto 0);
        led_access   : out STD_LOGIC;
        led_alarm    : out STD_LOGIC
    );
end main_fsm;

architecture Behavioral of main_fsm is

    -- Added ADMIN_CHANGE_ALARM to the state list
    type state_type is (IDLE, SETUP_STEP1, SETUP_STEP2, ENTER_PIN, ALARM, ACCESS_STD, ADMIN_MENU, ADMIN_RESET_USER, ADMIN_CHANGE_ALARM);
    signal current_state : state_type := IDLE;

    type pin_array_type is array (0 to 4) of STD_LOGIC_VECTOR(15 downto 0);
    signal user_pins : pin_array_type := (
        0 => x"0000", 
        1 => x"0000", 
        2 => x"0000", 
        3 => x"0000", 
        4 => x"1234"  -- Admin
    );

    signal current_user  : integer range 0 to 4 := 0;
    signal fail_count    : integer range 0 to 3 := 0;
    signal digits_typed  : integer range 0 to 4 := 0;
    
    signal current_input : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal setup_memory  : STD_LOGIC_VECTOR(15 downto 0) := x"0000"; 

    -- Timers (Removed the arbitrary 30,000 limit to allow for long alarms)
    signal timeout_counter : integer := 0; 
    constant TIMEOUT_15S   : integer := 15000; 
    signal alarm_duration  : integer := 10000; -- Default 10 seconds

begin

    digit_1 <= current_input(3 downto 0);
    digit_2 <= current_input(7 downto 4);
    digit_3 <= current_input(11 downto 8);
    digit_4 <= current_input(15 downto 12);

    process(clk_100MHz, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
            current_user <= 0;
            fail_count <= 0;
            current_input <= x"0000";
            
            user_pins(0) <= x"0000"; user_pins(1) <= x"0000";
            user_pins(2) <= x"0000"; user_pins(3) <= x"0000";
            user_pins(4) <= x"1234"; 
            
            led_access <= '0';
            led_alarm <= '0';
            alarm_duration <= 10000; -- Reset alarm to 10 seconds
            
        elsif rising_edge(clk_100MHz) then
        
            show_admin <= '0';
            if current_user = 4 then show_admin <= '1'; end if;
            
            led_users <= (others => '0');
            led_users(current_user) <= '1';

            case current_state is

                when IDLE =>
                    led_access <= '0';
                    led_alarm <= '0';
                    current_input <= x"0000";
                    digits_typed <= 0;
                    timeout_counter <= 0;
                    
                    if scroll_pulse = '1' then
                        if current_user = 4 then current_user <= 0;
                        else current_user <= current_user + 1;
                        end if;
                    end if;
                    
                    if ok_pulse = '1' then
                        if user_pins(current_user) = x"0000" then
                            current_state <= SETUP_STEP1; 
                        else
                            current_state <= ENTER_PIN;   
                        end if;
                    end if;

                when ENTER_PIN =>
                    if key_valid = '1' and digits_typed < 4 then
                        current_input <= current_input(11 downto 0) & key_value;
                        digits_typed <= digits_typed + 1;
                        timeout_counter <= 0; 
                    end if;

                    if clk_1kHz_en = '1' then
                        timeout_counter <= timeout_counter + 1;
                        if timeout_counter >= TIMEOUT_15S then
                            current_state <= IDLE; 
                        end if;
                    end if;

                    if ok_pulse = '1' and digits_typed = 4 then
                        if current_input = user_pins(current_user) then
                            fail_count <= 0;
                            if current_user = 4 then current_state <= ADMIN_MENU;
                            else current_state <= ACCESS_STD;
                            end if;
                        else
                            current_input <= x"0000";
                            digits_typed <= 0;
                            fail_count <= fail_count + 1;
                            if fail_count = 2 then 
                                current_state <= ALARM;
                            end if;
                        end if;
                    end if;

                when SETUP_STEP1 =>
                    if key_valid = '1' and digits_typed < 4 then
                        current_input <= current_input(11 downto 0) & key_value;
                        digits_typed <= digits_typed + 1;
                    end if;
                    
                    if ok_pulse = '1' and digits_typed = 4 then
                        setup_memory <= current_input; 
                        current_input <= x"0000";
                        digits_typed <= 0;
                        current_state <= SETUP_STEP2;
                    end if;

                when SETUP_STEP2 =>
                    if key_valid = '1' and digits_typed < 4 then
                        current_input <= current_input(11 downto 0) & key_value;
                        digits_typed <= digits_typed + 1;
                    end if;
                    
                    if ok_pulse = '1' and digits_typed = 4 then
                        if current_input = setup_memory then
                            user_pins(current_user) <= current_input; 
                            current_state <= IDLE;
                        else
                            current_input <= x"0000";
                            digits_typed <= 0;
                            current_state <= SETUP_STEP1;
                        end if;
                    end if;

                when ALARM =>
                    led_alarm <= '1'; 
                    
                    if clk_1kHz_en = '1' then
                        timeout_counter <= timeout_counter + 1;
                        if timeout_counter >= alarm_duration then
                            fail_count <= 0;
                            current_state <= IDLE;
                        end if;
                    end if;

                when ACCESS_STD =>
                    led_access <= '1'; 
                    current_input <= user_pins(current_user); 
                    if ok_pulse = '1' then
                        current_state <= IDLE; 
                    end if;

                when ADMIN_MENU =>
                    led_access <= '1';
                    current_input <= x"A000"; 
                    
                    if key_valid = '1' then
                        if key_value = x"1" then
                            current_user <= 0; 
                            current_state <= ADMIN_RESET_USER;
                        elsif key_value = x"2" then
                            -- NEW: Transition to the change alarm state
                            current_input <= x"0000";
                            digits_typed <= 0;
                            current_state <= ADMIN_CHANGE_ALARM;
                        end if;
                    end if;
                    
                    if ok_pulse = '1' then current_state <= IDLE; end if; 

                when ADMIN_RESET_USER =>
                    if scroll_pulse = '1' then
                        if current_user = 3 then current_user <= 0;
                        else current_user <= current_user + 1;
                        end if;
                    end if;
                    
                    if ok_pulse = '1' then
                        user_pins(current_user) <= x"0000";
                        current_user <= 4; 
                        current_state <= ADMIN_MENU;
                    end if;

                -- ==========================================
                -- NEW STATE: Change the Alarm Timer
                -- ==========================================
                when ADMIN_CHANGE_ALARM =>
                    -- Let user type the new duration (e.g., 0 0 0 5 for 5 seconds)
                    if key_valid = '1' and digits_typed < 4 then
                        current_input <= current_input(11 downto 0) & key_value;
                        digits_typed <= digits_typed + 1;
                    end if;
                    
                    -- Press OK to save and return to Admin Menu
                    if ok_pulse = '1' and digits_typed > 0 then
                        -- Convert the Hex input to integer (seconds), then multiply by 1000 for milliseconds
                        alarm_duration <= to_integer(unsigned(current_input)) * 1000;
                        
                        -- Go back to the Admin Menu
                        current_user <= 4; 
                        current_state <= ADMIN_MENU;
                    end if;

            end case;
        end if;
    end process;

end Behavioral;