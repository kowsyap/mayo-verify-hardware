library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity controller is
    port (
        clk : in std_logic;
        reset : in std_logic;
        calc : in std_logic;
        WrInit : in std_logic;
        zi : in std_logic;
        zj : in std_logic;
        zl : in std_logic;
        zrow : in std_logic;
        zcol : in std_logic;
        Li : out std_logic;
        Ei : out std_logic;
        Lj : out std_logic;
        Ej : out std_logic;
        Lrow : out std_logic;
        Erow : out std_logic;
        Lcol : out std_logic;
        Ecol : out std_logic;
        Ll : out std_logic;
        El : out std_logic;
        Ey : out std_logic;
        Ef : out std_logic;
        Arr: out std_logic;
        Rd : out std_logic;
        write_done : out std_logic;
        Wr : out std_logic;
        Done : out std_logic
    );
end controller;

architecture behavioral of controller is

TYPE state is (S0,S1,S2,S3,S4,S5,S6,S7,W1,W2);
signal state_reg, state_next: state;

begin

    reg: process(clk, reset)
    begin
        if reset = '1' then
            state_reg <= S0;
        elsif rising_edge(clk) then
            state_reg <= state_next;
        end if;
    end process;

    logic: process(state_reg, calc, zi, zj, zrow, zcol, zl, WrInit)
    begin

        state_next <= state_reg;
        Li <= '0';
        Ei <= '0';
        Lj <= '0';
        Ej <= '0';
        Lrow <= '0';
        Erow <= '0';
        Lcol <= '0';
        Ecol <= '0';
        Ll <= '0';
        El <= '0';
        Ey <= '0';
        Ef <= '0';
        Arr <= '0';
        Wr <= '0';
        Rd <= '0';
        Done <= '0';
        write_done <= '0';
        CASE state_reg is
            when S0 =>
                Li <= '1';
                Ll <= '1';
                Lrow <= '1';
                Lcol <= '1';
                if calc = '1' then
                    state_next <= S1;
                else
                    if WrInit = '1' then
                        state_next <= W1;
                    else
                        state_next <= S0;
                    end if;
                end if;
            when W1 =>
                Ef <= '1';
                if zcol = '0' then
                    Ecol <= '1';
                    state_next <= W1;
                else
                    Lcol <= '1';
                    Wr <= '1';
                    if zrow = '0' then
                        Erow <= '1';
                        state_next <= W1;
                    else
                        Lrow <= '1';
                        if zl = '0' then
                            El <= '1';
                            state_next <= W1;
                        else
                            state_next <= W2;
                        end if;
                    end if;
                end if;
            when W2 =>
                write_done <= '1';
                if calc = '1' then
                    state_next <= S0;
                else
                    state_next <= W2;
                end if;
            when S1 =>
                Lj <= '1';
                state_next <= S2;
            when S2 =>
                Ll <= '1';
                state_next <= S3;
            when S3 =>
                Lrow <= '1';
                state_next <= S4;
            when S4 =>
                Erow <= '1';
                if zrow = '0' then
                    state_next <= S4;
                else
                    state_next <= S5;
                end if;
            when S5 =>
                Arr <= '1';
                if zl = '0' then
                    El <= '1';
                    state_next <= S3;
                else
                    state_next <= S6;
                end if;
            when S6 =>
                Ey <= '1';
                if zj = '0' then
                    Ej <= '1';
                    state_next <= S2;
                elsif zi = '0' then
                    Ei <= '1';
                    state_next <= S1;
                else
                    state_next <= S7;
                end if;
            when S7 =>
                Rd <= '1';
                Done <= '1';
                if calc = '1' then
                    state_next <= S7;
                else
                    state_next <= S0;
                end if;
        end case;
    end process;

end behavioral;