//SystemVerilog
// Range threshold register module with fanout buffers
module RangeThresholdReg #(
    parameter WIDTH = 8
)(
    input clk,
    input wr_en,
    input [WIDTH-1:0] new_low,
    input [WIDTH-1:0] new_high,
    output [WIDTH-1:0] current_low,
    output [WIDTH-1:0] current_high
);

reg [WIDTH-1:0] current_low_reg;
reg [WIDTH-1:0] current_high_reg;

// First stage registers
reg [WIDTH-1:0] new_low_reg;
reg [WIDTH-1:0] new_high_reg;
reg wr_en_reg;

// Second stage registers for fanout buffering
reg [WIDTH-1:0] current_low_buf;
reg [WIDTH-1:0] current_high_buf;

always @(posedge clk) begin
    // First stage
    new_low_reg <= new_low;
    new_high_reg <= new_high;
    wr_en_reg <= wr_en;
    
    // Second stage
    if(wr_en_reg) begin
        current_low_reg <= new_low_reg;
        current_high_reg <= new_high_reg;
    end
    
    // Fanout buffer stage
    current_low_buf <= current_low_reg;
    current_high_buf <= current_high_reg;
end

assign current_low = current_low_buf;
assign current_high = current_high_buf;

endmodule

// Range comparison module with balanced paths
module RangeComparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] current_low,
    input [WIDTH-1:0] current_high,
    output reg out_flag
);

// Intermediate comparison results
reg low_compare;
reg high_compare;

always @(*) begin
    // Split comparison into two parallel paths
    low_compare = (data_in >= current_low);
    high_compare = (data_in <= current_high);
    
    // Combine results
    out_flag = low_compare && high_compare;
end

endmodule

// Top level module with parameter buffering
module RangeDetector_DynamicTh #(
    parameter WIDTH = 8
)(
    input clk,
    input wr_en,
    input [WIDTH-1:0] new_low,
    input [WIDTH-1:0] new_high,
    input [WIDTH-1:0] data_in,
    output out_flag
);

// Parameter buffering
localparam WIDTH_BUFF = WIDTH;

wire [WIDTH_BUFF-1:0] current_low;
wire [WIDTH_BUFF-1:0] current_high;

RangeThresholdReg #(
    .WIDTH(WIDTH_BUFF)
) threshold_reg (
    .clk(clk),
    .wr_en(wr_en),
    .new_low(new_low),
    .new_high(new_high),
    .current_low(current_low),
    .current_high(current_high)
);

RangeComparator #(
    .WIDTH(WIDTH_BUFF)
) comparator (
    .data_in(data_in),
    .current_low(current_low),
    .current_high(current_high),
    .out_flag(out_flag)
);

endmodule