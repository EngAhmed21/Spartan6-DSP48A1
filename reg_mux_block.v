module reg_mux_block #(parameter BITS = 1, RSTTYPE = "SYNC", SELECTION = 1)(
    input clk, rst, en,
    input [BITS - 1 : 0] in,
    output [BITS - 1 : 0] out
);

    reg [BITS - 1 : 0] q_in;
    generate
        if (RSTTYPE == "ASYNC")
            always @(posedge clk, posedge rst) begin
                if (rst)
                    q_in <= 0;
                else if (en)
                    q_in <= in;
            end
        else if (RSTTYPE == "SYNC")
            always @(posedge clk) begin
                if (rst)
                    q_in <= 0;
                else if (en)
                    q_in <= in;
            end
    endgenerate
    
    assign out = SELECTION ? q_in : in;
endmodule