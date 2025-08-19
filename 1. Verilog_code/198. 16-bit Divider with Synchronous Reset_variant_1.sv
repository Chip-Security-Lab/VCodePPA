//SystemVerilog
module divider_sync_reset (
    input clk,
    input reset,
    input [15:0] dividend,
    input [15:0] divisor,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        quotient <= 16'b0;
        remainder <= 16'b0;
    end else begin
        quotient <= dividend / divisor;
        remainder <= dividend % divisor;
    end
end

endmodule