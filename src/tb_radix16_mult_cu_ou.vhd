library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_radix16_mult is
end entity;

architecture sim of tb_radix16_mult is
    constant A_WIDTH : natural := 8;
    constant B_WIDTH : natural := 8;
    constant P_WIDTH : natural := A_WIDTH + B_WIDTH;

    signal clk   : std_logic := '0';
    signal rst   : std_logic := '1';
    signal start : std_logic := '0';
    signal A_in  : std_logic_vector(A_WIDTH-1 downto 0);
    signal B_in  : std_logic_vector(B_WIDTH-1 downto 0);
    signal done  : std_logic;
    signal P_out : std_logic_vector(P_WIDTH-1 downto 0);

begin
    dut : entity work.radix16_mult_top
        port map (
            clk   => clk,
            rst   => rst,
            start => start,
            A_in  => A_in,
            B_in  => B_in,
            done  => done,
            P_out => P_out
        );

    clk <= not clk after 5 ns;

    process
        procedure apply_vec(a_val: unsigned; b_val: unsigned) is
        begin
            A_in <= std_logic_vector(a_val);
            B_in <= std_logic_vector(b_val);
            start <= '1';
            wait for 10 ns;
            start <= '0';
            wait until done = '1';
            wait for 10 ns;
        end procedure;
    begin
        wait for 20 ns;
        rst <= '0';

        apply_vec(to_unsigned(11, A_WIDTH), to_unsigned(11, B_WIDTH));
        apply_vec(to_unsigned(0, A_WIDTH),  to_unsigned(0, B_WIDTH));
        apply_vec(to_unsigned(255, A_WIDTH), to_unsigned(1, B_WIDTH));

        for i in 1 to 25 loop
            apply_vec(to_unsigned(i*7 mod 256, A_WIDTH),
                      to_unsigned(i*5 mod 256 , B_WIDTH));
        end loop;

        wait;
    end process;
end architecture;