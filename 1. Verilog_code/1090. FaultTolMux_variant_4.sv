//SystemVerilog
module FaultTolMux #(parameter DW=8) (
    input clk,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error
);

// Pipeline stage 1: Register sel and din
reg [1:0] sel_stage1;
reg [3:0][DW-1:0] din_stage1;
always @(posedge clk) begin
    sel_stage1 <= sel;
    din_stage1 <= din;
end

// Pipeline stage 2: Primary and backup mux result
reg [DW-1:0] primary_mux_stage2;
reg [DW-1:0] backup_mux_stage2;
reg [1:0] sel_inv_stage2;
always @(posedge clk) begin
    // Primary mux
    case (sel_stage1)
        2'b00: primary_mux_stage2 <= din_stage1[0];
        2'b01: primary_mux_stage2 <= din_stage1[1];
        2'b10: primary_mux_stage2 <= din_stage1[2];
        2'b11: primary_mux_stage2 <= din_stage1[3];
        default: primary_mux_stage2 <= {DW{1'b0}};
    endcase
    // Inverted select for backup mux
    sel_inv_stage2 <= ~sel_stage1;
end

always @(posedge clk) begin
    // Backup mux depends on sel_inv_stage2 and din_stage1 (from previous cycle)
    case (sel_inv_stage2)
        2'b00: backup_mux_stage2 <= din_stage1[0];
        2'b01: backup_mux_stage2 <= din_stage1[1];
        2'b10: backup_mux_stage2 <= din_stage1[2];
        2'b11: backup_mux_stage2 <= din_stage1[3];
        default: backup_mux_stage2 <= {DW{1'b0}};
    endcase
end

// Pipeline stage 3: dout mux and error logic
reg [DW-1:0] dout_mux_stage3;
reg error_stage3;
always @(posedge clk) begin
    if ((^primary_mux_stage2[7:4]) == primary_mux_stage2[3])
        dout_mux_stage3 <= primary_mux_stage2;
    else
        dout_mux_stage3 <= backup_mux_stage2;
    error_stage3 <= (primary_mux_stage2 != backup_mux_stage2);
end

// Output register
always @(posedge clk) begin
    dout <= dout_mux_stage3;
    error <= error_stage3;
end

endmodule