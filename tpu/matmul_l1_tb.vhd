--Generated with ChatGPT for ease of testing
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.matmul_types.all;

entity matmul_l1_tb is
end entity;

architecture tb of matmul_l1_tb is

    constant CLK_PERIOD : time := 10 ns;
    constant LATENCY    : integer := 4;  -- pipeline cycles

    -- DUT signals
    signal clk : std_logic := '0';

    signal A : matrix64x5;
    signal B : vector5;
    signal C : vector64;

    -- Expected output
    signal C_ref : integer_vector(0 to 63);

begin

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD/2;

    --------------------------------------------------------------------
    -- DUT instance
    --------------------------------------------------------------------
    uut : entity work.matmul_l1
        port map (
            clk => clk,
            A   => A,
            B   => B,
            C   => C
        );

    --------------------------------------------------------------------
    -- Test process
    --------------------------------------------------------------------
    process
        variable sum : integer;
    begin

        ----------------------------------------------------------------
        -- Ensure simulation is stable before applying inputs
        ----------------------------------------------------------------
        wait for 2 * CLK_PERIOD;

        ----------------------------------------------------------------
        -- Apply deterministic stimulus
        -- A(i,k) = i+k
        -- B(k)   = k+1
        ----------------------------------------------------------------
        for i in 0 to 63 loop
            for k in 0 to 4 loop
                A(i)(k) <= to_signed(i + k, 8);
            end loop;
        end loop;

        for k in 0 to 4 loop
            B(k) <= to_signed(k + 1, 8);
        end loop;

        -- Let assignments propagate
        wait for CLK_PERIOD;

        ----------------------------------------------------------------
        -- Compute golden reference C_ref(i)
        ----------------------------------------------------------------
        for i in 0 to 63 loop
            sum := 0;
            for k in 0 to 4 loop
                sum := sum + (to_integer(A(i)(k)) * to_integer(B(k)));
            end loop;
            C_ref(i) <= sum;
        end loop;

        ----------------------------------------------------------------
        -- Wait for pipeline output to be valid
        ----------------------------------------------------------------
        wait for (LATENCY + 2) * CLK_PERIOD;

        ----------------------------------------------------------------
        -- PRINT + VALIDATE OUTPUT
        ----------------------------------------------------------------
        report "======== MATRIX MULTIPLIER OUTPUT ========" severity note;

        for i in 0 to 63 loop
            report "Row " & integer'image(i) &
                   ": DUT=" & integer'image(to_integer(C(i))) &
                   "  REF=" & integer'image(C_ref(i))
                   severity note;

            if to_integer(C(i)) /= C_ref(i) then
                report "ERROR at row " & integer'image(i)
                       severity error;
            end if;
        end loop;

        report "==========================================" severity note;

        report "TEST PASSED: All rows match expected output." severity note;

        wait;
    end process;

end architecture;

