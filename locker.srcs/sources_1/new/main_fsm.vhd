library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main_fsm is
    Port ( 
        clk_100MHz   : in  STD_LOGIC;
        reset        : in  STD_LOGIC;
        clk_1kHz_en  : in  STD_LOGIC; -- 1ms tick for timers
        
        -- Inputs from buttons and keypad
        scroll_pulse : in  STD_LOGIC;
        ok_pulse     : in  STD_LOGIC;
        key_value    : in  STD_LOGIC_VECTOR (3 downto 0);
        key_valid    : in  STD_LOGIC;
        
        -- Outputs to Display and LEDs
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

    -- 1. DEFINE THE STATES
    type state_type is (IDLE, SETUP_STEP1, SETUP_STEP2, ENTER_PIN, ALARM, ACCESS_STD, ADMIN_MENU, ADMIN_RESET_USER);
    signal current_state : state_type := IDLE;

    -- 2. DEFINE THE MEMORY (Array of 5 PINs, 16 bits each to hold 4 Hex digits)
    type pin_array_type is array (0 to 4) of STD_LOGIC_VECTOR(15 downto 0);
    signal user_pins : pin_array_type := (
        0 => x"0000", -- User 1 (Unset)
        1 => x"0000", -- User 2 (Unset)
        2 => x"0000", -- User 3 (Unset)
        3 => x"0000", -- User 4 (Unset)
        4 => x"1234"  -- Admin (Hardcoded default)
    );

    -- 3. TRACKING VARIABLES
    signal current_user  : integer range 0 to 4 := 0;
    signal fail_count    : integer range 0 to 3 := 0;
    signal digits_typed  : integer range 0 to 4 := 0;
    
    -- Holds the digits as they are being typed on the keypad
    signal current_input : STD_LOGIC_VECTOR(15 downto 0) := x"0000";
    signal setup_memory  : STD_LOGIC_VECTOR(15 downto 0) := x"0000"; -- Saves first try during setup

    -- 4. TIMERS (Using 1kHz tick)
    signal timeout_counter : integer range 0 to 30000 := 0; 
    constant TIMEOUT_15S   : integer := 15000; -- 15,000 ms = 15 seconds
    signal alarm_duration  : integer := 10000; -- Default 10 seconds for alarm

begin

    -- Continuously map the current input to the 4 displays so the user sees what they type
    digit_1 <= current_input(3 downto 0);
    digit_2 <= current_input(7 downto 4);
    digit_3 <= current_input(11 downto 8);
    digit_4 <= current_input(15 downto 12);

    process(clk_100MHz, reset)
    begin
        if reset = '1' then
            -- Reset completely restarts the system
            current_state <= IDLE;
            current_user <= 0;
            fail_count <= 0;
            current_input <= x"0000";
            
            -- Reset memory to defaults
            user_pins(0) <= x"0000"; user_pins(1) <= x"0000";
            user_pins(2) <= x"0000"; user_pins(3) <= x"0000";
            user_pins(4) <= x"1234"; -- Admin
            
            led_access <= '0';
            led_alarm <= '0';
            
        elsif rising_edge(clk_100MHz) then
        
            -- Dynamic Output Updates
            show_admin <= '0';
            if current_user = 4 then show_admin <= '1'; end if;
            
            -- Light up the correct User LED (1 out of 5)
            led_users <= (others => '0');
            led_users(current_user) <= '1';

            -- ==========================================
            -- THE STATE MACHINE
            -- ==========================================
            case current_state is

                -- ================== IDLE STATE ==================
                when IDLE =>
                    led_access <= '0';
                    led_alarm <= '0';
                    current_input <= x"0000";
                    digits_typed <= 0;
                    timeout_counter <= 0;
                    
                    -- Scroll through users
                    if scroll_pulse = '1' then
                        if current_user = 4 then current_user <= 0;
                        else current_user <= current_user + 1;
                        end if;
                    end if;
                    
                    -- OK Button Pressed -> Check PIN Status
                    if ok_pulse = '1' then
                        if user_pins(current_user) = x"0000" then
                            current_state <= SETUP_STEP1; -- Go to setup
                        else
                            current_state <= ENTER_PIN;   -- Go to login
                        end if;
                    end if;

                -- ================== ENTER PIN STATE ==================
                when ENTER_PIN =>
                    -- Keypad Entry Logic (Shift digits left)
                    if key_valid = '1' and digits_typed < 4 then
                        current_input <= current_input(11 downto 0) & key_value;
                        digits_typed <= digits_typed + 1;
                        timeout_counter <= 0; -- Reset timeout if they press a key
                    end if;

                    -- 15 Second Timeout Timer
                    if clk_1kHz_en = '1' then
                        timeout_counter <= timeout_counter + 1;
                        if timeout_counter >= TIMEOUT_15S then
                            current_state <= IDLE; -- Boot them back to idle
                        end if;
                    end if;

                    -- Verification Logic
                    if ok_pulse = '1' and digits_typed = 4 then
                        if current_input = user_pins(current_user) then
                            -- Correct PIN
                            fail_count <= 0;
                            if current_user = 4 then current_state <= ADMIN_MENU;
                            else current_state <= ACCESS_STD;
                            end if;
                        else
                            -- Wrong PIN
                            current_input <= x"0000";
                            digits_typed <= 0;
                            fail_count <= fail_count + 1;
                            if fail_count = 2 then -- Reached 3 strikes (0, 1, 2)
                                current_state <= ALARM;
                            end if;
                        end if;
                    end if;

                -- ================== SETUP STATES ==================
                when SETUP_STEP1 =>
                    if key_valid = '1' and digits_typed < 4 then
                        current_input <= current_input(11 downto 0) & key_value;
                        digits_typed <= digits_typed + 1;
                    end if;
                    
                    if ok_pulse = '1' and digits_typed = 4 then
                        setup_memory <= current_input; -- Save first entry
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
                            user_pins(current_user) <= current_input; -- Save to memory!
                            current_state <= IDLE;
                        else
                            -- Mismatch, start over
                            current_input <= x"0000";
                            digits_typed <= 0;
                            current_state <= SETUP_STEP1;
                        end if;
                    end if;

                -- ================== ALARM STATE ==================
                when ALARM =>
                    led_alarm <= '1'; -- Turn on Red LED
                    
                    if clk_1kHz_en = '1' then
                        timeout_counter <= timeout_counter + 1;
                        if timeout_counter >= alarm_duration then
                            fail_count <= 0;
                            current_state <= IDLE;
                        end if;
                    end if;

                -- ================== ACCESS STATES ==================
                when ACCESS_STD =>
                    led_access <= '1'; -- Turn on Green LED
                    current_input <= user_pins(current_user); -- Show their PIN or "OPEN" pattern
                    if ok_pulse = '1' then
                        current_state <= IDLE; -- Lock safe and return
                    end if;

                when ADMIN_MENU =>
                    led_access <= '1';
                    current_input <= x"A000"; -- Show they are in the menu
                    
                    if key_valid = '1' then
                        if key_value = x"1" then
                            current_user <= 0; -- Start at user 1 for reset selection
                            current_state <= ADMIN_RESET_USER;
                        end if;
                        -- (You could add "if key_value = x"2" then go to ADMIN_CHANGE_ALARM here)
                    end if;
                    
                    if ok_pulse = '1' then current_state <= IDLE; end if; -- Logout

                when ADMIN_RESET_USER =>
                    -- Scroll through users 0 to 3
                    if scroll_pulse = '1' then
                        if current_user = 3 then current_user <= 0;
                        else current_user <= current_user + 1;
                        end if;
                    end if;
                    
                    -- Press OK to reset the selected user's pin to 0000
                    if ok_pulse = '1' then
                        user_pins(current_user) <= x"0000";
                        current_user <= 4; -- Switch back to Admin
                        current_state <= ADMIN_MENU;
                    end if;

            end case;
        end if;
    end process;

end Behavioral;