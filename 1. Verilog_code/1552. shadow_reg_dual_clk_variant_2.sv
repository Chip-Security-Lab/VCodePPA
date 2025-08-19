//SystemVerilog
// Parameterized shadow register module for a single stage
module shadow_reg_stage #(
    parameter DW = 16
) (
    input  wire         clk,
    input  wire         load,
    input  wire [DW-1:0] din,
    output reg  [DW-1:0] dout
);
    always @(posedge clk) begin
        if (load) begin
            dout <= din;
        end
    end
endmodule

// Dual-clock shadow register with improved PPA metrics
module shadow_reg_dual_clk #(
    parameter DW = 16
) (
    input  wire         main_clk,
    input  wire         shadow_clk,
    input  wire         load,
    input  wire [DW-1:0] din,
    output wire [DW-1:0] dout
);
    // Internal signals
    wire [DW-1:0] shadow_storage_stage1;
    wire         load_stage1;
    wire [DW-1:0] shadow_storage_stage2;
    wire         load_stage2;
    
    // Stage 1: Main clock domain
    shadow_reg_stage #(
        .DW(DW)
    ) stage1 (
        .clk(main_clk),
        .load(load),
        .din(din),
        .dout(shadow_storage_stage1)
    );
    
    // Load signal synchronization for stage 1
    shadow_reg_stage #(
        .DW(1)
    ) load_sync1 (
        .clk(main_clk),
        .load(1'b1),
        .din(load),
        .dout(load_stage1)
    );
    
    // Stage 2: Shadow clock domain
    shadow_reg_stage #(
        .DW(DW)
    ) stage2 (
        .clk(shadow_clk),
        .load(load_stage1),
        .din(shadow_storage_stage1),
        .dout(shadow_storage_stage2)
    );
    
    // Load signal synchronization for stage 2
    shadow_reg_stage #(
        .DW(1)
    ) load_sync2 (
        .clk(shadow_clk),
        .load(1'b1),
        .din(load_stage1),
        .dout(load_stage2)
    );
    
    // Output stage
    shadow_reg_stage #(
        .DW(DW)
    ) output_stage (
        .clk(shadow_clk),
        .load(load_stage2),
        .din(shadow_storage_stage2),
        .dout(dout)
    );
endmodule