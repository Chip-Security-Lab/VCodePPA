module sawtooth_overflow(
    input clk,
    input rst,
    input [7:0] increment,
    output reg [7:0] sawtooth,
    output reg overflow
);
    always @(posedge clk) begin
        if (rst) begin
            sawtooth <= 8'd0;
            overflow <= 1'b0;
        end else begin
            {overflow, sawtooth} <= sawtooth + increment;
        end
    end
endmodule