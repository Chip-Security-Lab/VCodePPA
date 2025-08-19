module sequence_clock_gen(
    input clk,
    input rst,
    input [7:0] pattern,
    output reg seq_out
);
    reg [2:0] bit_pos;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_pos <= 3'd0;
            seq_out <= 1'b0;
        end else begin
            seq_out <= pattern[bit_pos];
            bit_pos <= bit_pos + 3'd1;
        end
    end
endmodule