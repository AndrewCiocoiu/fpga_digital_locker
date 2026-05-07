library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_module is
    Port ( 
        -- Physical Board Inputs
        clk_100MHz  : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        btn_scroll  : in  STD_LOGIC;
        btn_ok      : in  STD_LOGIC;
        PMOD_Row    : in  STD_LOGIC_VECTOR (3 downto 0);
        
        -- Physical Board Outputs
        PMOD_Col    : out STD_LOGIC_VECTOR (3 downto 0);
        LED_Users   : out STD_LOGIC_VECTOR (4 downto 0); -- 5 LEDs for the 5 Users
        LED_Access  : out STD_LOGIC;                     -- Green LED (Access Granted)
        LED_Alarm   : out STD_LOGIC;                     -- Red LED (Alarm State)
        seg         : out STD_LOGIC_VECTOR (6 downto 0); -- 7-Segment Cathodes
        an          : out STD_LOGIC_VECTOR (7 downto 0)  -- 7-Segment Anodes
    );
end top_module;

architecture Structural of top_module is

    -- ==========================================
    -- 1. COMPONENT DECLARATIONS (The Black Boxes)
    -- ==========================================
    
    component clk_div
        Port ( clk_100MHz, reset : in STD_LOGIC;
               clk_1kHz_en       : out STD_LOGIC );
    end component;

    component debouncer
        Port ( clk_100MHz, reset, btn_in, clk_1kHz_en : in STD_LOGIC;
               btn_pulse                              : out STD_LOGIC );
    end component;

    component keypad_scanner
        Port ( clk_100MHz, reset, clk_1kHz_en : in STD_LOGIC;
               Row                            : in STD_LOGIC_VECTOR (3 downto 0);
               Col                            : out STD_LOGIC_VECTOR (3 downto 0);
               key_value                      : out STD_LOGIC_VECTOR (3 downto 0);
               key_valid                      : out STD_LOGIC );
    end component;

    component display_driver
        Port ( clk_100MHz, reset, clk_1kHz_en : in STD_LOGIC;
               digit_1, digit_2, digit_3, digit_4 : in STD_LOGIC_VECTOR (3 downto 0);
               show_admin                     : in STD_LOGIC;
               seg                            : out STD_LOGIC_VECTOR (6 downto 0);
               an                             : out STD_LOGIC_VECTOR (7 downto 0) );
    end component;

    -- We haven't written this yet, but we must declare it so we can wire it up!
    component main_fsm
        Port ( clk_100MHz, reset, clk_1kHz_en : in STD_LOGIC;
               scroll_pulse, ok_pulse         : in STD_LOGIC;
               key_value                      : in STD_LOGIC_VECTOR (3 downto 0);
               key_valid                      : in STD_LOGIC;
               digit_1, digit_2, digit_3, digit_4 : out STD_LOGIC_VECTOR (3 downto 0);
               show_admin                     : out STD_LOGIC;
               led_users                      : out STD_LOGIC_VECTOR (4 downto 0);
               led_access, led_alarm          : out STD_LOGIC );
    end component;

    -- ==========================================
    -- 2. INTERNAL SIGNALS (The Wires)
    -- ==========================================
    signal w_1kHz_tick  : STD_LOGIC;
    signal w_clean_scr  : STD_LOGIC;
    signal w_clean_ok   : STD_LOGIC;
    
    signal w_key_val    : STD_LOGIC_VECTOR (3 downto 0);
    signal w_key_valid  : STD_LOGIC;
    
    signal w_dig1, w_dig2, w_dig3, w_dig4 : STD_LOGIC_VECTOR (3 downto 0);
    signal w_show_admin : STD_LOGIC;

begin

    -- ==========================================
    -- 3. PORT MAPPING (Plugging it all together)
    -- ==========================================

    Inst_Clock_Divider: clk_div
        port map (
            clk_100MHz  => clk_100MHz,
            reset       => reset,
            clk_1kHz_en => w_1kHz_tick
        );

    Inst_Debounce_Scroll: debouncer
        port map (
            clk_100MHz  => clk_100MHz,
            reset       => reset,
            btn_in      => btn_scroll,
            clk_1kHz_en => w_1kHz_tick,
            btn_pulse   => w_clean_scr
        );

    Inst_Debounce_OK: debouncer
        port map (
            clk_100MHz  => clk_100MHz,
            reset       => reset,
            btn_in      => btn_ok,
            clk_1kHz_en => w_1kHz_tick,
            btn_pulse   => w_clean_ok
        );

    Inst_Keypad: keypad_scanner
        port map (
            clk_100MHz  => clk_100MHz,
            reset       => reset,
            clk_1kHz_en => w_1kHz_tick,
            Row         => PMOD_Row,
            Col         => PMOD_Col,
            key_value   => w_key_val,
            key_valid   => w_key_valid
        );

    Inst_Display: display_driver
        port map (
            clk_100MHz  => clk_100MHz,
            reset       => reset,
            clk_1kHz_en => w_1kHz_tick,
            digit_1     => w_dig1,
            digit_2     => w_dig2,
            digit_3     => w_dig3,
            digit_4     => w_dig4,
            show_admin  => w_show_admin,
            seg         => seg,
            an          => an
        );

    Inst_FSM: main_fsm
        port map (
            clk_100MHz   => clk_100MHz,
            reset        => reset,
            clk_1kHz_en  => w_1kHz_tick,
            scroll_pulse => w_clean_scr,
            ok_pulse     => w_clean_ok,
            key_value    => w_key_val,
            key_valid    => w_key_valid,
            digit_1      => w_dig1,
            digit_2      => w_dig2,
            digit_3      => w_dig3,
            digit_4      => w_dig4,
            show_admin   => w_show_admin,
            led_users    => LED_Users,
            led_access   => LED_Access,
            led_alarm    => LED_Alarm
        );

end Structural;