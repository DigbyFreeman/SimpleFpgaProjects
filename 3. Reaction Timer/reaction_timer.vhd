library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity reaction_timer is
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0);
        SW       : in  std_logic_vector(3 downto 0);
        LED      : out std_logic_vector(3 downto 0)
    );
end entity reaction_timer;


architecture rtl of reaction_timer is


    ----------------------------------------------------------------
    -- BUTTON SYNCHRONIZERS
    --
    -- KEYs are physical signals and are not synchronized to the
    -- 50 MHz FPGA clock.
    --
    -- Two flip-flops safely bring them into our clock domain.
    ----------------------------------------------------------------

    signal key0_sync1 : std_logic := '1';
    signal key0_sync2 : std_logic := '1';

    signal key1_sync1 : std_logic := '1';
    signal key1_sync2 : std_logic := '1';


    ----------------------------------------------------------------
    -- BUTTON DEBOUNCERS
    --
    -- Require the button signal to remain stable for 10 ms before
    -- accepting a change.
    --
    -- 50,000,000 clocks/sec
    -- / 100
    -- = 500,000 clocks
    ----------------------------------------------------------------

    constant DEBOUNCE_COUNT : natural := 500_000;

    signal key0_debounce_count : unsigned(18 downto 0)
        := (others => '0');

    signal key1_debounce_count : unsigned(18 downto 0)
        := (others => '0');

    signal key0_clean : std_logic := '1';
    signal key1_clean : std_logic := '1';


    ----------------------------------------------------------------
    -- STATE MACHINE
    ----------------------------------------------------------------

    type state_type is (
        IDLE,
        WAITING,
        GO,
        TIMING
    );

    signal state : state_type := IDLE;


    ----------------------------------------------------------------
    -- PSEUDO-RANDOM NUMBER GENERATOR
    --
    -- 16-bit Linear Feedback Shift Register.
    --
    -- It continuously cycles through a pseudo-random sequence.
    ----------------------------------------------------------------

    signal lfsr : std_logic_vector(15 downto 0)
        := x"ACE1";


    ----------------------------------------------------------------
    -- RANDOM WAIT TIMER
    --
    -- CLOCK_50 = 50 MHz
    --
    -- Random delay will be approximately 1 to 5 seconds.
    ----------------------------------------------------------------

    constant ONE_SECOND : natural := 50_000_000;

    signal wait_counter : unsigned(27 downto 0)
        := (others => '0');

    signal wait_target : unsigned(27 downto 0)
        := (others => '0');


    ----------------------------------------------------------------
    -- REACTION TIMER
    --
    -- We count milliseconds.
    --
    -- 50,000,000 clocks/sec
    -- / 50,000 clocks/ms
    -- = 1,000 milliseconds/sec
    ----------------------------------------------------------------

    constant CLOCKS_PER_MS : natural := 50_000;

    signal ms_counter : unsigned(15 downto 0)
        := (others => '0');

    signal reaction_time_ms : unsigned(31 downto 0)
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

                key0_debounce_count <= (others => '0');

            else

                if key0_debounce_count = DEBOUNCE_COUNT - 1 then

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

                key1_debounce_count <= (others => '0');

            else

                if key1_debounce_count = DEBOUNCE_COUNT - 1 then

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
    -- LFSR PSEUDO-RANDOM GENERATOR
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
    -- MAIN GAME STATE MACHINE
    ----------------------------------------------------------------

    process (CLOCK_50)

    begin

        if rising_edge(CLOCK_50) then


            --------------------------------------------------------
            -- KEY 1 = GLOBAL RESET
            --
            -- Pressing KEY 1 resets the game regardless of what
            -- state we are currently in.
            --------------------------------------------------------

            if key1_clean = '0' then

                state <= IDLE;

                wait_counter <=
                    (others => '0');

                wait_target <=
                    (others => '0');

                ms_counter <=
                    (others => '0');

                reaction_time_ms <=
                    (others => '0');


            else


                ----------------------------------------------------
                -- NORMAL STATE MACHINE
                ----------------------------------------------------

                case state is


                    ------------------------------------------------
                    -- IDLE
                    --
                    -- All LEDs are off.
                    --
                    -- Waiting for the player to press and hold
                    -- KEY 0.
                    ------------------------------------------------

                    when IDLE =>

                        wait_counter <=
                            (others => '0');

                        ms_counter <=
                            (others => '0');

                        reaction_time_ms <=
                            (others => '0');


                        if key0_clean = '0' then

                            ------------------------------------------------
                            -- Pick a random delay between approximately
                            -- 1 and 5 seconds.
                            ------------------------------------------------

                            wait_target <=
                                ONE_SECOND +
                                (
                                    resize(
                                        unsigned(lfsr),
                                        wait_target'length
                                    ) mod
                                    (4 * ONE_SECOND)
                                );

                            state <= WAITING;

                        end if;


                    ------------------------------------------------
                    -- WAITING
                    --
                    -- Player is still holding KEY 0.
                    --
                    -- LEDs remain OFF.
                    --
                    -- We count until the random delay expires.
                    ------------------------------------------------

                    when WAITING =>

                        if wait_counter >= wait_target then

                            wait_counter <=
                                (others => '0');

                            state <= GO;

                        else

                            wait_counter <=
                                wait_counter + 1;

                        end if;


                    ------------------------------------------------
                    -- GO
                    --
                    -- All LEDs are ON.
                    --
                    -- The player must release KEY 0.
                    --
                    -- The instant KEY 0 is released, we enter
                    -- TIMING and start measuring the reaction time.
                    ------------------------------------------------

                    when GO =>

                        if key0_clean = '1' then

                            reaction_time_ms <=
                                (others => '0');

                            ms_counter <=
                                (others => '0');

                            state <= TIMING;

                        end if;


                    ------------------------------------------------
                    -- TIMING
                    --
                    -- All LEDs remain ON.
                    --
                    -- Count milliseconds until KEY 1 is pressed.
                    --
                    -- KEY 1 is handled above as the global reset.
                    ------------------------------------------------

                    when TIMING =>

                        if ms_counter = CLOCKS_PER_MS - 1 then

                            ms_counter <=
                                (others => '0');

                            reaction_time_ms <=
                                reaction_time_ms + 1;

                        else

                            ms_counter <=
                                ms_counter + 1;

                        end if;


                end case;

            end if;

        end if;

    end process;


    ----------------------------------------------------------------
    -- LED OUTPUT
    --
    -- Your FPGA LEDs are ACTIVE-LOW:
    --
    -- 0 = ON
    -- 1 = OFF
    ----------------------------------------------------------------

    process (state)

    begin

        case state is

            when IDLE =>
                LED <= "1111";


            when WAITING =>
                LED <= "1111";


            when GO =>
                LED <= "0000";


            when TIMING =>
                LED <= "0000";

        end case;

    end process;


end architecture rtl;
