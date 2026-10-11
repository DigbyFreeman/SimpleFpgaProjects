library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Dice is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0);
        LED      : out std_logic_vector(3 downto 0)
    );
end entity Dice;


architecture rtl of Dice is


    ----------------------------------------------------------------
    -- BUTTON SYNCHRONIZERS
    ----------------------------------------------------------------

    signal key0_sync1 : std_logic := '1';
    signal key0_sync2 : std_logic := '1';

    signal key1_sync1 : std_logic := '1';
    signal key1_sync2 : std_logic := '1';


    ----------------------------------------------------------------
    -- BUTTON DEBOUNCERS
    --
    -- 50 MHz / 100 = 500,000 clocks = 10 ms
    ----------------------------------------------------------------

    constant DEBOUNCE_COUNT : natural := 500_000;

    signal key0_debounce_count : unsigned(18 downto 0)
        := (others => '0');

    signal key1_debounce_count : unsigned(18 downto 0)
        := (others => '0');

    signal key0_clean : std_logic := '1';
    signal key1_clean : std_logic := '1';


    ----------------------------------------------------------------
    -- LFSR
    --
    -- Pseudo-random number generator.
    ----------------------------------------------------------------

    signal lfsr : std_logic_vector(15 downto 0)
        := x"ACE1";


    ----------------------------------------------------------------
    -- DICE VALUE
    --
    -- Values 1 through 6.
    ----------------------------------------------------------------

    signal dice_value : unsigned(2 downto 0)
        := to_unsigned(1, 3);


    ----------------------------------------------------------------
    -- ROLL TIMER
    --
    -- Controls how quickly the dice changes while KEY0
    -- is held down.
    --
    -- 50 MHz / 100,000 = 500 rolls per second.
    ----------------------------------------------------------------

    constant ROLL_COUNT : natural := 100_000;

    signal roll_counter : unsigned(16 downto 0)
        := (others => '0');


begin


    ----------------------------------------------------------------
    -- BUTTON SYNCHRONIZATION
    ----------------------------------------------------------------

    process (CLOCK_50)
    begin

        if rising_edge(CLOCK_50) then

            key0_sync1 <= KEY(0);
            key0_sync2 <= key0_sync1;

            key1_sync1 <= KEY(1);
            key1_sync2 <= key1_sync1;

        end if;

    end process;


    ----------------------------------------------------------------
    -- KEY 0 DEBOUNCER
    ----------------------------------------------------------------

    process (CLOCK_50)
    begin

        if rising_edge(CLOCK_50) then

            if key0_sync2 = key0_clean then

                key0_debounce_count <=
                    (others => '0');

            else

                if key0_debounce_count =
                    DEBOUNCE_COUNT - 1 then

                    key0_clean <= key0_sync2;

                    key0_debounce_count <=
                        (others => '0');

                else

                    key0_debounce_count <=
                        key0_debounce_count + 1;

                end if;

            end if;

        end if;

    end process;


    ----------------------------------------------------------------
    -- KEY 1 DEBOUNCER
    ----------------------------------------------------------------

    process (CLOCK_50)
    begin

        if rising_edge(CLOCK_50) then

            if key1_sync2 = key1_clean then

                key1_debounce_count <=
                    (others => '0');

            else

                if key1_debounce_count =
                    DEBOUNCE_COUNT - 1 then

                    key1_clean <= key1_sync2;

                    key1_debounce_count <=
                        (others => '0');

                else

                    key1_debounce_count <=
                        key1_debounce_count + 1;

                end if;

            end if;

        end if;

    end process;


    ----------------------------------------------------------------
    -- LFSR
    --
    -- Continuously generates a pseudo-random sequence.
    ----------------------------------------------------------------

    process (CLOCK_50)

        variable feedback : std_logic;

    begin

        if rising_edge(CLOCK_50) then

            feedback :=
                lfsr(15) xor
                lfsr(13) xor
                lfsr(12) xor
                lfsr(10);

            lfsr <=
                lfsr(14 downto 0) & feedback;

        end if;

    end process;


    ----------------------------------------------------------------
    -- DICE CONTROLLER
    ----------------------------------------------------------------

    process (CLOCK_50)
    begin

        if rising_edge(CLOCK_50) then


            --------------------------------------------------------
            -- KEY1 = RESET
            --------------------------------------------------------

            if key1_clean = '0' then

                dice_value <=
                    to_unsigned(1, 3);

                roll_counter <=
                    (others => '0');


            --------------------------------------------------------
            -- NORMAL OPERATION
            --------------------------------------------------------

            else

                ----------------------------------------------------
                -- KEY0 HELD = ROLL
                ----------------------------------------------------

                if key0_clean = '0' then

                    if roll_counter = ROLL_COUNT - 1 then

                        roll_counter <=
                            (others => '0');


                        ------------------------------------------------
                        -- Generate number from 1 to 6.
                        ------------------------------------------------

                        dice_value <=
                            (unsigned(lfsr(2 downto 0)) mod 6)
                            + 1;

                    else

                        roll_counter <=
                            roll_counter + 1;

                    end if;


                else

                    ------------------------------------------------
                    -- KEY0 RELEASED
                    --
                    -- Dice remains at its current value.
                    ------------------------------------------------

                    roll_counter <=
                        (others => '0');

                end if;

            end if;

        end if;

    end process;


    ----------------------------------------------------------------
    -- LED OUTPUT
    --
    -- Your board LEDs are ACTIVE-LOW.
    --
    -- Therefore:
    --
    -- LED = 0 -> ON
    -- LED = 1 -> OFF
    --
    -- We invert the dice value before sending it to the LEDs.
    ----------------------------------------------------------------

    process (dice_value)
    begin

        LED <= not std_logic_vector(
            resize(dice_value, 4)
        );

    end process;


end architecture rtl;
