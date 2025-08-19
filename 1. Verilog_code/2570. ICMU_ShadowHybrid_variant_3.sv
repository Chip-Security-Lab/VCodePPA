//SystemVerilog
module ICMU_ShadowHybrid #(
    parameter DW = 32,
    parameter SHADOW_DEPTH = 4
)(
    input clk,
    input rst_n,
    input shadow_switch,
    input [DW-1:0] reg_in,
    output [DW-1:0] reg_out
);

    // Stage 1: Input and Control
    reg [DW-1:0] reg_in_stage1;
    reg shadow_switch_stage1;
    reg [1:0] shadow_ptr_stage1;
    
    // Stage 2: Main Register Update
    reg [DW-1:0] main_reg_stage2;
    reg [DW-1:0] shadow_regs_stage2 [0:SHADOW_DEPTH-1];
    reg [1:0] shadow_ptr_stage2;
    reg shadow_switch_stage2;
    
    // Stage 3: Shadow Register Update
    reg [DW-1:0] main_reg_stage3;
    reg [DW-1:0] shadow_regs_stage3 [0:SHADOW_DEPTH-1];
    reg [1:0] shadow_ptr_stage3;
    reg shadow_switch_stage3;
    
    // Stage 4: Output Selection
    reg [DW-1:0] reg_out_stage4;
    
    // Stage 1 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_in_stage1 <= {DW{1'b0}};
            shadow_switch_stage1 <= 1'b0;
            shadow_ptr_stage1 <= 2'b0;
        end else begin
            reg_in_stage1 <= reg_in;
            shadow_switch_stage1 <= shadow_switch;
            shadow_ptr_stage1 <= shadow_ptr_stage3;
        end
    end
    
    // Stage 2 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg_stage2 <= {DW{1'b0}};
            for (int i = 0; i < SHADOW_DEPTH; i = i + 1)
                shadow_regs_stage2[i] <= {DW{1'b0}};
            shadow_ptr_stage2 <= 2'b0;
            shadow_switch_stage2 <= 1'b0;
        end else begin
            main_reg_stage2 <= reg_in_stage1;
            shadow_switch_stage2 <= shadow_switch_stage1;
            shadow_ptr_stage2 <= shadow_ptr_stage1;
            for (int i = 0; i < SHADOW_DEPTH; i = i + 1)
                shadow_regs_stage2[i] <= shadow_regs_stage3[i];
        end
    end
    
    // Stage 3 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg_stage3 <= {DW{1'b0}};
            for (int i = 0; i < SHADOW_DEPTH; i = i + 1)
                shadow_regs_stage3[i] <= {DW{1'b0}};
            shadow_ptr_stage3 <= 2'b0;
            shadow_switch_stage3 <= 1'b0;
        end else begin
            if (shadow_switch_stage2) begin
                shadow_regs_stage3[shadow_ptr_stage2] <= main_reg_stage2;
                shadow_ptr_stage3 <= shadow_ptr_stage2 + 1;
                main_reg_stage3 <= main_reg_stage2;
            end else begin
                main_reg_stage3 <= main_reg_stage2;
                shadow_ptr_stage3 <= shadow_ptr_stage2;
            end
            shadow_switch_stage3 <= shadow_switch_stage2;
        end
    end
    
    // Stage 4 Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_out_stage4 <= {DW{1'b0}};
        end else begin
            reg_out_stage4 <= shadow_switch_stage3 ? 
                            shadow_regs_stage3[shadow_ptr_stage2] : 
                            main_reg_stage3;
        end
    end
    
    assign reg_out = reg_out_stage4;
    
endmodule