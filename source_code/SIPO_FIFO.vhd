library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SIPO_FIFO is
    generic (
        INPUT_WIDTH  : positive := 8;   -- Width of the serial input data
        OUTPUT_WIDTH : positive := 256 -- Width of the parallel output data
    );
    port (
        clk         : in  std_logic;                         -- Clock input
        reset       : in  std_logic;                         -- Reset input (active high)
        serial_in   : in  std_logic_vector(INPUT_WIDTH-1 downto 0); -- Input data
        load        : in  std_logic;                         -- Load signal
        parallel_out : out std_logic_vector(OUTPUT_WIDTH-1 downto 0) -- Parallel output
    );
end SIPO_FIFO;

architecture Behavioral of SIPO_FIFO is

    -- Calculate the number of input data words required to fill the output
    constant NUM_WORDS : integer := OUTPUT_WIDTH / INPUT_WIDTH;

    -- Internal shift register to hold the data
    signal shift_register : std_logic_vector(OUTPUT_WIDTH-1 downto 0) := (others => '0');
    signal word_counter   : integer range 0 to NUM_WORDS := 0; -- Word counter
begin

    process(clk, reset, load, serial_in)
    begin
        if reset = '1' then
            -- Reset the shift register and counter
            shift_register <= (others => '0');
            word_counter <= 0;
        elsif rising_edge(clk) then
            if load = '1' then
                -- Shift the input data into the shift register
                shift_register <= shift_register(OUTPUT_WIDTH-INPUT_WIDTH-1 downto 0) & serial_in;
                word_counter <= word_counter + 1;
            end if;

            -- Reset counter when the shift register is full
            if word_counter = NUM_WORDS then
                word_counter <= 0;
            end if;
        end if;
    end process;

    -- Assign the shift register to the output
    parallel_out <= shift_register;

end Behavioral;
