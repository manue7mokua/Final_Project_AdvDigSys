library ieee;
use ieee.std_logic_1164.all;

entity alien_top_st is
    port(
        clk, reset: in std_logic;
        btn: in std_logic_vector(3 downto 0);
        shoot_btn: in std_logic;
        hsync, vsync: out std_logic;
        rgb_top: out std_logic_vector(2 downto 0);
        vga_pixel_tick: out std_logic;
        blank: out std_logic;
        comp_sync: out std_logic
    );
end alien_top_st;

architecture arch of alien_top_st is
    signal pixel_x, pixel_y: std_logic_vector(9 downto 0);
    signal video_on: std_logic;
    signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
    signal rgb: std_logic_vector(2 downto 0);
    signal alien_graph_rgb: std_logic_vector(2 downto 0);
    signal hit_cnter_rgb: std_logic_vector(2 downto 0);
    signal hit_cnt: std_logic_vector(2 downto 0);
    signal sq_hit_cnter_on: std_logic;
    signal p_tick: std_logic;

    begin

    -- instantiate VGA sync
    vga_sync_unit: entity work.vga_sync
        port map(clk=>clk, reset=>reset, hsync=>hsync,
            vsync=>vsync, comp_sync=>comp_sync,
            video_on=>video_on, p_tick=>p_tick,
            pixel_x=>pixel_x, pixel_y=>pixel_y);
    -- instantiate pixel generation circuit
    alien_graph_st_unit: entity
        work.alien_graph_st(sq_asteroids_arch)
        port map(clk=>clk, reset=>reset, btn=>btn, shoot_btn=>shoot_btn,
            video_on=>video_on, pixel_x=>pixel_x,
            pixel_y=>pixel_y, graph_rgb=>rgb_next);

    counter_disp_unit: entity work.score_counter_disp
        port map(pixel_x=>pixel_x, pixel_y=>pixel_y,
            hit_cnt=>hit_cnt, sq_hit_cnter_on_output=>sq_hit_cnter_on,
            graph_rgb=>hit_cnter_rgb);

    vga_pixel_tick <= p_tick;
-- Set the high order bits of the video DAC for each
-- of the three colors
    rgb_top <= rgb;

    vga_pixel_tick <= p_tick;

-- rgb buffer, graph_rgb is routed to the output through
-- an output buffer -- loaded when p_tick = ?1?.
-- This syncs. rgb output with buffered hsync/vsync sig.
    process (clk)
        begin
        if (clk'event and clk = '1') then
            if (p_tick = '1') then
                rgb_reg <= rgb_next;
            end if;
        end if;
    end process;

    rgb <= rgb_reg;

    rgb_next <= hit_cnter_rgb when sq_hit_cnter_on = '1' else
                    alien_graph_rgb;

    blank <= video_on;
end arch;
