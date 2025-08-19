//SystemVerilog
module shift_preset #(parameter W=8) (
    input clk,
    input preset,
    input [W-1:0] preset_val,
    output reg [W-1:0] dout
);

// Stage 1: Preset and capture current value
reg preset_stage1;
reg [W-1:0] preset_val_stage1;
reg [W-1:0] dout_stage1;

// Stage 2: Shift logic preparation
reg preset_stage2;
reg [W-1:0] preset_val_stage2;
reg [W-1:0] shift_input_stage2;

// Stage 3: Final output register
always @(posedge clk) begin
    // Pipeline stage 1
    preset_stage1     <= preset;
    preset_val_stage1 <= preset_val;
    dout_stage1       <= dout;
end

always @(posedge clk) begin
    // Pipeline stage 2
    preset_stage2      <= preset_stage1;
    preset_val_stage2  <= preset_val_stage1;
    shift_input_stage2 <= {dout_stage1[W-2:0], 1'b1};
end

always @(posedge clk) begin
    // Pipeline stage 3 / output register
    dout <= preset_stage2 ? preset_val_stage2 : shift_input_stage2;
end

endmodule