//SystemVerilog
module shadow_reg_mask #(parameter DW=32) (
    input clk, en,
    input [DW-1:0] data_in, mask,
    output reg [DW-1:0] data_out
);
    // Pipeline stage registers
    reg [DW-1:0] shadow_reg;
    reg [DW-1:0] mask_stage1;
    reg [DW-1:0] data_in_stage1;
    reg en_stage1;
    reg [DW-1:0] masked_data_stage2;
    reg [DW-1:0] masked_shadow_stage2;
    reg [DW-1:0] shadow_reg_stage3;
    
    // Stage 1: Register inputs and prepare for computation
    always @(posedge clk) begin
        mask_stage1 <= mask;
        data_in_stage1 <= data_in;
        en_stage1 <= en;
    end
    
    // Stage 2: Perform masking operations
    always @(posedge clk) begin
        masked_data_stage2 <= data_in_stage1 & mask_stage1;
        masked_shadow_stage2 <= shadow_reg & ~mask_stage1;
    end
    
    // Stage 3: Combine masked data and update shadow register
    always @(posedge clk) begin
        if(en_stage1) shadow_reg <= masked_shadow_stage2 | masked_data_stage2;
        shadow_reg_stage3 <= shadow_reg;
    end
    
    // Final stage: Update output
    always @(posedge clk) begin
        data_out <= shadow_reg_stage3;
    end
endmodule