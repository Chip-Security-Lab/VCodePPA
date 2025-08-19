module gray_ring_counter (
    input clk, rst_n,
    output reg [3:0] gray_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) gray_out <= 4'b0001;
    else gray_out <= {gray_out[0], gray_out[3:1] ^ {2'b00, gray_out[0]}};
end
endmodule
