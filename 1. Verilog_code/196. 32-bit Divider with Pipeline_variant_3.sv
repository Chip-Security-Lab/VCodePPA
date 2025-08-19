//SystemVerilog
module divider_pipeline_32bit (
    input clk,
    input valid,
    input [31:0] dividend,
    input [31:0] divisor,
    output reg ready,
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

reg [31:0] internal_dividend;
reg [31:0] internal_divisor;
reg processing;

always @(posedge clk) begin
    if (valid && !processing) begin
        internal_dividend <= dividend;
        internal_divisor <= divisor;
        processing <= 1'b1;
        ready <= 1'b0; // Not ready until processing is done
    end

    if (processing) begin
        quotient <= internal_dividend / internal_divisor;
        remainder <= internal_dividend % internal_divisor;
        processing <= 1'b0;
        ready <= 1'b1; // Ready to accept new data
    end
end

endmodule