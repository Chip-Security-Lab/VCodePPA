//SystemVerilog
module log_barrel_shifter (
    input            clk,
    input            rst_n,
    input  [15:0]    data_i,
    input  [3:0]     shamt,
    output reg [15:0] data_o
);
    // Intermediate registers for deeper pipeline stages
    reg [15:0] stage0_data;  // Input data stage
    
    // Stage 1 - Shift by 0 or 1
    reg [15:0] stage1a_data; // Input buffer 1
    reg [15:0] stage1b_data; // Input buffer 2
    reg [15:0] stage1c_data; // Shift operation
    reg [3:0]  stage1a_shamt;
    reg [3:0]  stage1b_shamt;
    reg [3:0]  stage1c_shamt;
    
    // Stage 2 - Shift by 0 or 2
    reg [15:0] stage2a_data; // Buffer
    reg [15:0] stage2b_data; // Buffer
    reg [15:0] stage2c_data; // Shift operation
    reg [3:0]  stage2a_shamt;
    reg [3:0]  stage2b_shamt;
    reg [3:0]  stage2c_shamt;
    
    // Stage 3 - Shift by 0 or 4
    reg [15:0] stage3a_data; // Buffer
    reg [15:0] stage3b_data; // Buffer
    reg [15:0] stage3c_data; // Shift operation
    reg [3:0]  stage3a_shamt;
    reg [3:0]  stage3b_shamt;
    reg [3:0]  stage3c_shamt;
    
    // Stage 4 - Shift by 0 or 8
    reg [15:0] stage4a_data; // Buffer
    reg [15:0] stage4b_data; // Buffer
    reg [15:0] stage4c_data; // Shift operation
    reg [3:0]  stage4a_shamt;
    reg [3:0]  stage4b_shamt;
    
    // Output buffer stages
    reg [15:0] output_buf1;
    reg [15:0] output_buf2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers
            stage0_data <= 16'b0;
            
            stage1a_data <= 16'b0;
            stage1b_data <= 16'b0;
            stage1c_data <= 16'b0;
            stage1a_shamt <= 4'b0;
            stage1b_shamt <= 4'b0;
            stage1c_shamt <= 4'b0;
            
            stage2a_data <= 16'b0;
            stage2b_data <= 16'b0;
            stage2c_data <= 16'b0;
            stage2a_shamt <= 4'b0;
            stage2b_shamt <= 4'b0;
            stage2c_shamt <= 4'b0;
            
            stage3a_data <= 16'b0;
            stage3b_data <= 16'b0;
            stage3c_data <= 16'b0;
            stage3a_shamt <= 4'b0;
            stage3b_shamt <= 4'b0;
            stage3c_shamt <= 4'b0;
            
            stage4a_data <= 16'b0;
            stage4b_data <= 16'b0;
            stage4c_data <= 16'b0;
            stage4a_shamt <= 4'b0;
            stage4b_shamt <= 4'b0;
            
            output_buf1 <= 16'b0;
            output_buf2 <= 16'b0;
            data_o <= 16'b0;
        end else begin
            // Input stage
            stage0_data <= data_i;
            
            // Stage 1 - Buffering and shift control signals
            stage1a_shamt <= shamt;
            stage1a_data <= stage0_data;
            
            stage1b_shamt <= stage1a_shamt;
            stage1b_data <= stage1a_data;
            
            // Stage 1 - Actual shift operation (by 0 or 1)
            stage1c_shamt <= stage1b_shamt;
            stage1c_data <= stage1b_shamt[0] ? {stage1b_data[14:0], 1'b0} : stage1b_data;
            
            // Stage 2 - Buffering
            stage2a_shamt <= stage1c_shamt;
            stage2a_data <= stage1c_data;
            
            stage2b_shamt <= stage2a_shamt;
            stage2b_data <= stage2a_data;
            
            // Stage 2 - Actual shift operation (by 0 or 2)
            stage2c_shamt <= stage2b_shamt;
            stage2c_data <= stage2b_shamt[1] ? {stage2b_data[13:0], 2'b0} : stage2b_data;
            
            // Stage 3 - Buffering
            stage3a_shamt <= stage2c_shamt;
            stage3a_data <= stage2c_data;
            
            stage3b_shamt <= stage3a_shamt;
            stage3b_data <= stage3a_data;
            
            // Stage 3 - Actual shift operation (by 0 or 4)
            stage3c_shamt <= stage3b_shamt;
            stage3c_data <= stage3b_shamt[2] ? {stage3b_data[11:0], 4'b0} : stage3b_data;
            
            // Stage 4 - Buffering
            stage4a_shamt <= stage3c_shamt;
            stage4a_data <= stage3c_data;
            
            stage4b_shamt <= stage4a_shamt;
            stage4b_data <= stage4a_data;
            
            // Stage 4 - Actual shift operation (by 0 or 8)
            stage4c_data <= stage4b_shamt[3] ? {stage4b_data[7:0], 8'b0} : stage4b_data;
            
            // Output buffering stages
            output_buf1 <= stage4c_data;
            output_buf2 <= output_buf1;
            
            // Final output
            data_o <= output_buf2;
        end
    end
endmodule