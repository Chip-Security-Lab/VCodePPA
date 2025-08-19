module decoder_sync_reg (
    input clk, rst_n, en,
    input [3:0] addr,
    output reg [15:0] decoded
);
    always @(posedge clk or negedge rst_n)
        if (!rst_n) decoded <= 16'h0;
        else if (en) decoded <= (1'b1 << addr);
endmodule