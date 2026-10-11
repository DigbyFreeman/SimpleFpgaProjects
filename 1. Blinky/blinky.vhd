-- blinky.vhd -- smoke test for Altera Cyclone V SoC Development Board
-- (5CSXFC6D6F31C6, the official Altera dev kit -- NOT the DE10-Standard)
--
-- Only 4 LEDs, 2 push buttons, and 4 DIP switch bits are wired straight
-- to the FPGA fabric on this board; everything else routes through the HPS.
--
--   LED(0)          ~1 Hz heartbeat (active-low: 0 = lit)
--   LED(3 downto 1) mirror SW(2 downto 0) (also active-low)
--   KEY(0)          async reset, active-low (press = 0)
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity blinky is
    port (
        CLOCK_50 : in  std_logic;                     -- PIN_AC18, 1.5-V
        KEY      : in  std_logic_vector(1 downto 0);  -- PIN_AA13, PIN_AB13, 1.5-V
        SW       : in  std_logic_vector(3 downto 0);  -- PIN_AG10..AG11, 2.5-V
        LED      : out std_logic_vector(3 downto 0)   -- PIN_AK2..AB17, 2.5-V, ACTIVE-LOW
    );
end entity blinky;
 
architecture rtl of blinky is
    constant HALF_PERIOD : natural := 25_000_000;  -- 0.5 s at 50 MHz
    signal   count       : unsigned(24 downto 0) := (others => '0');
    signal   heartbeat   : std_logic := '0';
    signal   rst_n       : std_logic;
begin
 
    rst_n <= KEY(0);   -- pressed = '0'
 
    process (CLOCK_50, rst_n)
    begin
        if rst_n = '0' then
            count     <= (others => '0');
            heartbeat <= '0';
        elsif rising_edge(CLOCK_50) then
            if count = HALF_PERIOD - 1 then
                count     <= (others => '0');
                heartbeat <= not heartbeat;
            else
                count <= count + 1;
            end if;
        end if;
    end process;
 
    -- LEDs are active-low: invert so "1"/heartbeat-high visually means "on"
    LED(0)          <= not heartbeat;
    LED(3 downto 1) <= not SW(2 downto 0);
 
end architecture rtl;
