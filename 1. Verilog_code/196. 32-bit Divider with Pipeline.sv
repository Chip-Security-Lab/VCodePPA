module divider_pipeline_32bit (
    input clk,
    input [31:0] dividend,
    input [31:0] divisor,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

always @(posedge clk) begin
    quotient <= dividend / divisor;
    remainder <= dividend % divisor;
end

endmodule