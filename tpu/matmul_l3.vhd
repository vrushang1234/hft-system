library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.matmul_types.all;
use work.tpu_weights_pkg.all;

entity matmul_l3 is
    port (
        clk          : in  std_logic;
        activated_in : in  std_logic_vector(2047 downto 0); 
        l3_out       : out std_logic_vector(63 downto 0) 
    );
end entity;

architecture rtl of matmul_l3 is
    
    type act_array is array (0 to 63) of signed(31 downto 0);
    signal acts : act_array;

    type sum_array is array (0 to 1) of signed(31 downto 0);
    signal sums : sum_array := (others => (others => '0'));

begin
    unpack_proc: process(activated_in)
    begin
        for i in 0 to 63 loop
            acts(i) <= signed(activated_in((i+1)*32 - 1 downto i*32));
        end loop;
    end process;

    mac_proc: process(clk)
        variable temp_sum : signed(47 downto 0); 
        variable mult_res : signed(39 downto 0); -- 32-bit * 8-bit = 40-bits
    begin
        if rising_edge(clk) then
            for node in 0 to 1 loop
                temp_sum := (others => '0');
                for i in 0 to 63 loop
                    mult_res := acts(i) * L3_WEIGHTS(node, i);
                    
                    -- Scaling: Shift right by 7
                    temp_sum := temp_sum + resize(mult_res(39 downto 7), 48);
                end loop;
                sums(node) <= resize(temp_sum, 32);
            end loop;
        end if;
    end process;

    pack_proc: process(sums)
    begin
        for node in 0 to 1 loop
            l3_out((node+1)*32 - 1 downto node*32) <= std_logic_vector(sums(node));
        end loop;
    end process;

end architecture;