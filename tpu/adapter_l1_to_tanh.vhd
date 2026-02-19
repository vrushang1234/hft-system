library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.matmul_types.all;

entity adapter_l1_to_tanh is
    port(
        tpu_out      : in  vector64; -- 64 x 16-bit 
        tanh_in_flat : out std_logic_vector((64 * 32) - 1 downto 0)
    );
end entity;

architecture rtl of adapter_l1_to_tanh is
begin
    gen_flat: for i in 0 to 63 generate
        -- Sign extend 16-bit to 32-bit and shift to match Q2.29 format
        tanh_in_flat((i+1)*32 - 1 downto i*32) <= 
            std_logic_vector(resize(tpu_out(i), 32) sll 13); 
    end generate;
end architecture;