library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mul_gf16 is
    Port (
        a : in  STD_LOGIC_VECTOR (3 downto 0);
        b : in  STD_LOGIC_VECTOR (3 downto 0);
        result : out  STD_LOGIC_VECTOR (3 downto 0)
    );
end mul_gf16;

architecture Behavioral of mul_gf16 is
    signal product : STD_LOGIC_VECTOR (7 downto 0);
    signal intermediate1 : STD_LOGIC_VECTOR (7 downto 0);
    signal intermediate2 : STD_LOGIC_VECTOR (7 downto 0);
    signal intermediate3 : STD_LOGIC_VECTOR (7 downto 0);
    signal intermediate4 : STD_LOGIC_VECTOR (7 downto 0);
begin
    product(0) <= (a(0) and b(0));
    product(1) <= (a(0) and b(1)) xor (a(1) and b(0));
    product(2) <= (a(0) and b(2)) xor (a(1) and b(1)) xor (a(2) and b(0));
    product(3) <= (a(0) and b(3)) xor (a(1) and b(2)) xor (a(2) and b(1)) xor (a(3) and b(0));
    product(4) <= (a(1) and b(3)) xor (a(2) and b(2)) xor (a(3) and b(1));
    product(5) <= (a(2) and b(3)) xor (a(3) and b(2));
    product(6) <= (a(3) and b(3));
    product(7) <= '0';
    
    
    intermediate1 <= product xor "10011000" when product(7)='1' else product;
    intermediate2 <= intermediate1 xor "01001100" when intermediate1(6)='1' else intermediate1;
    intermediate3 <= intermediate2 xor "00100110" when intermediate2(5)='1' else intermediate2;
    intermediate4 <= intermediate3 xor "00010011" when intermediate3(4)='1' else intermediate3;
    result <= intermediate4(3 downto 0);
    
end Behavioral;
