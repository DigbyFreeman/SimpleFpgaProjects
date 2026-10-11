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

    -- Button 1 synchronizer
    signal key1_sync1 : std_logic := '1';
    signal key1_sync2 : std_logic := '1';

    -- Previous synchronized button state
    signal key1_prev : std_logic := '1';

    -- Four-bit counter
    signal count : unsigned(3 downto 0) := (others => '0');

begin

    process (CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then

            -- Synchronize the physical button to CLOCK_50
            key1_sync1 <= KEY(1);
            key1_sync2 <= key1_sync1;

            -- Remember previous button state
            key1_prev <= key1_sync2;

            -- Detect button press:
            -- KEY goes from 1 (released) to 0 (pressed)
            if key1_prev = '1' and key1_sync2 = '0' then
                count <= count + 1;
            end if;

        end if;
    end process;


    -- LEDs are active-low.
    -- Convert the counter to std_logic_vector and invert it.
    LED <= not std_logic_vector(count);

end architecture rtl;