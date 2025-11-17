library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add2 is
    port(
        a : in  signed(15 downto 0);
        b : in  signed(15 downto 0);
        y : out signed(15 downto 0)
    );
end;

architecture rtl of add2 is
begin
    y <= a + b;
end;

