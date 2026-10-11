library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity button_counter is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0);
        SW       : in  std_logic_vector(3 downto 0);
        LED      : out std_logic_vector(3 downto 0)
    );
end entity button_counter;


architecture rtl of button_counter is

    -- ============================================================
    -- Button synchronizer
    -- ============================================================

    signal key1_sync1 : std_logic := '1';
    signal key1_sync2 : std_logic := '1';


    -- ============================================================
    -- Debounced button state
    -- ============================================================

    signal key1_clean : std_logic := '1';

    constant DEBOUNCE_COUNT : natural := 500_000;

    signal debounce_counter : unsigned(18 downto 0) :=
        (others => '0');


    -- ============================================================
    -- Edge detection
    -- ============================================================

    signal key1_prev : std_logic := '1';


    -- ============================================================
    -- Counter
    -- ============================================================

    signal count : unsigned(3 downto 0) := (others => '0');


begin

    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then

            -- ----------------------------------------------------
            -- Synchronize physical button
            -- ----------------------------------------------------

            key1_sync1 <= KEY(1);
            key1_sync2 <= key1_sync1;


            -- ----------------------------------------------------
            -- Debounce
            -- ----------------------------------------------------

            if key1_sync2 = key1_clean then

                -- Button hasn't changed.
                -- Reset the debounce timer.

                debounce_counter <= (others => '0');

            else

                -- Button is different from our accepted state.
                -- Start counting how long it remains different.

                if debounce_counter = DEBOUNCE_COUNT - 1 then

                    -- It stayed different for 10 ms.
                    -- Accept the new state.

                    key1_clean <= key1_sync2;
                    debounce_counter <= (others => '0');

                else

                    debounce_counter <= debounce_counter + 1;

                end if;

            end if;


            -- ----------------------------------------------------
            -- Edge detection
            -- ----------------------------------------------------

            key1_prev <= key1_clean;


            -- ----------------------------------------------------
            -- Counter
            -- ----------------------------------------------------

            -- Detect a clean 1 -> 0 transition.
            -- The button is active-low.

            if key1_prev = '1' and key1_clean = '0' then
                count <= count + 1;
            end if;

        end if;
    end process;


    -- LEDs are active-low.

    LED <= not std_logic_vector(count);

end architecture rtl;