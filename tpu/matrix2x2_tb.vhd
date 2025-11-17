-- Generated with ChatGPT for ease of testing
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matrix2x2_tb is
end;

architecture sim of matrix2x2_tb is

    signal clk : std_logic := '0';

    signal a,b,c,d,e,f,g,h : signed(7 downto 0);
    signal m11,m12,m21,m22 : signed(15 downto 0);

begin

    -- Clock generator (finite)
    clock_proc : process
    begin
        while now < 120 ns loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;

        wait;  -- stops the clock process
    end process;

    uut: entity work.matrix2x2_pipelined
        port map(
            clk => clk,
            a => a, b => b, c => c, d => d,
            e => e, f => f, g => g, h => h,
            m11 => m11, m12 => m12, m21 => m21, m22 => m22
        );

    -- Stimulus + printing
    stimulus_proc : process
    begin
        a <= to_signed(1,8);
        b <= to_signed(2,8);
        c <= to_signed(3,8);
        d <= to_signed(4,8);

        e <= to_signed(5,8);
        f <= to_signed(6,8);
        g <= to_signed(7,8);
        h <= to_signed(8,8);

        wait for 60 ns;

        report "Output matrix:";
        report "m11 = " & integer'image(to_integer(m11));
        report "m12 = " & integer'image(to_integer(m12));
        report "m21 = " & integer'image(to_integer(m21));
        report "m22 = " & integer'image(to_integer(m22));

        wait;  -- stop this process
    end process;

end architecture;

