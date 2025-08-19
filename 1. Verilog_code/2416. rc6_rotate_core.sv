module rc6_rotate_core (
    input clk, en,
    input [31:0] a_in, b_in,
    output reg [31:0] data_out
);
    wire [4:0] rot_offset = b_in[4:0];
    reg [31:0] rotated_val;
    
    always @(posedge clk) begin
        if (en) begin
            rotated_val <= (a_in << rot_offset) | (a_in >> (32 - rot_offset));
            data_out <= rotated_val + 32'h9E3779B9; // Golden ratio
        end
    end
endmodule
