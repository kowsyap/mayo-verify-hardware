LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_textio.all;

LIBRARY std;
USE std.textio.all;

ENTITY mayo_verify_tb IS
END mayo_verify_tb;

ARCHITECTURE behavior OF mayo_verify_tb IS

    constant w: integer := 8;
    constant nibble:integer := 4;
    constant s_addr_len: integer := 6;  
    constant p_addr_len: integer := 13; 
    
    --mayo1
   constant param_m : integer := 64;
   constant param_n : integer := 66;
   constant param_k : integer := 9;
   constant fx: integer := 0;
   FILE inpFile: TEXT OPEN READ_MODE IS "input_gen_mayo1_file.txt";
    
    --mayo2
    -- constant param_m : integer := 64;
    -- constant param_n : integer := 78;
    -- constant param_k : integer := 4;
    -- constant fx: integer := 0;
    -- FILE inpFile: TEXT OPEN READ_MODE IS "input_gen_mayo2_file.txt";

    -- Inputs
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal sig : std_logic_vector(w-1 downto 0) := (others => '0');
    signal t : std_logic_vector(w-1 downto 0) := (others => '0');
    signal expanded_pk : std_logic_vector(w-1 downto 0) := (others => '0');
    -- signal SAddr: std_logic_vector(s_addr_len-1 downto 0) := (others => '0');
    -- signal PAddr: std_logic_vector(p_addr_len-1 downto 0) := (others => '0');
    -- signal TAddr: std_logic_vector(w-1 downto 0) := (others => '0');
    signal WrInit : std_logic := '0';
    signal write_done : std_logic := '0';
    signal calc : std_logic := '0';

    -- Outputs
    signal Done : std_logic;
    signal valid : std_logic;

    -- Clock period
    constant clk_period : time := 10 ns;
    constant initial_delay : time := 100 ns;

BEGIN

    -- Clock process definition
    clk <= not clk after clk_period/2;

    -- Uncomment the below code for Behavioral Simulation
    -- Comment out otherwise
    -- reset <= '1', '0' after clk_period;

    -- Uncomment the below code for Post-Synthesis and Post-Implementation Simulation
    -- Comment out otherwise
    reset <= '1' after initial_delay, '0' after initial_delay + clk_period;

    -- Instantiate the Design Under Test (DUT)
    dut: ENTITY work.mayo_verify
--    GENERIC MAP (
--        w=>w,
--        nibble=>nibble,
--        param_m=>param_m,
--        param_n=>param_n,
--        param_k=>param_k,
--        p_addr_len=>p_addr_len,
--        s_addr_len=>s_addr_len,
--        fx=>fx
--    )
    PORT MAP (
        clk => clk,
        reset => reset,
        WrInit => WrInit,
        calc => calc,
        sig => sig,
        t => t,
        expanded_pk => expanded_pk,
        -- SAddr => SAddr,
        -- PAddr => PAddr,
        -- TAddr => TAddr,
        write_done => write_done,
        valid => valid,
        Done => Done
    );

    -- Process to read test vectors from txt files
    readVec: PROCESS
        VARIABLE VectorLine: LINE;
        VARIABLE VectorValid: BOOLEAN;
        VARIABLE space: CHARACTER;
        VARIABLE vAddr: STD_LOGIC_VECTOR(17 DOWNTO 0);
        VARIABLE vPData: STD_LOGIC_VECTOR(w-1 DOWNTO 0);
        VARIABLE vSData: STD_LOGIC_VECTOR(w-1 DOWNTO 0);
        VARIABLE vTData: STD_LOGIC_VECTOR(w-1 DOWNTO 0);
        variable sThreshold : integer := 2**s_addr_len;
        variable tThreshold : integer := 2**w;
        variable RsltMsg: LINE;
        variable result_message: string(1 to 100);
    BEGIN
        -- WAIT FOR initial_delay;
        WAIT UNTIL reset = '0';

        -- Initialize WrInit signal to start loading inputs
        calc <= '0';
        WrInit <= '1';
        -- Read from all three input files in parallel
        WHILE NOT ENDFILE(inpFile) LOOP
            -- Read the signature vector
            readline(inpFile, VectorLine);
            hread(VectorLine, vPData, good => VectorValid);
            NEXT WHEN NOT VectorValid;
            --read(VectorLine, space);
            --hread(VectorLine, vPData);
            read(VectorLine, space);
            hread(VectorLine, vSData);
            read(VectorLine, space);
            hread(VectorLine, vTData);
            
           
            -- Assign values to signals
            expanded_pk <= vPData;
            sig <= vSData;
            t <= vTData;
            -- PAddr <= vAddr;
            -- if to_integer(unsigned(pAddr)) < sThreshold-1 then
            --     SAddr <= vAddr(s_addr_len-1 downto 0);
            -- else
            --     SAddr <= (others => '1');
            -- end if;
            -- if to_integer(unsigned(pAddr)) < tThreshold-1 then
            --     TAddr <= vAddr(w-1 downto 0);
            -- else
            --     TAddr <= (others => '1');
            -- end if;

            WAIT FOR clk_period;
            -- Clear the WrInit signal
            WrInit<='0';
            
        END LOOP;

        sig <= (others => '0');
        t <= (others => '0');
        expanded_pk <= (others => '0');
        -- PAddr <= (others => '0');
        -- SAddr <= (others => '0');
        -- TAddr <= (others => '0');
        WAIT UNTIL write_done = '1';
        WAIT FOR clk_period;

        -- Start the calculation
        calc <= '1';
        WAIT UNTIL Done = '1';
        WAIT FOR clk_period;
        calc <= '0';
        write(RsltMsg, string'("Time: "));
        write(RsltMsg, time'IMAGE(now));
        write(RsltMsg, string'(", Signature: "));
        if(valid = '1') then
            write(RsltMsg, string'("Valid"));
        elsif(valid = '0') then
            write(RsltMsg, string'("Invalid"));
        end if;
        writeline(output, RsltMsg);

        ASSERT FALSE
            REPORT "Simulation complete"
            SEVERITY NOTE;
        WAIT;
    END PROCESS;

END behavior;
