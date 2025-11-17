library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity matrix2x2_pipelined is
    port (
        clk : in std_logic;

        a, b, c, d : in  signed(7 downto 0);
        e, f, g, h : in  signed(7 downto 0);

        m11, m12, m21, m22 : out signed(15 downto 0)
    );
end entity;

architecture rtl of matrix2x2_pipelined is

    signal a1, b1, c1, d1 : signed(7 downto 0);
    signal e1, f1, g1, h1 : signed(7 downto 0);

    signal ae2, bg2, af2, bh2 : signed(15 downto 0);
    signal ce2, dg2, cf2, dh2 : signed(15 downto 0);

    signal ae3, bg3, af3, bh3 : signed(15 downto 0);
    signal ce3, dg3, cf3, dh3 : signed(15 downto 0);

    signal m11_int, m12_int, m21_int, m22_int : signed(15 downto 0);

begin

    stage1 : process(clk)
    begin
        if rising_edge(clk) then
            a1 <= a;  b1 <= b;  c1 <= c;  d1 <= d;
            e1 <= e;  f1 <= f;  g1 <= g;  h1 <= h;
        end if;
    end process;

    ae2 <= a1 * e1;
    bg2 <= b1 * g1;
    af2 <= a1 * f1;
    bh2 <= b1 * h1;

    ce2 <= c1 * e1;
    dg2 <= d1 * g1;
    cf2 <= c1 * f1;
    dh2 <= d1 * h1;

    stage3 : process(clk)
    begin
        if rising_edge(clk) then
            ae3 <= ae2;  bg3 <= bg2;
            af3 <= af2;  bh3 <= bh2;
            ce3 <= ce2;  dg3 <= dg2;
            cf3 <= cf2;  dh3 <= dh2;
        end if;
    end process;

    m11_int <= ae3 + bg3;
    m12_int <= af3 + bh3;
    m21_int <= ce3 + dg3;
    m22_int <= cf3 + dh3;

    stage4 : process(clk)
    begin
        if rising_edge(clk) then
            m11 <= m11_int;
            m12 <= m12_int;
            m21 <= m21_int;
            m22 <= m22_int;
        end if;
    end process;

end architecture;

