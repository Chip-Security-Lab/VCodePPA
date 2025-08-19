module sync_decoder(
    input clk,
    input rst_n,
    input [2:0] address,
    output reg [7:0] decode_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            decode_out <= 8'b0;
        else
            decode_out <= (8'b1 << address);
    end
endmodule