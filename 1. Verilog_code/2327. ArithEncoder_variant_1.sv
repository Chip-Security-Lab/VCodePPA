//SystemVerilog
module ArithEncoder #(PREC=8) (
    input clk, rst_n,
    input [7:0] data,
    output reg [PREC-1:0] code
);

reg [PREC-1:0] low;
reg [PREC-1:0] range;
reg [7:0] data_reg;
wire [PREC-1:0] range_data_div;
wire [PREC-1:0] range_minus_term;
wire [PREC-1:0] new_range;
wire [PREC-1:0] new_low;

// Register input data to break timing path
always @(posedge clk) begin
    if (!rst_n)
        data_reg <= 8'd0;
    else
        data_reg <= data;
end

// Pre-compute values combinationally
assign range_data_div = range * data_reg / 256;
assign range_minus_term = range - range_data_div;
assign new_low = low + range_minus_term;
assign new_range = range_data_div;

// Update state registers
always @(posedge clk) begin
    if (!rst_n) begin
        low <= 'd0;
        range <= 'd255;
        code <= 'd0;
    end else begin
        low <= new_low;
        range <= new_range;
        code <= new_low[PREC-1:0];
    end
end

endmodule