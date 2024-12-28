library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity add_gf16 is
    generic (
        param_m : integer := 64
    );
    Port (
        a : in  STD_LOGIC_VECTOR (param_m*4-1 downto 0);
        b : in  STD_LOGIC_VECTOR (param_m*4-1 downto 0);
        result : out  STD_LOGIC_VECTOR (param_m*4-1 downto 0)
    );
end add_gf16;

architecture Behavioral of add_gf16 is
begin

    result <= a xor b;
    
end Behavioral;
