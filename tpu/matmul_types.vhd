library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package matmul_types is

    -- A row of 5 signed(7 downto 0)
    type row5 is array(0 to 4) of signed(7 downto 0);

    -- A 64×5 matrix: 64 rows of row5
    type matrix64x5 is array(0 to 63) of row5;

    -- B is a 5×1 vector
    type vector5 is array(0 to 4) of signed(7 downto 0);

    -- C is 64×1 result
    type vector64 is array(0 to 63) of signed(15 downto 0);

    -- Product row: 5 products (16-bit)
    type prod_row5 is array(0 to 4) of signed(15 downto 0);

    -- 64 rows of product-row
    type prod_matrix64x5 is array(0 to 63) of prod_row5;

    -- For Layer 2
    type weight_matrix_64x64 is array (0 to 63, 0 to 63) of signed(7 downto 0);
    
    -- For Layer 3
    type weight_matrix_2x64 is array (0 to 1, 0 to 63) of signed(7 downto 0);

end package;

