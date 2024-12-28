library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mayo_verify is
    generic (
        w:integer := 8;
        nibble:integer := 4;
        param_m : integer := 64;
        param_n : integer := 66;
        param_k : integer := 9;
        s_addr_len: integer := 6;  -- log2(param_m*param_n/2)
        p_addr_len: integer := 13;  -- log2(param_m*param_n*param_n/2)
        fx: integer := 0
    );
    port (
        clk : in  std_logic;
        reset : in std_logic;
        WrInit: in std_logic; -- read sig, expanded_pk,t when wrInit is '1'
  	    calc: in std_logic; --- calculate when calc is '1'
        sig : in  std_logic_vector(w-1 downto 0); -- Signature data
        expanded_pk : in  std_logic_vector(w-1 downto 0); -- Expanded public key
        t : in  std_logic_vector(w-1 downto 0); -- Target value
		-- SAddr: in std_logic_vector(s_addr_len-1 downto 0);
		-- PAddr: in std_logic_vector(p_addr_len-1 downto 0);
		-- TAddr: in std_logic_vector(w-1 downto 0);
		write_done : out std_logic;
        valid : out std_logic;  -- Output: '1' if signature is valid, '0' otherwise
        Done: out std_logic -- Output: '1' if calculation completed
    );
end entity mayo_verify;


architecture structural of mayo_verify is

-- status signals
signal zi : std_logic;
signal zj : std_logic;
signal zl : std_logic;
signal zrow : std_logic;
signal zcol : std_logic;

--control signals
signal Li : std_logic;
signal Ei : std_logic;
signal Lj : std_logic;
signal Ej : std_logic;
signal Lrow : std_logic;
signal Erow : std_logic;
signal Lcol : std_logic;
signal Ecol : std_logic;
signal Ll : std_logic;
signal El : std_logic;
signal Ey : std_logic;
signal Ef : std_logic;
signal Rd : std_logic;
signal Wr : std_logic;
signal Arr : std_logic;

begin

mayo_verify_datapath: entity work.datapath2(mixed)
generic map (
	w => w,
	nibble => nibble,
    param_m => param_m,
	param_n => param_n,
	param_k => param_k,
	s_addr_len => s_addr_len,
	p_addr_len => p_addr_len,
	fx => fx
)
port map(
  	clk => clk,
    reset => reset,
  	WrInit => WrInit,
  	calc => calc,
  	sig => sig,
  	expanded_pk => expanded_pk,
--	SAddr=>SAddr,
--	PAddr=>PAddr,
--	TAddr=>TAddr,
  	t => t,
  	zi => zi,
  	zj => zj,
  	zl => zl,
  	zrow => zrow,
  	zcol => zcol,
  	Li => Li,
  	Ei => Ei,
  	Lj => Lj,
  	Ej => Ej,
  	Lrow => Lrow,
  	Erow => Erow,
  	Lcol => Lcol,
  	Ecol => Ecol,
  	Ll => Ll,
  	El => El,
  	Ey => Ey,
	Ef => Ef,
    Rd => Rd,
	Wr => Wr,
	Arr => Arr,
    valid => valid
);

mayo_verify_controller: entity work.controller2(behavioral)
port map(
  	clk => clk,
  	reset => reset,
  	calc => calc,
	WrInit => WrInit,
  	zi => zi, 
  	zj => zj,    
  	zl => zl,    
    zrow => zrow,
	zcol => zcol,
  	Li => Li,
  	Ei => Ei,
  	Lj => Lj,
  	Ej => Ej,
  	Lrow => Lrow,
  	Erow => Erow,
	Lcol => Lcol,
  	Ecol => Ecol,
  	Ll => Ll,
  	El => El,
  	Ey => Ey,
  	Ef => Ef,
	Arr => Arr,
	Rd => Rd,
	Wr => Wr,
	write_done => write_done,
	Done => Done
);

end structural;
