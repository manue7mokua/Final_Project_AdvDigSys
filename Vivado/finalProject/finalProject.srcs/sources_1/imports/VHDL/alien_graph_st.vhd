library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART

entity alien_graph_st is
    port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(3 downto 0);
        shoot_btn: in std_logic;
        video_on: in std_logic;
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        hit_cnt: out std_logic_vector(2 downto 0); 
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end alien_graph_st;

architecture sq_asteroids_arch of alien_graph_st is

    -- Signal used to control speed of small_asteroid and how
    -- often pushbuttons are checked for paddle movement.
    signal refr_tick: std_logic;

    -- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);

    -- counter tracking signals
    signal hit_cnt_reg, hit_cnt_next: unsigned(2 downto 0);

    -- screen dimensions
    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;

    -- wall left and right boundary of wall (full height)
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;

-- paddle left, right, top, bottom and height left &
-- right are constant. top & bottom are signals to
-- allow movement. bar_y_t driven by reg below.
    signal ship_x_l, ship_x_r: unsigned(9 downto 0);
    signal ship_y_t, ship_y_b: unsigned(9 downto 0);
    constant SHIP_X_SIZE: integer := 6;
    constant SHIP_Y_SIZE: integer := 12;

-- reg to track top boundary
    signal ship_x_reg, ship_x_next: unsigned(9 downto 0);
    signal ship_y_reg, ship_y_next: unsigned(9 downto 0);

-- bar moving velocity when a button is pressed
-- the amount the bar is moved.
    constant SHIP_V: integer:= 1;

-- Firing missiles for asteroid
    constant MISSILE_BALL_SIZE: integer := 8;
    signal missile_ball_x_l, missile_ball_x_r: unsigned(9 downto 0);
    signal missile_ball_y_t, missile_ball_y_b: unsigned(9 downto 0);

    -- registers to calculate the position of missile
    signal missile_ball_x_reg, missile_ball_x_next: unsigned(9 downto 0);
    signal missile_ball_y_reg, missile_ball_y_next: unsigned(9 downto 0);

    -- registers to track missile speeds
    signal x_missile_delta_reg, x_missile_delta_next: unsigned(9 downto 0);
    signal y_missile_delta_reg, y_missile_delta_next: unsigned(9 downto 0);

    -- missile movement can be pos or neg
    constant MISSILE_V_P: unsigned(9 downto 0):= to_unsigned(2,10);
    constant MISSILE_V_N: unsigned(9 downto 0):= unsigned(to_signed(-2,10));

    -- missile projectile image
    type rom_type_Missile is array(0 to 7) of std_logic_vector(0 to 7);
    constant MISSILE_BALL_ROM: rom_type_Missile:= (
        "00011000",
        "00111100",
        "00111100",
        "01111110",
        "01111110",
        "00111100",
        "00111100",
        "00011000"
    );

-- square small asteroid -- small asteroid left, right, top and bottom
-- all vary. Left and top driven by registers below.
    constant SMALLROCK_ONE_SIZE: integer := 8;
    signal smallRockOne_x_l, smallRockOne_x_r: unsigned(9 downto 0);
    signal smallRockOne_y_t, smallRockOne_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal smallRockOne_x_reg, smallRockOne_x_next: unsigned(9 downto 0);
    signal smallRockOne_y_reg, smallRockOne_y_next: unsigned(9 downto 0);

    --------------------------------------------
    constant SMALLROCK_TWO_SIZE: integer := 8;
    signal smallRockTwo_x_l, smallRockTwo_x_r: unsigned(9 downto 0);
    signal smallRockTwo_y_t, smallRockTwo_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal smallRockTwo_x_reg, smallRockTwo_x_next: unsigned(9 downto 0);
    signal smallRockTwo_y_reg, smallRockTwo_y_next: unsigned(9 downto 0);

    ---------------------------------------------
    constant SMALLROCK_THREE_SIZE: integer := 8;
    signal smallRockThree_x_l, smallRockThree_x_r: unsigned(9 downto 0);
    signal smallRockThree_y_t, smallRockThree_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal smallRockThree_x_reg, smallRockThree_x_next: unsigned(9 downto 0);
    signal smallRockThree_y_reg, smallRockThree_y_next: unsigned(9 downto 0);

    ---------------------------------------------
    constant SMALLROCK_FOUR_SIZE: integer := 8;
    signal smallRockFour_x_l, smallRockFour_x_r: unsigned(9 downto 0);
    signal smallRockFour_y_t, smallRockFour_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal smallRockFour_x_reg, smallRockFour_x_next: unsigned(9 downto 0);
    signal smallRockFour_y_reg, smallRockFour_y_next: unsigned(9 downto 0);

    ---------------------------------------------
    constant SMALLROCK_FIVE_SIZE: integer := 8;
    signal smallRockFive_x_l, smallRockFive_x_r: unsigned(9 downto 0);
    signal smallRockFive_y_t, smallRockFive_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal smallRockFive_x_reg, smallRockFive_x_next: unsigned(9 downto 0);
    signal smallRockFive_y_reg, smallRockFive_y_next: unsigned(9 downto 0);

    ---------------------------------------------
    constant SMALLROCK_SIX_SIZE: integer := 8;
    signal smallRockSix_x_l, smallRockSix_x_r: unsigned(9 downto 0);
    signal smallRockSix_y_t, smallRockSix_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal smallRockSix_x_reg, smallRockSix_x_next: unsigned(9 downto 0);
    signal smallRockSIx_y_reg, smallRockSix_y_next: unsigned(9 downto 0);

    ---------------------------------------------
    constant SMALLROCK_SEVEN_SIZE: integer := 8;
    signal smallRockSeven_x_l, smallRockSeven_x_r: unsigned(9 downto 0);
    signal smallRockSeven_y_t, smallRockSeven_y_b: unsigned(9 downto 0);

-- reg to track left and top boundary
    signal smallRockSeven_x_reg, smallRockSeven_x_next: unsigned(9 downto 0);
    signal smallRockSeven_y_reg, smallRockSeven_y_next: unsigned(9 downto 0);

-- reg to track small aestoroids speeds
    signal x_small_delta_reg, x_small_delta_next: unsigned(9 downto 0);
    signal y_small_delta_reg, y_small_delta_next: unsigned(9 downto 0);

    signal x_smallTwo_delta_reg, x_smallTwo_delta_next: unsigned(9 downto 0);
    signal y_smallTwo_delta_reg, y_smallTwo_delta_next: unsigned(9 downto 0);

    signal x_smallThree_delta_reg, x_smallThree_delta_next: unsigned(9 downto 0);
    signal y_smallThree_delta_reg, y_smallThree_delta_next: unsigned(9 downto 0);

    signal x_smallFour_delta_reg, x_smallFour_delta_next: unsigned(9 downto 0);
    signal y_smallFour_delta_reg, y_smallFour_delta_next: unsigned(9 downto 0);

    signal x_smallFive_delta_reg, x_smallFive_delta_next: unsigned(9 downto 0);
    signal y_smallFive_delta_reg, y_smallFive_delta_next: unsigned(9 downto 0);

    signal x_smallSix_delta_reg, x_smallSix_delta_next: unsigned(9 downto 0);
    signal y_smallSix_delta_reg, y_smallSix_delta_next: unsigned(9 downto 0);

    signal x_smallSeven_delta_reg, x_smallSeven_delta_next: unsigned(9 downto 0);
    signal y_smallSeven_delta_reg, y_smallSeven_delta_next: unsigned(9 downto 0);

--reg to track big aestoroids speeds
    signal x_big_delta_reg, x_big_delta_next: unsigned(9 downto 0);
    signal y_big_delta_reg, y_big_delta_next: unsigned(9 downto 0);

    signal x_bigTwo_delta_reg, x_bigTwo_delta_next: unsigned(9 downto 0);
    signal y_bigTwo_delta_reg, y_bigTwo_delta_next: unsigned(9 downto 0);

    signal x_bigThree_delta_reg, x_bigThree_delta_next: unsigned(9 downto 0);
    signal y_bigThree_delta_reg, y_bigThree_delta_next: unsigned(9 downto 0);

    signal x_bigFour_delta_reg, x_bigFour_delta_next: unsigned(9 downto 0);
    signal y_bigFour_delta_reg, y_bigFour_delta_next: unsigned(9 downto 0);

-- small asteroid movement can be pos or neg
    constant SMALLROCK_V_P: unsigned(9 downto 0):= to_unsigned(1,10);
    constant SMALLROCK_V_N: unsigned(9 downto 0):= unsigned(to_signed(-1,10));

-- round small asteroid image
    type rom_type_smallRockOne is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKONE_ROM: rom_type_smallRockOne:= (
        "00111100",
        "01111110",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockTwo is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKTWO_ROM: rom_type_smallRockTwo:= (
        "00111100",
        "01111110",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockThree is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKTHREE_ROM: rom_type_smallRockThree:= (
        "00111100",
        "01111110",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockFour is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKFOUR_ROM: rom_type_smallRockFour:= (
        "00111100",
        "01111110",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockFive is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKFIVE_ROM: rom_type_smallRockFive:= (
        "00111100",
        "01111110",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockSix is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKSIX_ROM: rom_type_smallRockSix:= (
        "00111100",
        "01111110",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockSeven is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKSEVEN_ROM: rom_type_smallRockSeven:= (
        "00111100",
        "01111110",
        "01111110",
        "11111111",
        "11111111",
        "01111110",
        "01111110",
        "00111100"
    );

    signal rom_missile_addr, rom_missile_col: unsigned(2 downto 0);
    signal rom_missile_data: std_logic_vector(7 downto 0);
    signal rom_missile_bit:  std_logic;
    signal rom_small_addr, rom_small_col: unsigned(2 downto 0);
    signal rom_small_addr_two, rom_small_col_two: unsigned(2 downto 0);
    signal rom_small_addr_three, rom_small_col_three: unsigned(2 downto 0);
    signal rom_small_addr_four, rom_small_col_four: unsigned(2 downto 0);
    signal rom_small_addr_five, rom_small_col_five: unsigned(2 downto 0);
    signal rom_small_addr_six, rom_small_col_six: unsigned(2 downto 0);
    signal rom_small_addr_seven, rom_small_col_seven: unsigned(2 downto 0);
    signal rom_big_addr, rom_big_col: unsigned(3 downto 0);
    signal rom_big_addr_two, rom_big_col_two: unsigned(3 downto 0);
    signal rom_big_addr_three, rom_big_col_three: unsigned(3 downto 0);
    signal rom_big_addr_four, rom_big_col_four: unsigned(3 downto 0);
    signal rom_small_data, rom_small_data_two, rom_small_data_three: std_logic_vector(7 downto 0);
    signal rom_small_data_four, rom_small_data_five, rom_small_data_six, rom_small_data_seven: std_logic_vector(7 downto 0);
    signal rom_big_data, rom_big_data_two, rom_big_data_three, rom_big_data_four: std_logic_vector(15 downto 0);
    signal rom_small_bit, rom_small_bit_two, rom_small_bit_three: std_logic;
    signal rom_small_bit_four, rom_small_bit_five, rom_small_bit_six, rom_small_bit_seven: std_logic;
    signal rom_big_bit, rom_big_bit_two, rom_big_bit_three, rom_big_bit_four: std_logic;

-- BIG Asteroid object
    constant BIGROCK_ONE_SIZE: integer := 16;
    signal bigRockOne_x_l, bigRockOne_x_r: unsigned(9 downto 0);
    signal bigRockOne_y_t, bigRockOne_y_b: unsigned(9 downto 0);

-- Registers to track left and top boundary
    signal bigRockOne_x_reg, bigRockOne_x_next: unsigned(9 downto 0);
    signal bigRockOne_y_reg, bigRockOne_y_next: unsigned(9 downto 0);

    -------------------------------------------
    constant BIGROCK_TWO_SIZE: integer := 16;
    signal bigRockTwo_x_l, bigRockTwo_x_r: unsigned(9 downto 0);
    signal bigRockTwo_y_t, bigRockTwo_y_b: unsigned(9 downto 0);

-- Registers to track left and top boundary
    signal bigRockTwo_x_reg, bigRockTwo_x_next: unsigned(9 downto 0);
    signal bigRockTwo_y_reg, bigRockTwo_y_next: unsigned(9 downto 0);

    -------------------------------------------
    constant BIGROCK_THREE_SIZE: integer := 16;
    signal bigRockThree_x_l, bigRockThree_x_r: unsigned(9 downto 0);
    signal bigRockThree_y_t, bigRockThree_y_b: unsigned(9 downto 0);

-- Registers to track left and top boundary
    signal bigRockThree_x_reg, bigRockThree_x_next: unsigned(9 downto 0);
    signal bigRockThree_y_reg, bigRockThree_y_next: unsigned(9 downto 0);

    -------------------------------------------
    constant BIGROCK_FOUR_SIZE: integer := 16;
    signal bigRockFour_x_l, bigRockFour_x_r: unsigned(9 downto 0);
    signal bigRockFour_y_t, bigRockFour_y_b: unsigned(9 downto 0);

-- Registers to track left and top boundary
    signal bigRockFour_x_reg, bigRockFour_x_next: unsigned(9 downto 0);
    signal bigRockFour_y_reg, bigRockFour_y_next: unsigned(9 downto 0);

-- Big Asteroid movement can be pos or neg
    constant BIGROCK_V_P: unsigned(9 downto 0) := to_unsigned(1, 10);
    constant BIGROCK_V_N: unsigned(9 downto 0) := unsigned(to_signed(-1, 10));

-- Big Asteroid image
    type rom_type_bigRockOne is array (0 to 15) of std_logic_vector(0 to 15);
    constant BIGROCKONE_ROM: rom_type_bigRockOne:= (
        "0000111111110000",
        "0001111111111000",
        "0001111111111000",
        "0011111111111100",
        "0011111111111100",
        "0111111111111110",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "0111111111111110",
        "0011111111111100",
        "0011111111111100",
        "0001111111111000",
        "0001111111111000",
        "0000111111110000"
    );

    type rom_type_bigRockTwo is array (0 to 15) of std_logic_vector(0 to 15);
    constant BIGROCKTWO_ROM: rom_type_bigRockTwo:= (
        "0000111111110000",
        "0001111111111000",
        "0001111111111000",
        "0011111111111100",
        "0011111111111100",
        "0111111111111110",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "0111111111111110",
        "0011111111111100",
        "0011111111111100",
        "0001111111111000",
        "0001111111111000",
        "0000111111110000"
    );

    type rom_type_bigRockThree is array (0 to 15) of std_logic_vector(0 to 15);
    constant BIGROCKTHREE_ROM: rom_type_bigRockThree:= (
        "0000111111110000",
        "0001111111111000",
        "0001111111111000",
        "0011111111111100",
        "0011111111111100",
        "0111111111111110",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "0111111111111110",
        "0011111111111100",
        "0011111111111100",
        "0001111111111000",
        "0001111111111000",
        "0000111111110000"
    );

    type rom_type_bigRockFour is array (0 to 15) of std_logic_vector(0 to 15);
    constant BIGROCKFOUR_ROM: rom_type_bigRockFour:= (
        "0000111111110000",
        "0001111111111000",
        "0001111111111000",
        "0011111111111100",
        "0011111111111100",
        "0111111111111110",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "1111111111111111",
        "0111111111111110",
        "0011111111111100",
        "0011111111111100",
        "0001111111111000",
        "0001111111111000",
        "0000111111110000"
    );

-- object output signals -- new signal to indicate if
-- scan coord is within small asteroid
    signal wall_on, ship_on: std_logic;
    signal sq_missile_ball_on, rd_missile_ball_on: std_logic;
    signal sq_smallRockOne_on, sq_smallRockTwo_on, sq_smallRockThree_on, sq_smallRockFour_on, sq_smallRockFive_on, sq_smallRockSix_on, sq_smallRockSeven_on: std_logic;
    signal sq_bigRockOne_on, sq_bigRockTwo_on, sq_bigRockThree_on, sq_bigRockFour_on: std_logic;
    signal rd_smallRockOne_on, rd_smallRockTwo_on, rd_smallRockThree_on, rd_smallRockFour_on, rd_smallRockFive_on, rd_smallRockSix_on, rd_smallRockSeven_on: std_logic;
    signal rd_bigRockOne_on, rd_bigRockTwo_on, rd_bigRockThree_on, rd_bigRockFour_on: std_logic;

    signal wall_rgb, ship_rgb: std_logic_vector(2 downto 0);
    signal missile_ball_rgb: std_logic_vector(2 downto 0);
    signal smallRockOne_rgb, smallRockTwo_rgb, smallRockThree_rgb, smallRockFour_rgb, smallRockFive_rgb, smallRockSix_rgb, smallRockSeven_rgb: std_logic_vector(2 downto 0);
    signal bigRockOne_rgb, bigRockTwo_rgb, bigRockThree_rgb, bigRockFour_rgb: std_logic_vector(2 downto 0);

-- ====================================================
    begin
    process (clk, reset)
        begin
        if (reset = '1') then
            ship_x_reg <= (others => '0');
            ship_y_reg <= (others => '0');
            hit_cnt_reg <= (others => '0');
            missile_ball_x_reg <= "0000001000";
            missile_ball_y_reg <= "0000001000";
            smallRockOne_x_reg <= "0100000000";
            smallRockOne_y_reg <= "0100000000";
            smallRockTwo_x_reg <= "0000000010";
            smallRockTwo_y_reg <= "0000000010";
            smallRockThree_x_reg <= "0000100000";
            smallRockThree_y_reg <= "0000100000";
            smallRockFour_x_reg <= "0000100000";
            smallRockFour_y_reg <= "0000100000";
            smallRockFive_x_reg <= "0000100000";
            smallRockFive_y_reg <= "0000100000";
            smallRockSix_x_reg <= "0000100000";
            smallRockSix_y_reg <= "0000100000";
            smallRockSeven_x_reg <= "0000100000";
            smallRockSeven_y_reg <= "0000100000";
            bigRockOne_x_reg <= "0000100000";
            bigRockOne_y_reg <= "0000100000";
            bigRockTwo_x_reg <= "0000001000";
            bigRockTwo_y_reg <= "0000001000";
            bigRockThree_x_reg <= "0000001000";
            bigRockThree_y_reg <= "0000001000";
            bigRockFour_x_reg <= "0000001000";
            bigRockFour_y_reg <= "0000001000";
            x_missile_delta_reg <= ("0000000100");
            y_missile_delta_reg <= ("0000000100");
            x_small_delta_reg <= ("0000000100");
            y_small_delta_reg <= ("0000000100");
            x_smallTwo_delta_reg <= ("0000000100");
            y_smallTwo_delta_reg <= ("0000000100");
            x_smallThree_delta_reg <= ("0000000100");
            y_smallThree_delta_reg <= ("0000000100");
            x_smallFour_delta_reg <= ("0000000100");
            y_smallFour_delta_reg <= ("0000000100");
            x_smallFive_delta_reg <= ("0000000100");
            y_smallFive_delta_reg <= ("0000000100");
            x_smallSix_delta_reg <= ("0000000100");
            y_smallSix_delta_reg <= ("0000000100");
            x_smallSeven_delta_reg <= ("0000000100");
            y_smallSeven_delta_reg <= ("0000000100");
            x_big_delta_reg <= ("0000000100");
            y_big_delta_reg <= ("0000000100");
            x_bigTwo_delta_reg <= ("0001000100");
            y_bigTwo_delta_reg <= ("0001000100");
            x_bigThree_delta_reg <= ("0001000100");
            y_bigThree_delta_reg <= ("0001000100");
            x_bigFour_delta_reg <= ("0001000100");
            y_bigFour_delta_reg <= ("0001000100");
        elsif (clk'event and clk = '1') then
            ship_x_reg <= ship_x_next;
            ship_y_reg <= ship_y_next;
            hit_cnt_reg <= hit_cnt_next;
            missile_ball_x_reg <= missile_ball_x_next;
            missile_ball_y_reg <= missile_ball_y_next;
            smallRockOne_x_reg <= smallRockOne_x_next;
            smallRockOne_y_reg <= smallRockOne_y_next;
            smallRockTwo_x_reg <= smallRockTwo_x_next;
            smallRockTwo_y_reg <= smallRockTwo_y_next;
            smallRockThree_x_reg <= smallRockThree_x_next;
            smallRockThree_y_reg <= smallRockThree_y_next;
            smallRockFour_x_reg <= smallRockFour_x_next;
            smallRockFour_y_reg <= smallRockFour_y_next;
            smallRockFive_x_reg <= smallRockFive_x_next;
            smallRockFive_y_reg <= smallRockFive_y_next;
            smallRockSix_x_reg <= smallRockSix_x_next;
            smallRockSix_y_reg <= smallRockSix_y_next;
            smallRockSeven_x_reg <= smallRockSeven_x_next;
            smallRockSeven_y_reg <= smallRockSeven_y_next;
            bigRockOne_x_reg <= bigRockOne_x_next;
            bigRockOne_y_reg <= bigRockOne_y_next;
            bigRockTwo_x_reg <= bigRockTwo_x_next;
            bigRockTwo_y_reg <= bigRockTwo_y_next;
            bigRockThree_x_reg <= bigRockThree_x_next;
            bigRockThree_y_reg <= bigRockThree_y_next;
            bigRockFour_x_reg <= bigRockFour_x_next;
            bigRockFour_y_reg <= bigRockFour_y_next;
            x_missile_delta_reg <= x_missile_delta_next;
            y_missile_delta_reg <= y_missile_delta_next;
            x_small_delta_reg <= x_small_delta_next;
            y_small_delta_reg <= y_small_delta_next;
            x_smallTwo_delta_reg <= x_smallTwo_delta_next;
            y_smallTwo_delta_reg <= y_smallTwo_delta_next;
            x_smallThree_delta_reg <= x_smallThree_delta_next;
            y_smallThree_delta_reg <= y_smallThree_delta_next;
            x_smallFour_delta_reg <= x_smallFour_delta_next;
            y_smallFour_delta_reg <= y_smallFour_delta_next;
            x_smallFive_delta_reg <= x_smallFive_delta_next;
            y_smallFive_delta_reg <= y_smallFive_delta_next;
            x_smallSix_delta_reg <= x_smallSix_delta_next;
            y_smallSix_delta_reg <= y_smallSix_delta_next;
            x_smallSeven_delta_reg <= x_smallSeven_delta_next;
            y_smallSeven_delta_reg <= y_smallSeven_delta_next;
            x_big_delta_reg <= x_big_delta_next;
            y_big_delta_reg <= y_big_delta_next;
            x_bigTwo_delta_reg <= x_bigTwo_delta_next;
            y_bigTwo_delta_reg <= y_bigTwo_delta_next;
            x_bigThree_delta_reg <= x_bigThree_delta_next;
            y_bigThree_delta_reg <= y_bigThree_delta_next;
            x_bigFour_delta_reg <= x_bigFour_delta_next;
            y_bigFour_delta_reg <= y_bigFour_delta_next;
        end if;
    end process;

    pix_x <= unsigned(pixel_x);
    pix_y <= unsigned(pixel_y);

    -- refr_tick: 1-clock tick asserted at start of v_sync,
    -- e.g., when the screen is refreshed -- speed is 60 Hz
    refr_tick <= '1' when (pix_y = 481) and (pix_x = 0)
    else '0';

    -- wall left vertical stripe
    wall_on <= '1' when (WALL_X_L <= pix_x) and
        (pix_x <= WALL_X_R) else '0';
    wall_rgb <= "001"; -- blue

-- pixel within spaceship
    ship_x_l <= ship_x_reg;
    ship_x_r <= ship_x_l + SHIP_X_SIZE - 1;
    ship_y_t <= ship_y_reg;
    ship_y_b <= ship_y_t + SHIP_Y_SIZE - 1;
    ship_on <= '1' when (ship_x_l <= pix_x) and
        (pix_x <= ship_x_r) and (ship_y_t <= pix_y) and
        (pix_y <= ship_y_b) else '0';
    ship_rgb <= "101"; -- pink

-- Process bar movement requests (UP and DOWN)
    process( ship_y_reg, ship_y_b, ship_y_t, refr_tick, btn)
        begin
        ship_y_next <= ship_y_reg; -- no move
        if ( refr_tick = '1' ) then
            -- if btn 1 pressed and paddle not at bottom yet
            if ( btn(1) = '1' and ship_y_b < (MAX_Y - 1 - SHIP_V)) then
                ship_y_next <= ship_y_reg + SHIP_V; -- Move down
            -- if btn 1 pressed and bar not at top yet
            elsif ( btn(0) = '1' and ship_y_t > SHIP_V) then
                ship_y_next <= ship_y_reg - SHIP_V; -- Move up
            end if;
        end if;
    end process;

-- Process bar movement requests (LEFT and RIGHT)
    process( ship_x_reg, ship_x_l, ship_x_r, refr_tick, btn)
        begin
        ship_x_next <= ship_x_reg; -- no move
        if ( refr_tick = '1' ) then
            -- if btn 1 pressed and paddle not at most right yet
            if ( btn(3) = '1' and ship_x_r < (MAX_X - 1 - SHIP_V)) then
                ship_x_next <= ship_x_reg + SHIP_V; -- Move right
            -- if btn 1 pressed and bar not at most left yet
            elsif ( btn(2) = '1' and ship_x_l > SHIP_V) then
                ship_x_next <= ship_x_reg - SHIP_V; -- Move left
            end if;
        end if;
    end process;

    -- set coordinates of 1st square small asteroid.
    smallRockOne_x_l <= smallRockOne_x_reg;
    smallRockOne_y_t <= smallRockOne_y_reg;
    smallRockOne_x_r <= smallRockOne_x_l + SMALLROCK_ONE_SIZE;
    smallRockOne_y_b <= smallRockOne_y_t + SMALLROCK_ONE_SIZE;

    -- set coordinates of 2nd square small asteroid.
    smallRockTwo_x_l <= smallRockTwo_x_reg;
    smallRockTwo_y_t <= smallRockTwo_y_reg;
    smallRockTwo_x_r <= smallRockTwo_x_l + SMALLROCK_TWO_SIZE;
    smallRockTwo_y_b <= smallRockTwo_y_t + SMALLROCK_TWO_SIZE;

    -- set coordinates of 3rd square small asteroid.
    smallRockThree_x_l <= smallRockThree_x_reg;
    smallRockThree_y_t <= smallRockThree_y_reg;
    smallRockThree_x_r <= smallRockThree_x_l + SMALLROCK_THREE_SIZE;
    smallRockThree_y_b <= smallRockThree_y_t + SMALLROCK_THREE_SIZE;

    -- set coordinates of 4th square small asteroid.
    smallRockFour_x_l <= smallRockFour_x_reg;
    smallRockFour_y_t <= smallRockFour_y_reg;
    smallRockFour_x_r <= smallRockFour_x_l + SMALLROCK_FOUR_SIZE;
    smallRockFour_y_b <= smallRockFour_y_t + SMALLROCK_FOUR_SIZE;

    -- set coordinates of 5th square small asteroid.
    smallRockFive_x_l <= smallRockFive_x_reg;
    smallRockFive_y_t <= smallRockFive_y_reg;
    smallRockFive_x_r <= smallRockFive_x_l + SMALLROCK_FIVE_SIZE;
    smallRockFive_y_b <= smallRockFive_y_t + SMALLROCK_FIVE_SIZE;

    -- set coordinates of 6th square small asteroid.
    smallRockSix_x_l <= smallRockSix_x_reg;
    smallRockSix_y_t <= smallRockSix_y_reg;
    smallRockSix_x_r <= smallRockSix_x_l + SMALLROCK_SIX_SIZE;
    smallRockSix_y_b <= smallRockSix_y_t + SMALLROCK_SIX_SIZE;

    -- set coordinates of 7th square small asteroid.
    smallRockSeven_x_l <= smallRockSeven_x_reg;
    smallRockSeven_y_t <= smallRockSeven_y_reg;
    smallRockSeven_x_r <= smallRockSeven_x_l + SMALLROCK_SEVEN_SIZE;
    smallRockSeven_y_b <= smallRockSeven_y_t + SMALLROCK_SEVEN_SIZE;

    -- set coordinates of big asteroid
    bigRockOne_x_l <= bigRockOne_x_reg;
    bigRockOne_y_t <= bigRockOne_y_reg;
    bigRockOne_x_r <= bigRockOne_x_l + BIGROCK_ONE_SIZE;
    bigRockOne_y_b <= bigRockOne_y_t + BIGROCK_ONE_SIZE;

    -- set coordinates of 2nd big asteroid
    bigRockTwo_x_l <= bigRockTwo_x_reg;
    bigRockTwo_y_t <= bigRockTwo_y_reg;
    bigRockTwo_x_r <= bigRockTwo_x_l + BIGROCK_TWO_SIZE;
    bigRockTwo_y_b <= bigRockTwo_y_t + BIGROCK_TWO_SIZE;

    -- set coordinates of 3rd big asteroid
    bigRockThree_x_l <= bigRockThree_x_reg;
    bigRockThree_y_t <= bigRockThree_y_reg;
    bigRockThree_x_r <= bigRockThree_x_l + BIGROCK_THREE_SIZE;
    bigRockThree_y_b <= bigRockThree_y_t + BIGROCK_THREE_SIZE;

    -- set coordinates of 4th big asteroid
    bigRockFour_x_l <= bigRockFour_x_reg;
    bigRockFour_y_t <= bigRockFour_y_reg;
    bigRockFour_x_r <= bigRockFour_x_l + BIGROCK_FOUR_SIZE;
    bigRockFour_y_b <= bigRockFour_y_t + BIGROCK_FOUR_SIZE;

    -- set coordinates of the missile projectile
    missile_ball_x_l <= missile_ball_x_reg;
    missile_ball_y_t <= missile_ball_y_reg;
    missile_ball_x_r <= missile_ball_x_l + MISSILE_BALL_SIZE;
    missile_ball_y_b <= missile_ball_y_t + MISSILE_BALL_SIZE;

    -- pixel within missile_ball_projectile
    sq_missile_ball_on <= '1' when (missile_ball_x_l <= pix_x) and
        (pix_x <= missile_ball_x_r) and (missile_ball_y_t <= pix_y) and
        (pix_y <= missile_ball_y_b) else '0';

    -- pixel within 1st square small asteroid
    sq_smallRockOne_on <= '1' when (smallRockOne_x_l <= pix_x) and
        (pix_x <= smallRockOne_x_r) and (smallRockOne_y_t <= pix_y) and
        (pix_y <= smallRockOne_y_b) else '0';

    -- pixel within 2nd square small asteroid
    sq_smallRockTwo_on <= '1' when (smallRockTwo_x_l <= pix_x) and
        (pix_x <= smallRockTwo_x_r) and (smallRockTwo_y_t <= pix_y) and
        (pix_y <= smallRockTwo_y_b) else '0';

    -- pixel within 3rd square small asteroid
    sq_smallRockThree_on <= '1' when (smallRockThree_x_l <= pix_x) and
        (pix_x <= smallRockThree_x_r) and (smallRockThree_y_t <= pix_y) and
        (pix_y <= smallRockThree_y_b) else '0';

    -- pixel within 4th square small asteroid
    sq_smallRockFour_on <= '1' when (smallRockFour_x_l <= pix_x) and
        (pix_x <= smallRockFour_x_r) and (smallRockFour_y_t <= pix_y) and
        (pix_y <= smallRockFour_y_b) else '0';

    -- pixel within 5th square small asteroid
    sq_smallRockFive_on <= '1' when (smallRockFive_x_l <= pix_x) and
        (pix_x <= smallRockFive_x_r) and (smallRockFive_y_t <= pix_y) and
        (pix_y <= smallRockFive_y_b) else '0';

    -- pixel within 6th square small asteroid
    sq_smallRockSix_on <= '1' when (smallRockSix_x_l <= pix_x) and
        (pix_x <= smallRockSix_x_r) and (smallRockSix_y_t <= pix_y) and
        (pix_y <= smallRockSix_y_b) else '0';

    -- pixel within 7th square small asteroid
    sq_smallRockSeven_on <= '1' when (smallRockSeven_x_l <= pix_x) and
        (pix_x <= smallRockSeven_x_r) and (smallRockSeven_y_t <= pix_y) and
        (pix_y <= smallRockSeven_y_b) else '0';

    -- pixel within 1st BIG asteroid
    sq_bigRockOne_on <= '1' when (bigRockOne_x_l <= pix_x) and
        (pix_x <= bigRockOne_x_r) and (bigRockOne_y_t <= pix_y) and
        (pix_y <= bigRockOne_y_b) else '0';

    -- pixel within 2nd BIG asteroid
    sq_bigRockTwo_on <= '1' when (bigRockTwo_x_l <= pix_x) and
        (pix_x <= bigRockTwo_x_r) and (bigRockTwo_y_t <= pix_y) and
        (pix_y <= bigRockTwo_y_b) else '0';

    -- pixel within 3rd BIG asteroid
    sq_bigRockThree_on <= '1' when (bigRockThree_x_l <= pix_x) and
        (pix_x <= bigRockThree_x_r) and (bigRockThree_y_t <= pix_y) and
        (pix_y <= bigRockThree_y_b) else '0';

    -- pixel within 4th BIG asteroid
    sq_bigRockFour_on <= '1' when (bigRockFour_x_l <= pix_x) and
        (pix_x <= bigRockFour_x_r) and (bigRockFour_y_t <= pix_y) and
        (pix_y <= bigRockFour_y_b) else '0';

-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and small asteroid positions.
-- ROM row
    rom_missile_addr <= pix_y(2 downto 0) - missile_ball_y_t(2 downto 0);
    rom_small_addr <= pix_y(2 downto 0) - smallRockOne_y_t(2 downto 0);
    rom_small_addr_two <= pix_y(2 downto 0) - smallRockTwo_y_t(2 downto 0);
    rom_small_addr_three <= pix_y(2 downto 0) - smallRockThree_y_t(2 downto 0);
    rom_small_addr_four <= pix_y(2 downto 0) - smallRockFour_y_t(2 downto 0);
    rom_small_addr_five <= pix_y(2 downto 0) - smallRockFive_y_t(2 downto 0);
    rom_small_addr_six <= pix_y(2 downto 0) - smallRockSix_y_t(2 downto 0);
    rom_small_addr_seven <= pix_y(2 downto 0) - smallRockSeven_y_t(2 downto 0);
    rom_big_addr <= pix_y(3 downto 0) - bigRockOne_y_t(3 downto 0);
    rom_big_addr_two <= pix_y(3 downto 0) - bigRockTwo_y_t(3 downto 0);
    rom_big_addr_three <= pix_y(3 downto 0) - bigRockThree_y_t(3 downto 0);
    rom_big_addr_four <= pix_y(3 downto 0) - bigRockFour_y_t(3 downto 0);
-- ROM column
    rom_missile_col <= pix_x(2 downto 0) - missile_ball_x_l(2 downto 0);
    rom_small_col <= pix_x(2 downto 0) - smallRockOne_x_l(2 downto 0);
    rom_small_col_two <= pix_x(2 downto 0) - smallRockTwo_x_l(2 downto 0);
    rom_small_col_three <= pix_x(2 downto 0) - smallRockThree_x_l(2 downto 0);
    rom_small_col_four <= pix_x(2 downto 0) - smallRockFour_x_l(2 downto 0);
    rom_small_col_five <= pix_x(2 downto 0) - smallRockFive_x_l(2 downto 0);
    rom_small_col_six <= pix_x(2 downto 0) - smallRockSix_x_l(2 downto 0);
    rom_small_col_seven <= pix_x(2 downto 0) - smallRockSeven_x_l(2 downto 0);
    rom_big_col <= pix_x(3 downto 0) - bigRockOne_x_l(3 downto 0);
    rom_big_col_two <= pix_x(3 downto 0) - bigRockTwo_x_l(3 downto 0);
    rom_big_col_three <= pix_x(3 downto 0) - bigRockThree_x_l(3 downto 0);
    rom_big_col_four <= pix_x(3 downto 0) - bigRockFour_x_l(3 downto 0);
-- Get row data
    rom_missile_data <= MISSILE_BALL_ROM(to_integer(rom_missile_addr));
    rom_small_data <= SMALLROCKONE_ROM(to_integer(rom_small_addr));
    rom_small_data_two <= SMALLROCKTWO_ROM(to_integer(rom_small_addr_two));
    rom_small_data_three <= SMALLROCKTHREE_ROM(to_integer(rom_small_addr_three));
    rom_small_data_four <= SMALLROCKFOUR_ROM(to_integer(rom_small_addr_four));
    rom_small_data_five <= SMALLROCKFIVE_ROM(to_integer(rom_small_addr_five));
    rom_small_data_six <= SMALLROCKSIX_ROM(to_integer(rom_small_addr_six));
    rom_small_data_seven <= SMALLROCKSEVEN_ROM(to_integer(rom_small_addr_seven));
    rom_big_data <= BIGROCKONE_ROM(to_integer(rom_big_addr));
    rom_big_data_two <= BIGROCKTWO_ROM(to_integer(rom_big_addr_two));
    rom_big_data_three <= BIGROCKTHREE_ROM(to_integer(rom_big_addr_three));
    rom_big_data_four <= BIGROCKFOUR_ROM(to_integer(rom_big_addr_four));
-- Get column bit
    rom_missile_bit <= rom_missile_data(to_integer(rom_missile_col));
    rom_small_bit <= rom_small_data(to_integer(rom_small_col));
    rom_small_bit_two <= rom_small_data_two(to_integer(rom_small_col_two));
    rom_small_bit_three <= rom_small_data_three(to_integer(rom_small_col_three));
    rom_small_bit_four <= rom_small_data_four(to_integer(rom_small_col_four));
    rom_small_bit_five <= rom_small_data_five(to_integer(rom_small_col_five));
    rom_small_bit_six <= rom_small_data_six(to_integer(rom_small_col_six));
    rom_small_bit_seven <= rom_small_data_seven(to_integer(rom_small_col_seven));
    rom_big_bit <= rom_big_data(to_integer(rom_big_col));
    rom_big_bit_two <= rom_big_data_two(to_integer(rom_big_col_two));
    rom_big_bit_three <= rom_big_data_three(to_integer(rom_big_col_three));
    rom_big_bit_four <= rom_big_data_four(to_integer(rom_big_col_four));

    --------------------------------------------------------------------------------------

    --- Turn on missile ball if within the pixel square and the ROM bit is 1
    rd_missile_ball_on <= '1' when (sq_missile_ball_on = '1') and
    (rom_missile_bit = '1') else '0';
    missile_ball_rgb <= "010"; -- red

-- Turn small asteroid on only if within square and ROM bit is 1.
    rd_smallRockOne_on <= '1' when (sq_smallRockOne_on = '1') and
    (rom_small_bit = '1') else '0';
    smallRockOne_rgb <= "100"; -- red

    rd_smallRockTwo_on <= '1' when (sq_smallRockTwo_on = '1') and
    (rom_small_bit_two = '1') else '0';
    smallRockTwo_rgb <= "100"; -- red

    rd_smallRockThree_on <= '1' when (sq_smallRockThree_on = '1') and
    (rom_small_bit_three = '1') else '0';
    smallRockThree_rgb <= "100"; -- red

    rd_smallRockFour_on <= '1' when (sq_smallRockFour_on = '1') and
    (rom_small_bit_four = '1') else '0';
    smallRockFour_rgb <= "100"; -- red

    rd_smallRockFive_on <= '1' when (sq_smallRockFive_on = '1') and
    (rom_small_bit_five = '1') else '0';
    smallRockFive_rgb <= "100"; -- red

    rd_smallRockSix_on <= '1' when (sq_smallRockSix_on = '1') and
    (rom_small_bit_six = '1') else '0';
    smallRockSix_rgb <= "100"; -- red

    rd_smallRockSeven_on <= '1' when (sq_smallRockSeven_on = '1') and
    (rom_small_bit_seven = '1') else '0';
    smallRockSeven_rgb <= "100"; -- red

-- Turn big asteroid on only if within square and ROM bit is 1
    rd_bigRockOne_on <= '1' when (sq_bigRockOne_on = '1') and
    (rom_big_bit = '1') else '0';
    bigRockOne_rgb <= "000"; -- black

    rd_bigRockTwo_on <= '1' when (sq_bigRockTwo_on = '1') and
    (rom_big_bit_two = '1') else '0';
    bigRockTwo_rgb <= "000"; -- black

    rd_bigRockThree_on <= '1' when (sq_bigRockThree_on = '1') and
    (rom_big_bit_three = '1') else '0';
    bigRockThree_rgb <= "000"; -- black

    rd_bigRockFour_on <= '1' when (sq_bigRockFour_on = '1') and
    (rom_big_bit_four = '1') else '0';
    bigRockFour_rgb <= "000"; -- black

    -- Update the missiles positions 60 times per second
    missile_ball_x_next <= missile_ball_x_reg + x_missile_delta_reg when
        refr_tick = '1' else missile_ball_x_reg;
    missile_ball_y_next <= missile_ball_y_reg + y_missile_delta_reg when
        refr_tick = '1' else missile_ball_y_reg;

-- Update the small asteroids positions 60 times per second.
    smallRockOne_x_next <= smallRockOne_x_reg + x_small_delta_reg when
        refr_tick = '1' else smallRockOne_x_reg;
    smallRockOne_y_next <= smallRockOne_y_reg + y_small_delta_reg when
        refr_tick = '1' else smallRockOne_y_reg;
    
    smallRockTwo_x_next <= smallRockTwo_x_reg + x_smallTwo_delta_reg when
        refr_tick = '1' else smallRockTwo_x_reg;
    smallRockTwo_y_next <= smallRockTwo_y_reg + y_smallTwo_delta_reg when
        refr_tick = '1' else smallRockTwo_y_reg;

    smallRockThree_x_next <= smallRockThree_x_reg + x_smallThree_delta_reg when
        refr_tick = '1' else smallRockThree_x_reg;
    smallRockThree_y_next <= smallRockThree_y_reg + y_smallThree_delta_reg when
        refr_tick = '1' else smallRockThree_y_reg;

    smallRockFour_x_next <= smallRockFour_x_reg + x_smallFour_delta_reg when
        refr_tick = '1' else smallRockFour_x_reg;
    smallRockFour_y_next <= smallRockFour_y_reg + y_smallFour_delta_reg when
        refr_tick = '1' else smallRockFour_y_reg;

    smallRockFive_x_next <= smallRockFive_x_reg + x_smallFive_delta_reg when
        refr_tick = '1' else smallRockFive_x_reg;
    smallRockFive_y_next <= smallRockFive_y_reg + y_smallFive_delta_reg when
        refr_tick = '1' else smallRockFive_y_reg;

    smallRockSix_x_next <= smallRockSix_x_reg + x_smallSix_delta_reg when
        refr_tick = '1' else smallRockSix_x_reg;
    smallRockSix_y_next <= smallRockSix_y_reg + y_smallSix_delta_reg when
        refr_tick = '1' else smallRockSix_y_reg;

    smallRockSeven_x_next <= smallRockSeven_x_reg + x_smallSeven_delta_reg when
        refr_tick = '1' else smallRockSeven_x_reg;
    smallRockSeven_y_next <= smallRockSeven_y_reg + y_smallSeven_delta_reg when
        refr_tick = '1' else smallRockSeven_y_reg;

-- Update the big asteroid position 60 times per second
    bigRockOne_x_next <= bigRockOne_x_reg + x_big_delta_reg when
        refr_tick = '1' else bigRockOne_x_reg;
    bigRockOne_y_next <= bigRockOne_y_reg + y_big_delta_reg when
        refr_tick = '1' else bigRockOne_y_reg;

    bigRockTwo_x_next <= bigRockTwo_x_reg + x_bigTwo_delta_reg when
        refr_tick = '1' else bigRockTwo_x_reg;
    bigRockTwo_y_next <= bigRockTwo_y_reg + y_bigTwo_delta_reg when
        refr_tick = '1' else bigRockTwo_y_reg;

    bigRockThree_x_next <= bigRockThree_x_reg + x_bigThree_delta_reg when
        refr_tick = '1' else bigRockThree_x_reg;
    bigRockThree_y_next <= bigRockThree_y_reg + y_bigThree_delta_reg when
        refr_tick = '1' else bigRockThree_y_reg;

    bigRockFour_x_next <= bigRockFour_x_reg + x_bigFour_delta_reg when
        refr_tick = '1' else bigRockFour_x_reg;
    bigRockFour_y_next <= bigRockFour_y_reg + y_bigFour_delta_reg when
        refr_tick = '1' else bigRockFour_y_reg;

-- Set the value of the next small asteroid position according to
-- the boundaries.
    process(x_small_delta_reg, y_small_delta_reg, x_smallTwo_delta_reg, y_smallTwo_delta_reg,
        x_smallThree_delta_reg, y_smallThree_delta_reg, x_smallFour_delta_reg, y_smallFour_delta_reg,
        x_smallFive_delta_reg, y_smallFive_delta_reg, x_smallSix_delta_reg, y_smallSix_delta_reg,
        x_smallSeven_delta_reg, y_smallSeven_delta_reg, smallRockOne_y_t, smallRockOne_x_l,
        smallRockOne_x_r, smallRockOne_y_b, smallRockTwo_y_t, smallRockTwo_x_l,
        smallRockTwo_x_r, smallRockTwo_y_b, smallRockThree_y_t, smallRockThree_x_l,
        smallRockThree_x_r, smallRockThree_y_b, smallRockFour_y_t, smallRockFour_x_l,
        smallRockFour_x_r, smallRockFour_y_b, smallRockFive_y_t, smallRockFive_x_l,
        smallRockFive_x_r, smallRockFive_y_b, smallRockSix_y_t, smallRockSix_x_l,
        smallRockSix_x_r, smallRockSix_y_b, smallRockSeven_y_t, smallRockSeven_x_l,
        smallRockSeven_x_r, smallRockSeven_y_b, ship_y_t, ship_y_b)
        begin
        x_small_delta_next <= x_small_delta_reg;
        y_small_delta_next <= y_small_delta_reg;
        x_smallTwo_delta_next <= x_smallTwo_delta_reg;
        y_smallTwo_delta_next <= y_smallTwo_delta_reg;
        x_smallThree_delta_next <= x_smallThree_delta_reg;
        y_smallThree_delta_next <= y_smallThree_delta_reg;
        x_smallFour_delta_next <= x_smallFour_delta_reg;
        y_smallFour_delta_next <= y_smallFour_delta_reg;
        x_smallFive_delta_next <= x_smallFive_delta_reg;
        y_smallFive_delta_next <= y_smallFive_delta_reg;
        x_smallSix_delta_next <= x_smallSix_delta_reg;
        y_smallSix_delta_next <= y_smallSix_delta_reg;
        x_smallSeven_delta_next <= x_smallSeven_delta_reg;
        y_smallSeven_delta_next <= y_smallSeven_delta_reg;
-- small asteroid reached top, make offset positive
        if ( smallRockOne_y_t < 1 ) then
        y_small_delta_next <= SMALLROCK_V_P;
-- reached bottom, make negative
        elsif (smallRockOne_y_b > (MAX_Y - 1)) then
            y_small_delta_next <= SMALLROCK_V_N;
            -- reach wall, bounce back
        elsif (smallRockOne_x_l <= WALL_X_R ) then
            x_small_delta_next <= SMALLROCK_V_P;
            -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= smallRockOne_x_r) and (smallRockOne_x_r <= ship_x_r)) then
            -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= smallRockOne_y_b) and (smallRockOne_y_t <= ship_y_b)) then
            x_small_delta_next <= SMALLROCK_V_N;
            end if;
        end if;

-- 2nd small asteroid logic
        if ( smallRockTwo_y_t < 1 ) then
            y_smallTwo_delta_next <= SMALLROCK_V_P;
    -- reached bottom, make negative
        elsif (smallRockTwo_y_b > (MAX_Y - 1)) then
            y_smallTwo_delta_next <= SMALLROCK_V_N;
    -- reach wall, bounce back
        elsif (smallRockTwo_x_l <= WALL_X_R ) then
            x_smallTwo_delta_next <= SMALLROCK_V_P;
    -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= smallRockTwo_x_r) and (smallRocktwo_x_r <= ship_x_r)) then
        -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= smallRockTwo_y_b) and (smallRockTwo_y_t <= ship_y_b)) then
                x_smallTwo_delta_next <= SMALLROCK_V_N;
            end if;
        end if;

-- 3rd asteroid logic
        if ( smallRockThree_y_t < 1 ) then
            y_smallThree_delta_next <= SMALLROCK_V_P;
    -- reached bottom, make negative
        elsif (smallRockThree_y_b > (MAX_Y - 1)) then
            y_smallThree_delta_next <= SMALLROCK_V_N;
    -- reach wall, bounce back
        elsif (smallRockThree_x_l <= WALL_X_R ) then
            x_smallThree_delta_next <= SMALLROCK_V_P;
    -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= smallRockThree_x_r) and (smallRockThree_x_r <= ship_x_r)) then
    -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= smallRockThree_y_b) and (smallRockThree_y_t <= ship_y_b)) then
                x_smallThree_delta_next <= SMALLROCK_V_N;
            end if;
        end if;

-- 4th asteroid logic
        if ( smallRockFour_y_t < 1 ) then
            y_smallFour_delta_next <= SMALLROCK_V_P;
    -- reached bottom, make negative
        elsif (smallRockFour_y_b > (MAX_Y - 1)) then
            y_smallFour_delta_next <= SMALLROCK_V_N;
    -- reach wall, bounce back
        elsif (smallRockFour_x_l <= WALL_X_R ) then
            x_smallFour_delta_next <= SMALLROCK_V_P;
    -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= smallRockFour_x_r) and (smallRockFour_x_r <= ship_x_r)) then
    -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= smallRockFour_y_b) and (smallRockFour_y_t <= ship_y_b)) then
                x_smallFour_delta_next <= SMALLROCK_V_N;
            end if;
        end if;

-- 5th asteroid logic
        if ( smallRockFive_y_t < 1 ) then
            y_smallFive_delta_next <= SMALLROCK_V_P;
    -- reached bottom, make negative
        elsif (smallRockFive_y_b > (MAX_Y - 1)) then
            y_smallFive_delta_next <= SMALLROCK_V_N;
    -- reach wall, bounce back
        elsif (smallRockFive_x_l <= WALL_X_R ) then
            x_smallFive_delta_next <= SMALLROCK_V_P;
    -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= smallRockFive_x_r) and (smallRockFive_x_r <= ship_x_r)) then
    -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= smallRockFive_y_b) and (smallRockFive_y_t <= ship_y_b)) then
                x_smallFive_delta_next <= SMALLROCK_V_N;
            end if;
        end if;

-- 6th asteroid logic
        if ( smallRockSix_y_t < 1 ) then
            y_smallSix_delta_next <= SMALLROCK_V_P;
    -- reached bottom, make negative
        elsif (smallRockSix_y_b > (MAX_Y - 1)) then
            y_smallSix_delta_next <= SMALLROCK_V_N;
    -- reach wall, bounce back
        elsif (smallRockSix_x_l <= WALL_X_R ) then
            x_smallSix_delta_next <= SMALLROCK_V_P;
    -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= smallRockSix_x_r) and (smallRockSix_x_r <= ship_x_r)) then
    -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= smallRockSix_y_b) and (smallRockSix_y_t <= ship_y_b)) then
                x_smallSix_delta_next <= SMALLROCK_V_N;
            end if;
        end if;

-- 7th asteroid logic
        if ( smallRockSeven_y_t < 1 ) then
            y_smallSeven_delta_next <= SMALLROCK_V_P;
    -- reached bottom, make negative
        elsif (smallRockSeven_y_b > (MAX_Y - 1)) then
            y_smallSeven_delta_next <= SMALLROCK_V_N;
    -- reach wall, bounce back
        elsif (smallRockSeven_x_l <= WALL_X_R ) then
            x_smallSeven_delta_next <= SMALLROCK_V_P;
    -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= smallRockSeven_x_r) and (smallRockSeven_x_r <= ship_x_r)) then
    -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= smallRockSeven_y_b) and (smallRockSeven_y_t <= ship_y_b)) then
                x_smallSeven_delta_next <= SMALLROCK_V_N;
            end if;
        end if;
    end process;

    process(x_big_delta_reg, y_big_delta_reg, x_bigTwo_delta_reg, y_bigTwo_delta_reg,
        x_bigThree_delta_reg, y_bigThree_delta_reg, x_bigFour_delta_reg, y_bigFour_delta_reg,
        ship_y_t, ship_y_b, bigRockOne_y_b, bigRockOne_y_t, bigRockOne_x_l, bigRockOne_x_r, 
        bigRockTwo_y_b, bigRockTwo_y_t, bigRockTwo_x_l, bigRockTwo_x_r,
        bigRockThree_y_b, bigRockThree_y_t, bigRockThree_x_l, bigRockThree_x_r,
        bigRockFour_y_b, bigRockFour_y_t, bigRockFour_x_l, bigRockFour_x_r)
        begin
        x_big_delta_next <= x_big_delta_reg;
        y_big_delta_next <= y_big_delta_reg;
        x_bigTwo_delta_next <= x_bigTwo_delta_reg;
        y_bigTwo_delta_next <= y_bigTwo_delta_reg;
        x_bigThree_delta_next <= x_bigThree_delta_reg;
        y_bigThree_delta_next <= y_bigThree_delta_reg;
        x_bigFour_delta_next <= x_bigFour_delta_reg;
        y_bigFour_delta_next <= y_bigFour_delta_reg;
    -- Big Asteroid reached top, make offset positive
        if ( bigRockOne_y_t < 1 ) then
            y_big_delta_next <= BIGROCK_V_P;
    -- reached bottom, make negative
        elsif (bigRockOne_y_b > (MAX_Y - 1)) then
            y_big_delta_next <= BIGROCK_V_N;
            -- reach wall, bounce back
        elsif (bigRockOne_x_l <= WALL_X_R ) then
            x_big_delta_next <= BIGROCK_V_P;
            -- right corner of small asteroid inside bar
        elsif ((ship_x_l <= bigRockOne_x_r) and (bigRockOne_x_r <= ship_x_r)) then
            -- some portion of small asteroid hitting paddle, reverse dir
            if ((ship_y_t <= bigRockOne_y_b) and (bigRockOne_y_t <= ship_y_b)) then
                x_big_delta_next <= BIGROCK_V_N;
            end if;
        end if;

    -- 2nd BIG Asteroid reached top, make offset positive
        if ( bigRockTwo_y_t < 1 ) then
            y_bigTwo_delta_next <= BIGROCK_V_P;
    -- reached bottom, make negative
        elsif (bigRockTwo_y_b > (MAX_Y - 1)) then
            y_bigTwo_delta_next <= BIGROCK_V_N;
            -- reach wall, bounce back
        elsif (bigRockTwo_x_l <= WALL_X_R ) then
            x_bigTwo_delta_next <= BIGROCK_V_P;
            -- right corner of big asteroid inside bar
        elsif ((ship_x_l <= bigRockTwo_x_r) and (bigRockTwo_x_r <= ship_x_r)) then
            -- some portion of big asteroid hitting paddle, reverse dir
            if ((ship_y_t <= bigRockTwo_y_b) and (bigRockTwo_y_t <= ship_y_b)) then
                x_bigTwo_delta_next <= BIGROCK_V_N;
            end if;
        end if;

    -- 3rd BIG Asteroid reached top, make offset positive
        if ( bigRockThree_y_t < 1 ) then
            y_bigThree_delta_next <= BIGROCK_V_P;
    -- reached bottom, make negative
        elsif (bigRockThree_y_b > (MAX_Y - 1)) then
            y_bigThree_delta_next <= BIGROCK_V_N;
            -- reach wall, bounce back
        elsif (bigRockThree_x_l <= WALL_X_R ) then
            x_bigThree_delta_next <= BIGROCK_V_P;
            -- right corner of big asteroid inside bar
        elsif ((ship_x_l <= bigRockThree_x_r) and (bigRockThree_x_r <= ship_x_r)) then
            -- some portion of big asteroid hitting paddle, reverse dir
            if ((ship_y_t <= bigRockThree_y_b) and (bigRockThree_y_t <= ship_y_b)) then
                x_bigThree_delta_next <= BIGROCK_V_N;
            end if;
        end if;

    -- 4th BIG Asteroid reached top, make offset positive
        if ( bigRockFour_y_t < 1 ) then
            y_bigFour_delta_next <= BIGROCK_V_P;
    -- reached bottom, make negative
        elsif (bigRockFour_y_b > (MAX_Y - 1)) then
            y_bigFour_delta_next <= BIGROCK_V_N;
            -- reach wall, bounce back
        elsif (bigRockFour_x_l <= WALL_X_R ) then
            x_bigFour_delta_next <= BIGROCK_V_P;
            -- right corner of big asteroid inside bar
        elsif ((ship_x_l <= bigRockFour_x_r) and (bigRockFour_x_r <= ship_x_r)) then
            -- some portion of big asteroid hitting paddle, reverse dir
            if ((ship_y_t <= bigRockFour_y_b) and (bigRockFour_y_t <= ship_y_b)) then
                x_bigFour_delta_next <= BIGROCK_V_N;
            end if;
        end if;
    end process;

    process (missile_ball_x_reg, missile_ball_y_reg, refr_tick, shoot_btn, ship_y_reg)
        begin
        missile_ball_x_next <= missile_ball_x_reg; --default state

        if (refr_tick = '1') then
            -- Checking if firing button is pressed
            if (shoot_btn = '1') then
                -- Set starting position to the right side of the spaceship
                missile_ball_x_next <= ship_x_r + MISSILE_BALL_SIZE;
                missile_ball_y_next <= ship_y_reg + (SHIP_Y_SIZE / 2) - (MISSILE_BALL_SIZE / 2);
            elsif (missile_ball_x_l > 0) then
                -- Move missile projectile horizontally right to left
                missile_ball_x_next <= missile_ball_x_reg - MISSILE_V_P;
            end if;
        end if;

        missile_ball_x_reg <= missile_ball_x_next;
        missile_ball_y_reg <= missile_ball_y_next;
    end process;

    process (video_on, wall_on, ship_on, rd_smallRockOne_on, rd_smallRockTwo_on, 
        rd_smallRockThree_on, rd_smallRockFour_on, rd_smallRockFive_on, rd_smallRockSix_on, 
        rd_smallRockSeven_on, rd_bigRockOne_on, rd_bigRockTwo_on, rd_bigRockThree_on,
        rd_bigRockFour_on, wall_rgb, ship_rgb, smallRockOne_rgb, smallRockTwo_rgb, smallRockThree_rgb, 
        smallRockFour_rgb, smallRockFive_rgb, smallRockSix_rgb, smallRockSeven_rgb, 
        bigRockOne_rgb, bigRockTwo_rgb, bigRockThree_rgb, bigRockFour_rgb)
        begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (wall_on = '1') then
                graph_rgb <= wall_rgb;
            elsif (ship_on = '1') then
                graph_rgb <= ship_rgb;
            elsif (rd_missile_ball_on = '1') then
                graph_rgb <= missile_ball_rgb;
            elsif (rd_smallRockOne_on = '1') then
                graph_rgb <= smallRockOne_rgb;
            elsif (rd_smallRockTwo_on = '1') then
                graph_rgb <= smallRockTwo_rgb;
            elsif (rd_smallRockThree_on = '1') then
                graph_rgb <= smallRockThree_rgb;
            elsif (rd_smallRockFour_on = '1') then
                graph_rgb <= smallRockFour_rgb;
            elsif (rd_smallRockFive_on = '1') then
                graph_rgb <= smallRockFive_rgb;
            elsif (rd_smallRockSix_on = '1') then
                graph_rgb <= smallRockSix_rgb;
            elsif (rd_smallRockSeven_on = '1') then
                graph_rgb <= smallRockSeven_rgb;
            elsif (rd_bigRockOne_on = '1') then
                graph_rgb <= bigRockOne_rgb;
            elsif (rd_bigRockTwo_on = '1') then
                graph_rgb <= bigRockTwo_rgb;
            elsif (rd_bigRockThree_on = '1') then
                graph_rgb <= bigRockThree_rgb;
            elsif (rd_bigRockFour_on = '1') then
                graph_rgb <= bigRockFour_rgb;
            else
                graph_rgb <= "111"; -- white background
            end if;
        end if;
    end process;

    hit_cnt_next <= hit_cnt_reg+1 when ((ship_x_l < smallRockOne_x_r)
                    and (x_small_delta_reg = SMALLROCK_V_N)
                    and refr_tick = '1')
                    else hit_cnt_reg;

    hit_cnt <= std_logic_vector(hit_cnt_reg);

end sq_asteroids_arch;  