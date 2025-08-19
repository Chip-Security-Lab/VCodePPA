//SystemVerilog
module ICMU_ShadowHybrid #(
    parameter DW = 32,
    parameter SHADOW_DEPTH = 4
)(
    input clk,
    input shadow_switch,
    input [DW-1:0] reg_in,
    output [DW-1:0] reg_out
);
    reg [DW-1:0] main_reg;
    reg [DW-1:0] shadow_regs [0:SHADOW_DEPTH-1];
    reg [1:0] shadow_ptr;
    
    // Pipeline stage 1
    reg [DW-1:0] shadow_data_stage1;
    reg shadow_switch_stage1;
    reg [DW-1:0] main_reg_stage1;
    
    // Pipeline stage 2
    reg [DW-1:0] shadow_data_stage2;
    reg shadow_switch_stage2;
    reg [DW-1:0] main_reg_stage2;
    
    // Pipeline stage 3
    reg [DW-1:0] shadow_data_stage3;
    reg shadow_switch_stage3;
    reg [DW-1:0] main_reg_stage3;
    
    // Pipeline stage 4
    reg [DW-1:0] shadow_data_stage4;
    reg shadow_switch_stage4;
    reg [DW-1:0] main_reg_stage4;
    
    // Pipeline stage 1
    always @(posedge clk) begin
        shadow_data_stage1 <= shadow_regs[shadow_ptr];
        shadow_switch_stage1 <= shadow_switch;
        main_reg_stage1 <= main_reg;
    end
    
    // Pipeline stage 2
    always @(posedge clk) begin
        shadow_data_stage2 <= shadow_data_stage1;
        shadow_switch_stage2 <= shadow_switch_stage1;
        main_reg_stage2 <= main_reg_stage1;
    end
    
    // Pipeline stage 3
    always @(posedge clk) begin
        shadow_data_stage3 <= shadow_data_stage2;
        shadow_switch_stage3 <= shadow_switch_stage2;
        main_reg_stage3 <= main_reg_stage2;
    end
    
    // Pipeline stage 4
    always @(posedge clk) begin
        shadow_data_stage4 <= shadow_data_stage3;
        shadow_switch_stage4 <= shadow_switch_stage3;
        main_reg_stage4 <= main_reg_stage3;
    end
    
    // Main logic with pipelined shadow switch
    always @(posedge clk) begin
        if (shadow_switch_stage4) begin
            shadow_regs[shadow_ptr] <= main_reg_stage4;
            shadow_ptr <= shadow_ptr + 1;
            main_reg <= reg_in;
        end else begin
            main_reg <= reg_in;
        end
    end
    
    // Output selection with pipelined data
    assign reg_out = shadow_switch_stage4 ? shadow_data_stage4 : main_reg_stage4;
endmodule