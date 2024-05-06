library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity life_counter_disp is
    port (
    pixel_x : in STD_LOGIC_VECTOR (9 downto 0);
    pixel_y : in STD_LOGIC_VECTOR (9 downto 0);
    life_cnt: in STD_LOGIC_VECTOR (1 downto 0);
    sq_life_cnter_on_output: out std_logic;
    graph_rgb: out std_logic_vector(2 downto 0));
end life_counter_disp;

architecture Behavioral of life_counter_disp is
    -- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);
    -- signal that stores the unsigned 'hit_cnt' value
    signal life_cnter: unsigned(1 downto 0);
    -- hit cnter value color
    signal life_cnter_rgb: std_logic_vector(2 downto 0);

    -- Square cnter size and boundaries
    constant CNT_SIZE: integer := 16;
    constant LIFE_CNT_X_L: integer := 60;
    constant LIFE_CNT_X_R: integer:= LIFE_CNT_X_L + CNT_SIZE - 1;
    constant LIFE_CNT_Y_T: integer := 60;
    constant LIFE_CNT_Y_B: integer:= LIFE_CNT_Y_T + CNT_SIZE - 1;

    -- new data type to store the 16x16 rom images of counter values 0-7
    type life_counter_type is array(0 to 15) of std_logic_vector(15 downto 0);
    -- signal that stores the rom image of the current cnter value
    signal life_cnter_rom_current: life_counter_type;
    -- constant rom images for 0-7
    constant LIFE_CNTER_ROM_0: life_counter_type:= (
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111100000011111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "1111000000001111",
        "1111100000011111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111"
    );

    --- Write your own VHDL code below:
    --- Initialize images for other CNTER_ROM VALUES (1-7)

    constant LIFE_CNTER_ROM_1: life_counter_type:= (
        "0000001111111000",
        "0000001111111100",
        "0000001111011110",
        "0000001111001111",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "0000001111000000",
        "1111111111111111",
        "1111111111111111"
    );

    constant LIFE_CNTER_ROM_2: life_counter_type:= (
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111000000000",
        "1111111000000000",
        "1111111000000000",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "0000000001111111",
        "0000000001111111",
        "0000000001111111",
        "0000000001111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111"
    );

    constant LIFE_CNTER_ROM_3: life_counter_type:= (
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111110000000000",
        "1111110000000000",
        "1111110000000000",
        "1111110000000000",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111110000000000",
        "1111110000000000",
        "1111110000000000",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111"
    );


    -- signals to store the row and column indexes of the current cnter rom
    signal rom_life_addr_cnter, rom_life_col_cnter: unsigned(3 downto 0);
    -- signals to store the row data and the rom_bit
    signal rom_life_data_cnter: std_logic_vector(15 downto 0);
    signal rom_life_bit_cnter: std_logic;
    -- signal to indicate if scan coord is within the square area of
    --- the counter
    signal sq_life_cnter_on: std_logic;
    -- signals to indicate if the image of current cnter value is
    --- displayed
    signal life_cnter_cur_val_on: std_logic;

    -- signals that store unsigned values of the square counter boundaries
    signal life_cnt_y_t_u: unsigned(9 downto 0);
    signal life_cnt_x_l_u: unsigned(9 downto 0);

    begin
    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);
    life_cnter <= unsigned(life_cnt);
    -- Write your VHDL code below:
    -- Assert ‘sq_hit_cnter_on’ by checking if the pixel is within the area
    --- of the square hit_counter;
    -- Note: the square area is a fixed area shared by 8 counter values
    --- Write your VHDL code: complete “with select” statement below:

    -- Assert ‘sq_hit_cnter_on’ by checking if the pixel is within the area of the square hit_counter;
    sq_life_cnter_on <= '1' when (LIFE_CNT_X_L <= pix_x) and 
                                (pix_x <= LIFE_CNT_X_R) and 
                                (LIFE_CNT_Y_T <= pix_y) and 
                                (pix_y <= LIFE_CNT_Y_B) else '0';

    --- Here we use a signal ‘cnter_rom_current’ to store the actual
    --- ROM image to be displayed which depends on the current cnter value.
    -- Assign the corresponding ROM image constant to ‘cnter_rom_current’
    --- depending on the value of ‘hit_cnter’
    with to_integer(life_cnter) select
    life_cnter_rom_current <=
        LIFE_CNTER_ROM_0 when 0,
        LIFE_CNTER_ROM_1 when 1,
        LIFE_CNTER_ROM_2 when 2,
        LIFE_CNTER_ROM_3 when others; -- Handles the hit counter value 3 and other potential higher ones

    -- type conversion to unsigned values
    life_cnt_y_t_u <= to_unsigned(LIFE_CNT_Y_T, 10);
    life_cnt_x_l_u <= to_unsigned(LIFE_CNT_X_L, 10);
    -- Obtain row and col indexes
    rom_life_addr_cnter <= pix_y(3 downto 0) - life_cnt_y_t_u(3 downto 0);
    rom_life_col_cnter <= pix_x(3 downto 0) - life_cnt_x_l_u(3 downto 0);
    -- map scan coord to rom_bit using addr/col for current cnter value;
    rom_life_data_cnter <= life_cnter_rom_current(to_integer(rom_life_addr_cnter));
    rom_life_bit_cnter <= rom_life_data_cnter(to_integer(rom_life_col_cnter));

    --- Write your VHDL code below:
    life_cnter_cur_val_on <= '1' when (sq_life_cnter_on = '1') and
                                    (rom_life_bit_cnter = '1') else '0';
    -- assert ‘hit_cnter_cur_val_on’ by checking
    --- ‘sq_hit_cnter_on’ and ‘rom_bit_cnter’
    -- set the cnter value color
    life_cnter_rgb <= "011"; -- cyan

    --- Write your VHDL code below:
    -- set graph_rgb 

    graph_rgb <= life_cnter_rgb when
                life_cnter_cur_val_on = '1' else "111";

    -- assign output sq_hit_cnter_on_output
    sq_life_cnter_on_output <= sq_life_cnter_on;
end Behavioral; 