library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mod_fx64 is
    generic(
        param_m : integer := 64;
        fx : integer := 0
    );
    Port (
        a         : in  STD_LOGIC_VECTOR(param_m*4-1 downto 0);
        result    : out STD_LOGIC_VECTOR(param_m*4-1 downto 0)
    );
end mod_fx64;

architecture Mixed of mod_fx64 is 
    signal temp: std_logic_vector(param_m*4-1 downto 0);
    type fx_table is array (0 to 2, 0 to 4) of STD_LOGIC_VECTOR(3 downto 0); 
    type res_table is array (0 to 4) of STD_LOGIC_VECTOR(3 downto 0); 
    constant lookup_table : fx_table := (
        ("1000","0000","0010","1000","0000"),
        ("0010","0010","0000","0010","0000"),
        ("0100","1000","0000","0100","0010")
    );
    signal intermediate_results: res_table := (others =>(others=>'0'));
begin

    gen_mul: for i in 0 to 4 generate
        mul_inst: entity work.mul_gf16
            port map (
                a => a(param_m*4-1 downto (param_m-1)*4),
                b => lookup_table(fx,i),
                result => intermediate_results(i)
            );
    end generate;

    temp <= a((param_m-1)*4-1 downto 0) & "0000";

    process(intermediate_results, temp)
        variable temp_xor :  STD_LOGIC_VECTOR(param_m*4-1 downto 0) := (others => '0');
    begin
        temp_xor := temp;
        for i in 0 to 4 loop
            temp_xor(4*i+3 downto 4*i) := temp_xor(4*i+3 downto 4*i) xor intermediate_results(i);
        end loop;
        result <= temp_xor;
    end process;

end Mixed;
