library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity partial_arr_mul_gf16 is
    generic (
        param_n : integer := 66
    );
    Port (
        a : in  STD_LOGIC_VECTOR (param_n*4-1 downto 0);
        s : in  STD_LOGIC_VECTOR (param_n*4-1 downto 0);
        result : out  STD_LOGIC_VECTOR (3 downto 0)
    );
end partial_arr_mul_gf16;

architecture Mixed of partial_arr_mul_gf16 is

    type arr_type is array (0 to param_n-1) of std_logic_vector(3 downto 0);
    signal intermediate_results: arr_type := (others =>(others=>'0'));
    
begin
    gen_mul: for i in 0 to param_n-1 generate
        mul_inst: entity work.mul_gf16
            port map (
                a => a(4*i+3 downto 4*i),
                b => s(4*i+3 downto 4*i),
                result => intermediate_results(i)
            );
    end generate;

    process(intermediate_results)
        variable temp_xor : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    begin
        temp_xor := intermediate_results(param_n-1);
        for i in 0 to param_n-2 loop
            temp_xor := temp_xor xor intermediate_results(i);
        end loop;
        result <= temp_xor;
    end process;

end Mixed;
