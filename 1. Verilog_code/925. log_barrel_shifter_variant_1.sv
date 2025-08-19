//SystemVerilog
module log_barrel_shifter (
    input            clk,
    input            rst_n,
    input            valid_i,
    input  [15:0]    data_i,
    input  [3:0]     shamt,
    output [15:0]    data_o,
    output           valid_o
);
    // Pipeline stage registers for data
    reg [15:0] stage1_data, stage2_data, stage3_data, stage4_data, stage5_data;
    
    // Pipeline stage registers for shift amount
    reg [3:0] stage1_shamt, stage2_shamt, stage3_shamt, stage4_shamt;
    
    // Pipeline valid signals
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid, stage5_valid;
    
    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 16'b0;
            stage1_shamt <= 4'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_data <= data_i;
            stage1_shamt <= shamt;
            stage1_valid <= valid_i;
        end
    end
    
    // Stage 2: First shift (by 0 or 1)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 16'b0;
            stage2_shamt <= 4'b0;
            stage2_valid <= 1'b0;
        end else begin
            stage2_data <= stage1_shamt[0] ? {stage1_data[14:0], 1'b0} : stage1_data;
            stage2_shamt <= stage1_shamt;
            stage2_valid <= stage1_valid;
        end
    end
    
    // Stage 3: Second shift (by 0 or 2)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data <= 16'b0;
            stage3_shamt <= 4'b0;
            stage3_valid <= 1'b0;
        end else begin
            stage3_data <= stage2_shamt[1] ? {stage2_data[13:0], 2'b0} : stage2_data;
            stage3_shamt <= stage2_shamt;
            stage3_valid <= stage2_valid;
        end
    end
    
    // Stage 4: Third shift (by 0 or 4)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_data <= 16'b0;
            stage4_shamt <= 4'b0;
            stage4_valid <= 1'b0;
        end else begin
            stage4_data <= stage3_shamt[2] ? {stage3_data[11:0], 4'b0} : stage3_data;
            stage4_shamt <= stage3_shamt;
            stage4_valid <= stage3_valid;
        end
    end
    
    // Stage 5: Fourth shift (by 0 or 8) and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage5_data <= 16'b0;
            stage5_valid <= 1'b0;
        end else begin
            stage5_data <= stage4_shamt[3] ? {stage4_data[7:0], 8'b0} : stage4_data;
            stage5_valid <= stage4_valid;
        end
    end
    
    // Output assignments
    assign data_o = stage5_data;
    assign valid_o = stage5_valid;
    
endmodule