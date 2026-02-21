library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.matmul_types.all;

entity tpu_layer1_complete is
    port(
        clk : in std_logic;
        rst : in std_logic;
        
        -- Inputs: 5 Market Features (8-bit)
        features : in std_logic_vector(39 downto 0);
        
        -- Output: 64 activated neurons (Q2.29 format)
        layer_out_flat : out std_logic_vector((64 * 32) - 1 downto 0)
    );
end entity;

architecture struct of tpu_layer1_complete is

    signal features_array : vector5;

    -- Signals to connect MatMul -> Adapter -> Tanh
    signal matmul_result : vector64;
    signal tanh_input_flat : std_logic_vector((64 * 32) - 1 downto 0);
    
    component tanh_q32 is
        port (
            x : in  std_logic_vector(31 downto 0);
            y : out std_logic_vector(31 downto 0)
        );
    end component;

begin

    -- Map highest bits (the 7f) to index 0 (the non-zero weights)
    features_array(0) <= signed(features(39 downto 32)); 
    features_array(1) <= signed(features(31 downto 24));
    features_array(2) <= signed(features(23 downto 16));
    features_array(3) <= signed(features(15 downto 8));
    features_array(4) <= signed(features(7 downto 0));

    -- 1. The Matrix Multiplier (VHDL)
    u_matmul: entity work.matmul_l1
        port map(
            clk => clk,
            B   => features_array,
            C   => matmul_result
        );

    -- 2. The Adapter (VHDL)
    u_adapter: entity work.adapter_l1_to_tanh
        port map(
            tpu_out      => matmul_result,
            tanh_in_flat => tanh_input_flat
        );

    -- 3. The Tanh Activation Array (Verilog Wrapper)
    gen_activations: for i in 0 to 63 generate
        u_tanh: tanh_q32
            port map(
                x => tanh_input_flat((i+1)*32 - 1 downto i*32),
                y => layer_out_flat((i+1)*32 - 1 downto i*32)
            );
    end generate;

end architecture;