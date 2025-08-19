module sync_decoder_async_reset (
    input clk,
    input arst_n,
    input [2:0] address,
    output reg [7:0] cs_n
);
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            cs_n <= 8'hFF;
        else
            cs_n <= ~(8'h01 << address);
    end
endmodule