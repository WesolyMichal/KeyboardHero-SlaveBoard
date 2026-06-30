module vga_timing_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 15;     // ok 65 MHz bo period 15,3846...
    localparam RST_START_TIME  = 1.25*CLK_PERIOD;
    localparam RST_ACTIVE_TIME = 2.00*CLK_PERIOD;


    /**
     * Local variables and signals
     */

    logic clk;
    logic rst_n;

    wire vga_if vga_out;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    /**
     * Reset generation
     */

    initial begin
        rst_n = 1'b1;
        #(RST_START_TIME) rst_n = 1'b0;
        rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;
    end


    /**
     * Dut placement
     */

    vga_timing dut(
        .clk,
        .rst_n,
        .vga_out
    );

    /**
     * Tasks and functions
     */

    // Here you can declare tasks with immediate assertions (assert).


    /**
     * Assertions
     */

     assert property (
        /* run assertion at each positive clock edge: */
        @(posedge clk)
        /* except during reset (optional): */
        disable iff (!rst_n || $realtime < RST_START_TIME)
        /* check whether this condition is true: */
        vga_out.hcount < HOR_TOTAL_TIME
    ) else begin
        /* if condition is not true, display error message */
        $error("vga_out.hcount: max value exceeded");
    end
    
    /* vga_out.hcount : zero after max value */
    assert property (
        @(posedge clk)
        vga_out.hcount == (HOR_TOTAL_TIME - 1) |=> vga_out.hcount == 0
    ) else begin
        $error("vga_out.hcount: return to 0 after expected max value failed");
    end
    
    /* vga_out.hcount : incrementation with every clock tick */
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (vga_out.hcount < HOR_TOTAL_TIME - 1) |=> (vga_out.hcount == $past(vga_out.hcount) + 1)
    ) else begin
        $error("vga_out.hcount: increment at every clk failed");
    end
    
    /* vga_out.vcount : max value */
    assert property (
        @(posedge clk)
        disable iff (!rst_n || $realtime < RST_START_TIME)
        vga_out.vcount < VER_TOTAL_TIME
    ) else begin
        $error("vga_out.vcount: max value exceeded");
    end
    
    /* vga_out.vcount : zero after max value */
    assert property (
        @(posedge clk)
        vga_out.vcount == (VER_TOTAL_TIME - 1) |=> ##(HOR_TOTAL_TIME - 1) vga_out.vcount == 0
    ) else begin
        $error("vga_out.vcount: return to 0 after expected max value failed");
    end
    
    /* vga_out.vcount : incrementation with every clock tick */
    assert property (
        @(posedge clk)
        (vga_out.hcount == HOR_TOTAL_TIME - 1) && vga_out.vcount < (VER_TOTAL_TIME - 1) |=> (vga_out.vcount == $past(vga_out.vcount) + 1)
    ) else begin
        $error("vga_out.vcount: increment at vga_out.hcount reset failed");
    end
    
    /* vga_out.hblnk : set */
    assert property (
        @(posedge clk)
        vga_out.hcount >= HOR_BLANK_START && vga_out.hcount < HOR_BLANK_START + HOR_BLANK_TIME - 1 |-> vga_out.hblnk
    ) else begin
        $error("vga_out.hblnk: set failed");
    end
    
    /* vga_out.hblnk : clear */
    assert property (
        @(posedge clk)
        vga_out.hcount < HOR_BLANK_START |-> !vga_out.hblnk
    ) else begin
        $error("vga_out.hblnk: clear failed");
    end
    
    /* vga_out.vblnk : set */
    assert property (
        @(posedge clk)
        vga_out.vcount >= VER_BLANK_START && vga_out.vcount < VER_BLANK_START + VER_BLANK_TIME - 1 |-> vga_out.vblnk
    ) else begin
        $error("vga_out.vblnk set failed");
    end
    
    /* vga_out.vblnk : clear */
    assert property (
        @(posedge clk)
        vga_out.vcount < VER_BLANK_START |-> !vga_out.vblnk
    ) else begin
        $error("vga_out.vblnk: clear failed");
    end
    
    /* vga_out.hsync : set */
    assert property (
        @(posedge clk)
        vga_out.hcount >= HOR_SYNC_START && vga_out.hcount < HOR_SYNC_START + HOR_SYNC_TIME - 1 |-> vga_out.hsync
    ) else begin
        $error("vga_out.hsync: set failed");
    end
    
    /* vga_out.hsync : clear */
    assert property (
        @(posedge clk)
        (vga_out.hcount < HOR_SYNC_START) || (vga_out.hcount > (HOR_SYNC_START + HOR_SYNC_TIME - 1)) |-> !vga_out.hsync
    ) else begin
        $error("vga_out.hsync: clear failed");
    end
    
    /* vga_out.vsync : set */
    assert property (
        @(posedge clk)
        vga_out.vcount >= VER_SYNC_START && vga_out.vcount < VER_SYNC_START + VER_SYNC_TIME - 1 |-> vga_out.vsync
    ) else begin
        $error("vga_out.vsync: set failed");
    end
    
    /* vga_out.vsync : clear */
    assert property (
        @(posedge clk)
        vga_out.vcount < VER_SYNC_START || vga_out.vcount > VER_SYNC_START + VER_SYNC_TIME - 1 |-> !vga_out.vsync
    ) else begin
        $error("vga_out.vsync: clear failed");
    end


    /**
     * Main test
     */

    initial begin
        /*
        @(negedge rst_n);
        @(posedge rst_n);

        wait (vga_out.vsync == 1'b0);
        @(negedge vga_out.vsync);
        @(negedge vga_out.vsync);
        */
        #20ms;
        $finish;
    end



endmodule
