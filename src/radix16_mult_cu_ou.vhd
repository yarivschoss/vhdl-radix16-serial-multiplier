library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package mult_pkg is
    constant A_WIDTH : natural := 8;
    constant B_WIDTH : natural := 8;
    constant P_WIDTH : natural := A_WIDTH + B_WIDTH;
    constant N_CYCLES : natural := B_WIDTH / 4;
end package;

library ieee;
use ieee.std_logic_1164.all;
use work.mult_pkg.all;

entity control_unit is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        start       : in  std_logic;
        cnt_max     : in  std_logic;
        load_inputs : out std_logic;
        calc_enable : out std_logic;
        done        : out std_logic
    );
end entity;

architecture rtl of control_unit is
    type state_t is (IDLE, LOAD, CALC, FINISHED);
    signal state : state_t := IDLE;
begin
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        state <= LOAD;
                    end if;

                when LOAD =>
                    state <= CALC;

                when CALC =>
                    if cnt_max = '1' then
                        state <= FINISHED;
                    end if;

                when FINISHED =>
                    state <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

    load_inputs <= '1' when state = LOAD else '0';
    calc_enable <= '1' when state = CALC else '0';
    done <= '1' when state = FINISHED else '0';
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.mult_pkg.all;

entity operational_unit is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        A_in        : in  std_logic_vector(A_WIDTH-1 downto 0);
        B_in        : in  std_logic_vector(B_WIDTH-1 downto 0);
        load_inputs : in  std_logic;
        calc_enable : in  std_logic;
        cnt_max     : out std_logic;
        P_out       : out std_logic_vector(P_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of operational_unit is
    signal RA   : unsigned(A_WIDTH-1 downto 0) := (others => '0');
    signal RB   : unsigned(B_WIDTH-1 downto 0) := (others => '0');
    signal ACC  : unsigned(P_WIDTH-1 downto 0) := (others => '0');
    signal cnt  : integer range 0 to N_CYCLES  := 0;
begin
    cnt_max <= '1' when cnt = N_CYCLES - 1 else '0';
    P_out <= std_logic_vector(ACC);

    process(clk, rst)
        variable nibble    : unsigned(3 downto 0);
        variable part_prod : unsigned(P_WIDTH-1 downto 0);
        variable shift_amt : natural;
    begin
        if rst = '1' then
            RA  <= (others => '0');
            RB  <= (others => '0');
            ACC <= (others => '0');
            cnt <= 0;
        elsif rising_edge(clk) then
            if load_inputs = '1' then
                RA  <= unsigned(A_in);
                RB  <= unsigned(B_in);
                ACC <= (others => '0');
                cnt <= 0;
            elsif calc_enable = '1' then
                nibble := RB(3 downto 0);
                shift_amt := cnt * 4;
                
                part_prod := (others => '0');
                
                if nibble(0) = '1' then
                    part_prod := part_prod + resize(RA, P_WIDTH);
                end if;
                
                if nibble(1) = '1' then
                    part_prod := part_prod + (resize(RA, P_WIDTH) sll 1);
                end if;
                
                if nibble(2) = '1' then
                    part_prod := part_prod + (resize(RA, P_WIDTH) sll 2);
                end if;
                
                if nibble(3) = '1' then
                    part_prod := part_prod + (resize(RA, P_WIDTH) sll 3);
                end if;
                
                part_prod := part_prod sll shift_amt;
                
                ACC <= ACC + part_prod;
                
                RB <= RB srl 4;
                
                cnt <= cnt + 1;
            end if;
        end if;
    end process;
end architecture;

library ieee;
use ieee.std_logic_1164.all;
use work.mult_pkg.all;

entity radix16_mult_top is
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        start : in  std_logic;
        A_in  : in  std_logic_vector(A_WIDTH-1 downto 0);
        B_in  : in  std_logic_vector(B_WIDTH-1 downto 0);
        done  : out std_logic;
        P_out : out std_logic_vector(P_WIDTH-1 downto 0)
    );
end entity;

architecture str of radix16_mult_top is
    signal load_inputs_s : std_logic;
    signal calc_enable_s : std_logic;
    signal cnt_max_s     : std_logic;
begin
    CU: entity work.control_unit
        port map (
            clk         => clk,
            rst         => rst,
            start       => start,
            cnt_max     => cnt_max_s,
            load_inputs => load_inputs_s,
            calc_enable => calc_enable_s,
            done        => done
        );

    OU: entity work.operational_unit
        port map (
            clk         => clk,
            rst         => rst,
            A_in        => A_in,
            B_in        => B_in,
            load_inputs => load_inputs_s,
            calc_enable => calc_enable_s,
            cnt_max     => cnt_max_s,
            P_out       => P_out
        );
end architecture;