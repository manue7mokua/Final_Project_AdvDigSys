library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- btn connected to up/down pushbuttons for now but
-- eventually will get data from UART

entity alien_graph_st is
    port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(3 downto 0);
        video_on: in std_logic;
        pixel_x, pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
    );
end alien_graph_st;

architecture sq_asteroids_arch of alien_graph_st is

    -- Signal used to control speed of small_asteroid and how
    -- often pushbuttons are checked for paddle movement.
    signal refr_tick: std_logic;

    -- x, y coordinates (0,0 to (639, 479)
    signal pix_x, pix_y: unsigned(9 downto 0);

    -- screen dimensions
    constant MAX_X: integer := 640;
    constant MAX_Y: integer := 480;

    -- wall left and right boundary of wall (full height)
    constant WALL_X_L: integer := 32;
    constant WALL_X_R: integer := 35;

-- paddle left, right, top, bottom and height left &
-- right are constant. top & bottom are signals to
-- allow movement. bar_y_t driven by reg below.
    signal bar_x_l, bar_x_r: unsigned(9 downto 0);
    signal bar_y_t, bar_y_b: unsigned(9 downto 0);
    constant BAR_X_SIZE: integer := 8;
    constant BAR_Y_SIZE: integer := 16;

-- reg to track top boundary
    signal bar_x_reg, bar_x_next: unsigned(9 downto 0);
    signal bar_y_reg, bar_y_next: unsigned(9 downto 0);

-- bar moving velocity when a button is pressed
-- the amount the bar is moved.
    constant BAR_V: integer:= 2;

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

-- reg to track small aestoroids speeds
    signal x_small_delta_reg, x_small_delta_next: unsigned(9 downto 0);
    signal y_small_delta_reg, y_small_delta_next: unsigned(9 downto 0);

    signal x_smallTwo_delta_reg, x_smallTwo_delta_next: unsigned(9 downto 0);
    signal y_smallTwo_delta_reg, y_smallTwo_delta_next: unsigned(9 downto 0);

    signal x_smallThree_delta_reg, x_smallThree_delta_next: unsigned(9 downto 0);
    signal y_smallThree_delta_reg, y_smallThree_delta_next: unsigned(9 downto 0);
--reg to track big aestoroids speeds
    signal x_big_delta_reg, x_big_delta_next: unsigned(9 downto 0);
    signal y_big_delta_reg, y_big_delta_next: unsigned(9 downto 0);

    signal x_bigTwo_delta_reg, x_bigTwo_delta_next: unsigned(9 downto 0);
    signal y_bigTwo_delta_reg, y_bigTwo_delta_next: unsigned(9 downto 0);

-- small asteroid movement can be pos or neg
    constant SMALLROCK_V_P: unsigned(9 downto 0):= to_unsigned(2,10);
    constant SMALLROCK_V_N: unsigned(9 downto 0):= unsigned(to_signed(-2,10));

-- round small asteroid image
    type rom_type_smallRockOne is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKONE_ROM: rom_type_smallRockOne:= (
        "00111100",
        "01111110",
        "01100110",
        "11100111",
        "11100111",
        "01100110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockTwo is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKTWO_ROM: rom_type_smallRockTwo:= (
        "00111100",
        "01111110",
        "01100110",
        "11100111",
        "11100111",
        "01100110",
        "01111110",
        "00111100"
    );

    type rom_type_smallRockThree is array(0 to 7) of std_logic_vector(0 to 7);
    constant SMALLROCKTHREE_ROM: rom_type_smallRockThree:= (
        "00111100",
        "01111110",
        "01100110",
        "11100111",
        "11100111",
        "01100110",
        "01111110",
        "00111100"
    );

    signal rom_small_addr, rom_small_col: unsigned(2 downto 0);
    signal rom_small_addr_two, rom_small_col_two: unsigned(2 downto 0);
    signal rom_small_addr_three, rom_small_col_three: unsigned(2 downto 0);
    signal rom_big_addr, rom_big_col: unsigned(3 downto 0);
    signal rom_big_addr_two, rom_big_col_two: unsigned(3 downto 0);
    signal rom_small_data, rom_small_data_two, rom_small_data_three: std_logic_vector(7 downto 0);
    signal rom_big_data, rom_big_data_two: std_logic_vector(15 downto 0);
    signal rom_small_bit, rom_small_bit_two, rom_small_bit_three: std_logic;
    signal rom_big_bit, rom_big_bit_two: std_logic;

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

-- Big Asteroid movement can be pos or neg
    constant BIGROCK_V_P: unsigned(9 downto 0) := to_unsigned(1, 10);
    constant BIGROCK_V_N: unsigned(9 downto 0) := unsigned(to_signed(-1, 10));

-- Big Asteroid image
    type rom_type_bigRockOne is array (0 to 15) of std_logic_vector(0 to 15);
    constant BIGROCKONE_ROM: rom_type_bigRockOne:= (
        "0001111111111000",
        "0001111111111000",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "1111111111111111",
        "1111110000111111",
        "1111110000111111",
        "1111110000111111",
        "1111110000111111",
        "1111111111111111",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0001111111111000",
        "0001111111111000"
    );

    type rom_type_bigRockTwo is array (0 to 15) of std_logic_vector(0 to 15);
    constant BIGROCKTWO_ROM: rom_type_bigRockTwo:= (
        "0001111111111000",
        "0001111111111000",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "1111111111111111",
        "1111110000111111",
        "1111110000111111",
        "1111110000111111",
        "1111110000111111",
        "1111111111111111",
        "0011111111111100",
        "0011111111111100",
        "0011111111111100",
        "0001111111111000",
        "0001111111111000"
    );

-- object output signals -- new signal to indicate if
-- scan coord is within small asteroid
    signal wall_on, bar_on: std_logic;
    signal sq_smallRockOne_on, sq_smallRockTwo_on, sq_smallRockThree_on, sq_bigRockOne_on, sq_bigRockTwo_on: std_logic;
    signal rd_smallRockOne_on, rd_smallRockTwo_on, rd_smallRockThree_on, rd_bigRockOne_on, rd_bigRockTwo_on: std_logic;

    signal wall_rgb, bar_rgb: std_logic_vector(2 downto 0);
    signal smallRockOne_rgb, smallRockTwo_rgb, smallRockThree_rgb: std_logic_vector(2 downto 0);
    signal bigRockOne_rgb, bigRockTwo_rgb: std_logic_vector(2 downto 0);

-- ====================================================
    begin
    process (clk, reset)
        begin
        if (reset = '1') then
            bar_x_reg <= (others => '0');
            bar_y_reg <= (others => '0');
            smallRockOne_x_reg <= (others => '0');
            smallRockOne_y_reg <= (others => '0');
            smallRockTwo_x_reg <= (others => '0');
            smallRockTwo_y_reg <= (others => '0');
            smallRockThree_x_reg <= (others => '0');
            smallRockThree_y_reg <= (others => '0');
            bigRockOne_x_reg <= (others => '0');
            bigRockOne_y_reg <= (others => '0');
            bigRockTwo_x_reg <= (others => '0');
            bigRockTwo_y_reg <= (others => '0');
            x_small_delta_reg <= ("0000000100");
            y_small_delta_reg <= ("0000000100");
            x_smallTwo_delta_reg <= ("0000000100");
            y_smallTwo_delta_reg <= ("0000000100");
            x_smallThree_delta_reg <= ("0000000100");
            y_smallThree_delta_reg <= ("0000000100");
            x_big_delta_reg <= ("0000000100");
            y_big_delta_reg <= ("0000000100");
            x_bigTwo_delta_reg <= ("0000000100");
            y_bigTwo_delta_reg <= ("0000000100");
        elsif (clk'event and clk = '1') then
            bar_x_reg <= bar_x_next;
            bar_y_reg <= bar_y_next;
            smallRockOne_x_reg <= smallRockOne_x_next;
            smallRockOne_y_reg <= smallRockOne_y_next;
            smallRockTwo_x_reg <= smallRockTwo_x_next;
            smallRockTwo_y_reg <= smallRockTwo_y_next;
            smallRockThree_x_reg <= smallRockThree_x_next;
            smallRockThree_y_reg <= smallRockThree_y_next;
            bigRockOne_x_reg <= bigRockOne_x_next;
            bigRockOne_y_reg <= bigRockOne_y_next;
            bigRockTwo_x_reg <= bigRockTwo_x_next;
            bigRockTwo_y_reg <= bigRockTwo_y_next;
            x_small_delta_reg <= x_small_delta_next;
            y_small_delta_reg <= y_small_delta_next;
            x_smallTwo_delta_reg <= x_smallTwo_delta_next;
            y_smallTwo_delta_reg <= y_smallTwo_delta_next;
            x_smallThree_delta_reg <= x_smallThree_delta_next;
            y_smallThree_delta_reg <= y_smallThree_delta_next;
            x_big_delta_reg <= x_big_delta_next;
            y_big_delta_reg <= y_big_delta_next;
            x_bigTwo_delta_reg <= x_bigTwo_delta_next;
            y_bigTwo_delta_reg <= y_bigTwo_delta_next;
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

-- pixel within paddle
    bar_x_l <= bar_x_reg;
    bar_x_r <= bar_x_l + BAR_X_SIZE - 1;
    bar_y_t <= bar_y_reg;
    bar_y_b <= bar_y_t + BAR_Y_SIZE - 1;
    bar_on <= '1' when (bar_x_l <= pix_x) and
        (pix_x <= bar_x_r) and (bar_y_t <= pix_y) and
        (pix_y <= bar_y_b) else '0';
    bar_rgb <= "101"; -- cyan

-- Process bar movement requests (UP and DOWN)
    process( bar_y_reg, bar_y_b, bar_y_t, refr_tick, btn)
        begin
        bar_y_next <= bar_y_reg; -- no move
        if ( refr_tick = '1' ) then
            -- if btn 1 pressed and paddle not at bottom yet
            if ( btn(1) = '1' and bar_y_b < (MAX_Y - 1 - BAR_V)) then
                bar_y_next <= bar_y_reg + BAR_V; -- Move down
            -- if btn 1 pressed and bar not at top yet
            elsif ( btn(0) = '1' and bar_y_t > BAR_V) then
                bar_y_next <= bar_y_reg - BAR_V; -- Move up
            end if;
        end if;
    end process;

-- Process bar movement requests (LEFT and RIGHT)
    process( bar_x_reg, bar_x_l, bar_x_r, refr_tick, btn)
        begin
        bar_x_next <= bar_x_reg; -- no move
        if ( refr_tick = '1' ) then
            -- if btn 1 pressed and paddle not at most right yet
            if ( btn(3) = '1' and bar_x_r < (MAX_X - 1 - BAR_V)) then
                bar_x_next <= bar_x_reg + BAR_V; -- Move right
            -- if btn 1 pressed and bar not at most left yet
            elsif ( btn(2) = '1' and bar_x_l > BAR_V) then
                bar_x_next <= bar_x_reg - BAR_V; -- Move left
            end if;
        end if;
    end process;

    -- set coordinates of 1st square small asteroid.
    smallRockOne_x_l <= smallRockOne_x_reg;
    smallRockOne_y_t <= smallRockOne_y_reg;
    smallRockOne_x_r <= smallRockOne_x_l + (SMALLROCK_ONE_SIZE - 1);
    smallRockOne_y_b <= smallRockOne_y_t + (SMALLROCK_ONE_SIZE - 1);

    -- set coordinates of 2nd square small asteroid.
    smallRockTwo_x_l <= smallRockTwo_x_reg;
    smallRockTwo_y_t <= smallRockTwo_y_reg;
    smallRockTwo_x_r <= smallRockTwo_x_l + (SMALLROCK_TWO_SIZE - 3);
    smallRockTwo_y_b <= smallRockTwo_y_t + (SMALLROCK_TWO_SIZE - 3);

    -- set coordinates of 3rd square small asteroid.
    smallRockThree_x_l <= smallRockThree_x_reg;
    smallRockThree_y_t <= smallRockThree_y_reg;
    smallRockThree_x_r <= smallRockThree_x_l + (SMALLROCK_THREE_SIZE - 5);
    smallRockThree_y_b <= smallRockThree_y_t + (SMALLROCK_THREE_SIZE - 5);

    -- set coordinates of big asteroid
    bigRockOne_x_l <= bigRockOne_x_reg;
    bigRockOne_y_t <= bigRockOne_y_reg;
    bigRockOne_x_r <= bigRockOne_x_l + BIGROCK_ONE_SIZE - 7;
    bigRockOne_y_b <= bigRockOne_y_t + BIGROCK_ONE_SIZE - 7;

    -- set coordinates of big asteroid
    bigRockTwo_x_l <= bigRockTwo_x_reg;
    bigRockTwo_y_t <= bigRockTwo_y_reg;
    bigRockTwo_x_r <= bigRockTwo_x_l + BIGROCK_TWO_SIZE - 4;
    bigRockTwo_y_b <= bigRockTwo_y_t + BIGROCK_TWO_SIZE - 4;

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

    -- pixel within 1st BIG asteroid
    sq_bigRockOne_on <= '1' when (bigRockOne_x_l <= pix_x) and
        (pix_x <= bigRockOne_x_r) and (bigRockOne_y_t <= pix_y) and
        (pix_y <= bigRockOne_y_b) else '0';

    -- pixel within 2nd BIG asteroid
    sq_bigRockTwo_on <= '1' when (bigRockTwo_x_l <= pix_x) and
        (pix_x <= bigRockTwo_x_r) and (bigRockTwo_y_t <= pix_y) and
        (pix_y <= bigRockTwo_y_b) else '0';

-- map scan coord to ROM addr/col -- use low order three
-- bits of pixel and small asteroid positions.
-- ROM row
    rom_small_addr <= pix_y(2 downto 0) - smallRockOne_y_t(2 downto 0);
    rom_small_addr_two <= pix_y(2 downto 0) - smallRockTwo_y_t(2 downto 0);
    rom_small_addr_three <= pix_y(2 downto 0) - smallRockThree_y_t(2 downto 0);
    rom_big_addr <= pix_y(3 downto 0) - bigRockOne_y_t(3 downto 0);
    rom_big_addr_two <= pix_y(3 downto 0) - bigRockTwo_y_t(3 downto 0);
-- ROM column
    rom_small_col <= pix_x(2 downto 0) - smallRockOne_x_l(2 downto 0);
    rom_small_col_two <= pix_x(2 downto 0) - smallRockTwo_x_l(2 downto 0);
    rom_small_col_three <= pix_x(2 downto 0) - smallRockThree_x_l(2 downto 0);
    rom_big_col <= pix_x(3 downto 0) - bigRockOne_x_l(3 downto 0);
    rom_big_col_two <= pix_x(3 downto 0) - bigRockTwo_x_l(3 downto 0);
-- Get row data
    rom_small_data <= SMALLROCKONE_ROM(to_integer(rom_small_addr));
    rom_small_data_two <= SMALLROCKTWO_ROM(to_integer(rom_small_addr_two));
    rom_small_data_three <= SMALLROCKTHREE_ROM(to_integer(rom_small_addr_three));
    rom_big_data <= BIGROCKONE_ROM(to_integer(rom_big_addr));
    rom_big_data_two <= BIGROCKONE_ROM(to_integer(rom_big_addr_two));
-- Get column bit
    rom_small_bit <= rom_small_data(to_integer(rom_small_col));
    rom_small_bit_two <= rom_small_data_two(to_integer(rom_small_col_two));
    rom_small_bit_three <= rom_small_data_three(to_integer(rom_small_col_three));
    rom_big_bit <= rom_big_data(to_integer(rom_big_col));
    rom_big_bit_two <= rom_big_data_two(to_integer(rom_big_col_two));

    --------------------------------------------------------------------------------------
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

-- Turn big asteroid on only if within square and ROM bit is 1
    rd_bigRockOne_on <= '1' when (sq_bigRockOne_on = '1') and
    (rom_big_bit = '1') else '0';
    bigRockOne_rgb <= "000"; -- black

    rd_bigRockTwo_on <= '1' when (sq_bigRockTwo_on = '1') and
    (rom_big_bit_two = '1') else '0';
    bigRockTwo_rgb <= "000"; -- black

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

-- Update the big asteroid position 60 times per second
    bigRockOne_x_next <= bigRockOne_x_reg + x_big_delta_reg when
        refr_tick = '1' else bigRockOne_x_reg;
    bigRockOne_y_next <= bigRockOne_y_reg + y_big_delta_reg when
        refr_tick = '1' else bigRockOne_y_reg;

    bigRockTwo_x_next <= bigRockTwo_x_reg + x_bigTwo_delta_reg when
        refr_tick = '1' else bigRockTwo_x_reg;
    bigRockTwo_y_next <= bigRockTwo_y_reg + y_bigTwo_delta_reg when
        refr_tick = '1' else bigRockTwo_y_reg;

-- Set the value of the next small asteroid position according to
-- the boundaries.
    process(x_small_delta_reg, y_small_delta_reg, x_smallTwo_delta_reg, y_smallTwo_delta_reg,
        x_smallThree_delta_reg, y_smallThree_delta_reg, smallRockOne_y_t, smallRockOne_x_l,
        smallRockOne_x_r, smallRockOne_y_b, smallRockTwo_y_t, smallRockTwo_x_l,
        smallRockTwo_x_r, smallRockTwo_y_b, smallRockThree_y_t, smallRockThree_x_l,
        smallRockThree_x_r, smallRockThree_y_b, bar_y_t, bar_y_b)
        begin
        x_small_delta_next <= x_small_delta_reg;
        y_small_delta_next <= y_small_delta_reg;
        x_smallTwo_delta_next <= x_smallTwo_delta_reg;
        y_smallTwo_delta_next <= y_smallTwo_delta_reg;
        x_smallThree_delta_next <= x_smallThree_delta_reg;
        y_smallThree_delta_next <= y_smallThree_delta_reg;
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
        elsif ((bar_x_l <= smallRockOne_x_r) and (smallRockOne_x_r <= bar_x_r)) then
            -- some portion of small asteroid hitting paddle, reverse dir
            if ((bar_y_t <= smallRockOne_y_b) and (smallRockOne_y_t <= bar_y_b)) then
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
        elsif ((bar_x_l <= smallRockTwo_x_r) and (smallRocktwo_x_r <= bar_x_r)) then
        -- some portion of small asteroid hitting paddle, reverse dir
            if ((bar_y_t <= smallRockTwo_y_b) and (smallRockTwo_y_t <= bar_y_b)) then
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
        elsif ((bar_x_l <= smallRockThree_x_r) and (smallRockThree_x_r <= bar_x_r)) then
    -- some portion of small asteroid hitting paddle, reverse dir
            if ((bar_y_t <= smallRockThree_y_b) and (smallRockThree_y_t <= bar_y_b)) then
                x_smallThree_delta_next <= SMALLROCK_V_N;
            end if;
        end if;
    end process;

    process(x_big_delta_reg, y_big_delta_reg, x_bigTwo_delta_reg, y_bigTwo_delta_reg,
        bar_y_t, bar_y_b, bigRockOne_y_b, bigRockOne_y_t, bigRockOne_x_l, bigRockOne_x_r, 
        bigRockTwo_y_b, bigRockTwo_y_t, bigRockTwo_x_l, bigRockTwo_x_r)
        begin
        x_big_delta_next <= x_big_delta_reg;
        y_big_delta_next <= y_big_delta_reg;
        x_bigTwo_delta_next <= x_bigTwo_delta_reg;
        y_bigTwo_delta_next <= y_bigTwo_delta_reg;
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
        elsif ((bar_x_l <= bigRockOne_x_r) and (bigRockOne_x_r <= bar_x_r)) then
            -- some portion of small asteroid hitting paddle, reverse dir
            if ((bar_y_t <= bigRockOne_y_b) and (bigRockOne_y_t <= bar_y_b)) then
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
        elsif ((bar_x_l <= bigRockTwo_x_r) and (bigRockTwo_x_r <= bar_x_r)) then
            -- some portion of big asteroid hitting paddle, reverse dir
            if ((bar_y_t <= bigRockTwo_y_b) and (bigRockTwo_y_t <= bar_y_b)) then
                x_bigTwo_delta_next <= BIGROCK_V_N;
            end if;
        end if;
    end process;

    process (video_on, wall_on, bar_on, rd_smallRockOne_on, rd_smallRockTwo_on, 
        rd_smallRockThree_on, rd_bigRockOne_on, rd_bigRockTwo_on, wall_rgb, bar_rgb, 
        smallRockOne_rgb, smallRockTwo_rgb, smallRockThree_rgb, bigRockOne_rgb, bigRockTwo_rgb)
        begin
        if (video_on = '0') then
            graph_rgb <= "000"; -- blank
        else
            if (wall_on = '1') then
                graph_rgb <= wall_rgb;
            elsif (bar_on = '1') then
                graph_rgb <= bar_rgb;
            elsif (rd_smallRockOne_on = '1') then
                graph_rgb <= smallRockOne_rgb;
            elsif (rd_smallRockTwo_on = '1') then
                graph_rgb <= smallRockTwo_rgb;
            elsif (rd_smallRockThree_on = '1') then
                graph_rgb <= smallRockThree_rgb;
            elsif (rd_bigRockOne_on = '1') then
                graph_rgb <= bigRockOne_rgb;
            elsif (rd_bigRockTwo_on = '1') then
                graph_rgb <= bigRockTwo_rgb;
            else
                graph_rgb <= "111"; -- white background
            end if;
        end if;
    end process;
end sq_asteroids_arch;  