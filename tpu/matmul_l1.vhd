library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.matmul_types.all;

entity matmul_l1 is
    port(
        clk : in std_logic;
        A   : in matrix64x5;
        B   : in vector5;
        C   : out vector64
    );
end entity;

architecture rtl of matmul_l1 is

    signal A1 : matrix64x5;
    signal B1 : vector5;

    signal P2 : prod_matrix64x5;

    signal P3 : prod_matrix64x5;

    signal C_int : vector64;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            A1 <= A;
            B1 <= B;
        end if;
    end process;

    mult_gen : for i in 0 to 63 generate
        row_mult : for k in 0 to 4 generate
            P2(i)(k) <= A1(i)(k) * B1(k);
        end generate row_mult;
    end generate mult_gen;

    process(clk)
    begin
        if rising_edge(clk) then
            P3 <= P2;
        end if;
    end process;

    sum_gen : for i in 0 to 63 generate
        C_int(i) <= P3(i)(0) + P3(i)(1) + P3(i)(2) + P3(i)(3) + P3(i)(4);
    end generate sum_gen;
    
    process(clk)
    begin
        if rising_edge(clk) then
            C <= C_int;
        end if;
    end process;

end architecture;

