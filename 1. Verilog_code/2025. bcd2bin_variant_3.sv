//SystemVerilog
module bcd2bin (
    input wire clk,
    input wire enable,
    input wire [7:0] bcd_in,
    output reg [6:0] bin_out
);

// Combine input BCD separation and tens_value calculation into one stage
reg [6:0] tens_value_stage1;
reg [3:0] bcd_ones_stage1;
reg       enable_stage1;

always @(posedge clk) begin
    tens_value_stage1 <= (bcd_in[7:4] << 3) + (bcd_in[7:4] << 1); // x8 + x2 = x10
    bcd_ones_stage1   <= bcd_in[3:0];
    enable_stage1     <= enable;
end

// Pipeline stage 2: Add tens_value and ones
always @(posedge clk) begin
    if (enable_stage1)
        bin_out <= tens_value_stage1 + bcd_ones_stage1;
end

endmodule