library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tpu_layer2_complete is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        -- 64 activated inputs coming from Layer 1
        activated_in   : in  std_logic_vector(2047 downto 0); 
        -- 64 activated outputs going to Layer 3
        layer_out_flat : out std_logic_vector(2047 downto 0)  
    );
end entity;

architecture struct of tpu_layer2_complete is

    -- 64x64 Matrix Multiplier Component
    component matmul_l2 is
        port (
            clk          : in  std_logic;
            activated_in : in  std_logic_vector(2047 downto 0);
            l2_out       : out std_logic_vector(2047 downto 0)
        );
    end component;

    component tanh_q32 is
        port (
            x : in  std_logic_vector(31 downto 0);
            y : out std_logic_vector(31 downto 0)
        );
    end component;

    -- The wire holding raw MatMul outputs before Tanh 
    signal l2_raw_flat : std_logic_vector(2047 downto 0);

begin

    -- Instantiate the 64x64 Matrix Multiplier
    u_matmul: matmul_l2
        port map (
            clk          => clk,
            activated_in => activated_in,
            l2_out       => l2_raw_flat
        );

    -- Generate 64 parallel Tanh activation modules
    gen_tanh: for i in 0 to 63 generate
        u_tanh: tanh_q32
            port map (
                x => l2_raw_flat((i+1)*32 - 1 downto i*32),
                y => layer_out_flat((i+1)*32 - 1 downto i*32)
            );
    end generate;

end architecture;