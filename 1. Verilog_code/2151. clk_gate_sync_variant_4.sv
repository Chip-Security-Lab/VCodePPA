//SystemVerilog
module clk_gate_sync #(parameter WIDTH=4) (
    input clk, en,
    output reg [WIDTH-1:0] out
);

reg en_reg;
reg [WIDTH-1:0] incr_value;

// Register the enable signal
always @(posedge clk) begin
    en_reg <= en;
end

// Pre-compute the increment value
always @(posedge clk) begin
    incr_value <= out + 1;
end

// Use registered signals for output update
always @(posedge clk) begin
    if (en_reg) begin
        out <= incr_value;
    end
    else begin
        out <= out;
    end
end

endmodule