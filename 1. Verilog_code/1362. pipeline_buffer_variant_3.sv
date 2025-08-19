//SystemVerilog
module pipeline_buffer (
    input wire clk,
    input wire rst_n,
    input wire [15:0] data_in,
    input wire valid_in,
    output reg [15:0] data_out,
    output reg valid_out
);
    // 增加流水线级数，从2级扩展为5级
    reg [15:0] stage1_data, stage2_data, stage3_data, stage4_data;
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid;
    
    always @(posedge clk or negedge rst_n) begin
        // 使用条件运算符替代if-else结构
        // Stage 1
        stage1_data <= !rst_n ? 16'b0 : data_in;
        stage1_valid <= !rst_n ? 1'b0 : valid_in;
        
        // Stage 2
        stage2_data <= !rst_n ? 16'b0 : stage1_data;
        stage2_valid <= !rst_n ? 1'b0 : stage1_valid;
        
        // Stage 3
        stage3_data <= !rst_n ? 16'b0 : stage2_data;
        stage3_valid <= !rst_n ? 1'b0 : stage2_valid;
        
        // Stage 4
        stage4_data <= !rst_n ? 16'b0 : stage3_data;
        stage4_valid <= !rst_n ? 1'b0 : stage3_valid;
        
        // Output stage
        data_out <= !rst_n ? 16'b0 : stage4_data;
        valid_out <= !rst_n ? 1'b0 : stage4_valid;
    end
endmodule