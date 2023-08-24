module reg_mux_block_tb ();
    localparam BITS = 1;

    reg clk, rst, en;
    reg [BITS - 1 : 0] in;
    wire [BITS - 1 : 0] out_async_reg, out_sync_reg, out_no_reg;

    reg_mux_block #(.BITS(BITS), .RSTTYPE("ASYNC"), .SELECTION(1)) uut_async_reg (.clk(clk), .rst(rst), .en(en), .in(in), .out(out_async_reg));
    reg_mux_block #(.BITS(BITS), .RSTTYPE("SYNC"), .SELECTION(1)) uut_sync_reg (.clk(clk), .rst(rst), .en(en), .in(in), .out(out_sync_reg));
    reg_mux_block #(.BITS(BITS), .RSTTYPE("SYNC"), .SELECTION(0)) uut_no_reg (.clk(clk), .rst(rst), .en(en), .in(in), .out(out_no_reg));    

    localparam CLK_PERIOD = 10;
    always
        #(CLK_PERIOD / 2)   clk = ~clk;

    initial begin
        clk = 1'b1;     rst = 1'b1;
        en = 1'b0;      in = 1'b1;

        @(negedge clk)  rst = 1'b0;
        
        @(negedge clk)  en = 1'b1;

        repeat(12) @(negedge clk)  in = $random;

        @(negedge clk)  rst = 1'b1;

        @(negedge clk)  $stop;
    end
endmodule