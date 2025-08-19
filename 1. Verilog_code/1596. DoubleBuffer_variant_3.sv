//SystemVerilog
// Single buffer module
module SingleBuffer #(
    parameter W = 12
)(
    input wire clk,
    input wire load,
    input wire [W-1:0] data_in,
    output reg [W-1:0] data_out
);

always @(posedge clk) begin
    if (load) begin
        data_out <= data_in;
    end
end

endmodule

// Top-level double buffer module
module DoubleBuffer #(
    parameter W = 12
)(
    input wire clk,
    input wire load,
    input wire [W-1:0] data_in,
    output wire [W-1:0] data_out
);

wire [W-1:0] stage1_data;

// First buffer instance
SingleBuffer #(
    .W(W)
) buffer1 (
    .clk(clk),
    .load(load),
    .data_in(data_in),
    .data_out(stage1_data)
);

// Second buffer instance
SingleBuffer #(
    .W(W)
) buffer2 (
    .clk(clk),
    .load(load),
    .data_in(stage1_data),
    .data_out(data_out)
);

endmodule