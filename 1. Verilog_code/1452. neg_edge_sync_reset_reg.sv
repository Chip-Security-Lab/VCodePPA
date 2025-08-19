module neg_edge_sync_reset_reg(
    input clk, rst,
    input [15:0] d_in,
    input load,
    output reg [15:0] q_out
);
    always @(negedge clk) begin
        if (rst)
            q_out <= 16'b0;
        else if (load)
            q_out <= d_in;
    end
endmodule