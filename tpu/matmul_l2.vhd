library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.matmul_types.all;
use work.tpu_weights_pkg.all;

entity matmul_l2 is
    port (
        clk          : in  std_logic;
        activated_in : in  std_logic_vector(2047 downto 0); -- 64 input neurons * 32-bits (Q2.29 format from Layer 1 Tanh)
        l2_out       : out std_logic_vector(2047 downto 0)  -- 64 output nodes * 32-bits (To feed into Layer 2 Tanh)
    );
end entity;

architecture rtl of matmul_l2 is
    
    -- Internal arrays
    type act_array is array (0 to 63) of signed(31 downto 0);
    signal acts : act_array;

    -- Array for the 64 output sums
    type sum_array is array (0 to 63) of signed(31 downto 0);
    signal sums : sum_array := (others => (others => '0'));

begin
    -- Unpack the 2048-bit input bus into 64 individual 32-bit signals
    unpack_proc: process(activated_in)
    begin
        for i in 0 to 63 loop
            acts(i) <= signed(activated_in((i+1)*32 - 1 downto i*32));
        end loop;
    end process;

    -- 64x64 Matrix Multiply-Accumulate logic
    mac_proc: process(clk)
        variable temp_sum : signed(47 downto 0); 
        variable mult_res : signed(39 downto 0); 
    begin
        if rising_edge(clk) then
            -- Loop through all 64 output neurons
            for node in 0 to 63 loop
                temp_sum := (others => '0');
                
                -- Multiply by all 64 incoming features
                for i in 0 to 63 loop
                    -- L2_WEIGHTS must now be the 64x64 matrix
                    mult_res := acts(i) * signed(L2_WEIGHTS(node, i));
                    
                    -- Scaling: Shift right by 7 because weights are Q0.7
                    temp_sum := temp_sum + resize(mult_res(39 downto 7), 48);
                end loop;
                sums(node) <= resize(temp_sum, 32);
            end loop;
        end if;
    end process;

    -- Pack the 64 32-bit results back into the 2048-bit output
    pack_proc: process(sums)
    begin
        for node in 0 to 63 loop
            l2_out((node+1)*32 - 1 downto node*32) <= std_logic_vector(sums(node));
        end loop;
    end process;

end architecture;