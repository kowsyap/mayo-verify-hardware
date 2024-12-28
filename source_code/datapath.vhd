library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

use work.UTILS_PKG.all;

--customizable for mayo1 and mayo2

entity datapath is
    generic(
        w:integer := 8;
        nibble:integer := 4;
        param_m : integer := 64;
        param_n : integer := 66;
        param_v : integer := 58;
        param_k : integer := 9;
        s_addr_len: integer := 6;  -- Max(log2(sig_bytes))
        p_addr_len: integer := 13;  -- Max(log2(param_m*param_n*param_n/2))
        fx: integer := 0
    );
    port (
        clk: in std_logic;
        reset: in std_logic;
        WrInit: in std_logic;
  	    calc: in std_logic;
        sig : in  std_logic_vector(w-1 downto 0); 
        expanded_pk : in  std_logic_vector(w-1 downto 0);
        t : in  std_logic_vector(w-1 downto 0);
        zi: out std_logic;  
        zj: out std_logic;    
        zl: out std_logic;    
        zrow: out std_logic;    
        zcol: out std_logic;    
        Li : in std_logic;
        Ei : in std_logic;
        Lj : in std_logic;
        Ej : in std_logic;
        Lrow : in std_logic;
        Erow : in std_logic;
        Lcol : in std_logic;
        Ecol : in std_logic;
        Ll : in std_logic;
        El : in std_logic;
        Ey : in std_logic;
        Ef : in std_logic;
        Rd : in std_logic;
        Wr : in std_logic;
        Arr : in std_logic;
        valid: out std_logic
    );
end datapath;

architecture mixed of datapath is

constant n_read_words: integer := param_n/2;
constant m_read_words: integer := param_m/2;
constant n_read_bits: integer :=n_read_words*w;
constant m_read_bits: integer :=m_read_words*w;

signal i: unsigned(nibble-1 downto 0);
signal j: unsigned(nibble-1 downto 0);
signal row: unsigned(w-1 downto 0);
signal col: unsigned(w-1 downto 0);
signal l: unsigned(w-1 downto 0);

signal s_addr_a: std_logic_vector(s_addr_len-1 downto 0);
signal s_addr_b: std_logic_vector(s_addr_len-1 downto 0);
signal p_addr: std_logic_vector(p_addr_len-1 downto 0);
signal t_addr: std_logic_vector(w-1 downto 0);

signal s_data_out_a: std_logic_vector(param_n*nibble-1 downto 0);
signal s_data_out_b: std_logic_vector(param_n*nibble-1 downto 0);
signal s_reg: std_logic_vector(param_n*nibble-1 downto 0);
signal p_data_out: std_logic_vector(param_n*nibble-1 downto 0);
signal p_reg: std_logic_vector(param_n*nibble-1 downto 0);

signal we_partial: std_logic;
signal we_u: std_logic;
signal we_t: std_logic;
signal we_s: std_logic;
signal we_p: std_logic;
signal Efifo: std_logic;

signal i_partial_mul_out: std_logic_vector(nibble-1 downto 0);
signal j_partial_mul_out: std_logic_vector(nibble-1 downto 0);
signal mul_out: std_logic_vector(nibble-1 downto 0);

signal int_reg_a: std_logic_vector(param_n*nibble-1 downto 0);
signal int_reg_b: std_logic_vector(param_n*nibble-1 downto 0);
signal int_a: std_logic_vector(param_n*nibble-1 downto 0);
signal int_b: std_logic_vector(param_n*nibble-1 downto 0);
signal s_partial_a: std_logic_vector(param_n*nibble-1 downto 0);
signal s_partial_b: std_logic_vector(param_n*nibble-1 downto 0);
signal eu: std_logic_vector(param_m*nibble-1 downto 0);
signal u_reg: std_logic_vector(param_m*nibble-1 downto 0);
signal y_reg: std_logic_vector(param_m*nibble-1 downto 0);
signal y_temp: std_logic_vector(param_m*nibble-1 downto 0);
signal t_reg: std_logic_vector(param_m*nibble-1 downto 0);

begin

    we_partial <= '1' when Erow='1' else '0';
    we_u <= '1' when Arr='1' else '0';
    we_t <= (Ef or WrInit) when (calc='0' and col<to_unsigned(m_read_words-1,w) and row=to_unsigned(0,w) and l=to_unsigned(0,w)) else '0';
    we_s <= Wr when (calc='0' and l=to_unsigned(0,w) and row<to_unsigned(param_m,w)) else '0';
    we_p <= Wr when calc='0' else '0';
    Efifo <= WrInit or Ef;

    s_addr_a <= std_logic_vector(resize(row,s_addr_a'length)) when calc = '0' else std_logic_vector(resize(i, s_addr_a'length));
    s_addr_b <= std_logic_vector(resize(j,s_addr_b'length));
    p_addr <= std_logic_vector(resize(l*to_unsigned(param_n,w)+row,p_addr'length));

    p_dpram_inst: entity work.RAM 
        generic map(w=>n_read_bits, k=>p_addr_len)
        port map(
            DINA => p_reg,
            DINB => (others => '0'),
            DOUTA => p_data_out,
            DOUTB => open,
            ADDRA => p_addr,
            ADDRB => (others => '0'),
            WEA => we_p,
            WEB => '0',
            clk => clk
        );

    s_dpram_inst: entity work.RAM 
        generic map(w=>n_read_bits, k=>s_addr_len)
        port map(
            DINA => s_reg,
            DINB => (others => '0'),
            DOUTA => s_data_out_a,
            DOUTB => s_data_out_b,
            ADDRA => s_addr_a,
            ADDRB => s_addr_b,
            WEA => we_s,
            WEB => '0',
            clk => clk
        );

    p_fifo_inst: entity work.SIPO_FIFO
         generic map(INPUT_WIDTH=>w,OUTPUT_WIDTH=>n_read_bits)
         port map(
             clk => clk,
             reset => reset,
             serial_in => expanded_pk,
             load => Efifo,
             parallel_out => p_reg
         );

    s_fifo_inst: entity work.SIPO_FIFO
         generic map(INPUT_WIDTH=>w,OUTPUT_WIDTH=>n_read_bits)
         port map(
             clk => clk,
             reset => reset,
             serial_in => sig,
             load => Efifo,
             parallel_out => s_reg
         );

    t_fifo_inst: entity work.SIPO_FIFO
         generic map(INPUT_WIDTH=>w,OUTPUT_WIDTH=>m_read_bits)
         port map(
             clk => clk,
             reset => reset,
             serial_in => t,
             load => we_t,
             parallel_out => t_reg
         );

    u_fifo_inst: entity work.SIPO_FIFO
         generic map(INPUT_WIDTH=>nibble,OUTPUT_WIDTH=>m_read_bits)
         port map(
             clk => clk,
             reset => reset,
             serial_in => mul_out,
             load => we_u,
             parallel_out => u_reg
         );

    i_partial_fifo_inst: entity work.SIPO_FIFO
         generic map(INPUT_WIDTH=>nibble,OUTPUT_WIDTH=>n_read_bits)
         port map(
             clk => clk,
             reset => reset,
             serial_in => i_partial_mul_out,
             load => we_partial,
             parallel_out => int_reg_a
         );

    j_partial_fifo_inst: entity work.SIPO_FIFO
         generic map(INPUT_WIDTH=>nibble,OUTPUT_WIDTH=>n_read_bits)
         port map(
             clk => clk,
             reset => reset,
             serial_in => j_partial_mul_out,
             load => we_partial,
             parallel_out => int_reg_b
         );

    partial_mul_inst1: entity work.partial_arr_mul_gf16
        generic map(param_n=>param_n)
        port map(
            a => int_a,
            s => s_partial_a,
            result => i_partial_mul_out
        );
    
    partial_mul_inst2: entity work.partial_arr_mul_gf16
        generic map(param_n=>param_n)
        port map(
            a => int_b,
            s => s_partial_b,
            result => j_partial_mul_out
        );

    mod_fx_inst: entity work.mod_fx64
        generic map(param_m=>param_m,fx=>fx)
        port map(
            a => u_reg,
            result => eu
        );

    xor_inst: entity work.add_gf16
        generic map(param_m=>param_m)
        port map(
            a => eu,
            b => y_reg,
            result => y_temp
        );

    counterI: process(clk)
    begin
        if rising_edge(clk) then
            if Li = '1' then
                i <= (others => '0');
            elsif Ei = '1' then
                i <= i + 1;
            end if;          
        end if;
    end process;

    counterJ: process(clk)
    begin
        if rising_edge(clk) then
            if Lj = '1' then
                j <= to_unsigned(param_k-1, nibble);
            elsif Ej = '1' then
                j <= j - 1;
            end if;
        end if;
    end process;

    counterRow: process(clk)
    begin
        if rising_edge(clk) then
            if Lrow = '1' then
                row <= (others => '0');
            elsif Erow = '1' then
                row <= row + 1;
            end if; 
        end if;
    end process;

    counterCol: process(clk)
    begin
        if rising_edge(clk) then
            if Lcol = '1' then
                col <= (others => '0');
            elsif Ecol = '1' then
                col <= col + 1;
            end if; 
        end if;
    end process;

    counterL: process(clk)
    begin
        if rising_edge(clk) then
            if Ll = '1' then
                l <= (others => '0');
            elsif El = '1' then
                l <= l + 1;
            end if;          
        end if;
    end process;

    y_reg_inst : PROCESS(clk, reset)
    begin
        if reset = '1' then
            y_reg <= (others => '0');
        elsif rising_edge(clk) then
            if Ey = '1' then
                y_reg <= y_temp;
            end if;
        end if;
    end process;

    partial_data_assign: process(clk,Arr,int_reg_a,int_reg_b,s_data_out_a,s_data_out_b,p_data_out)
    begin
        if(Arr='1') then
            int_a <= int_reg_a;
            int_b <= int_reg_b;
            s_partial_a <= s_data_out_b;
            s_partial_b <= s_data_out_a;
        else
            int_a <= p_data_out;
            int_b <= p_data_out;
            s_partial_a <= s_data_out_a;
            s_partial_b <= s_data_out_b;
        end if;
    end process;

    mul_out <= i_partial_mul_out when j=i else (i_partial_mul_out xor j_partial_mul_out);

    zi <= '1' when i = to_unsigned(param_k-1, nibble) else '0';
    zj <= '1' when j = i else '0';
    zl <= '1' when l = to_unsigned(param_m-1, w) else '0';
    zrow <= '1' when row = to_unsigned(param_n-1, w) else '0';
    zcol <= '1' when col = to_unsigned(n_read_words-1, w) else '0';

    valid <= '1' when (Rd = '1' and y_reg = t_reg) else '0' when (Rd = '1' and y_reg /= t_reg) else 'Z';

end mixed;

