//SystemVerilog
module pipelined_recovery_unit #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire in_valid,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg out_valid
);
    reg [DATA_WIDTH-1:0] stage1, stage2;
    reg stage1_valid, stage2_valid;
    
    // 条件求和减法器信号
    reg [DATA_WIDTH-1:0] minuend, subtrahend;
    wire [DATA_WIDTH-1:0] diff_result;
    wire [DATA_WIDTH:0] extended_sum;
    wire [DATA_WIDTH-1:0] inverted_subtrahend;
    
    // 对减数取反
    assign inverted_subtrahend = ~subtrahend;
    
    // 条件求和减法实现: A - B = A + (~B) + 1
    assign extended_sum = minuend + inverted_subtrahend + 1'b1;
    assign diff_result = extended_sum[DATA_WIDTH-1:0];
    
    always @(posedge clock) begin
        if (reset) begin
            {stage1, stage2, data_out} <= 0;
            {stage1_valid, stage2_valid, out_valid} <= 0;
            {minuend, subtrahend} <= 0;
        end else begin
            // 第一级流水线
            if (in_valid) begin
                stage1 <= data_in;
                stage1_valid <= 1'b1;
                // 假设数据需要减法处理
                minuend <= data_in;
                subtrahend <= data_in >> 1; // 示例减法操作，使用右移作为减数
            end else begin
                stage1_valid <= 1'b0;
            end
            
            // 第二级流水线
            if (stage1_valid) begin
                // 使用条件求和减法结果
                stage2 <= diff_result;
                stage2_valid <= 1'b1;
            end else begin
                stage2_valid <= 1'b0;
            end
            
            // 输出级
            if (stage2_valid) begin
                data_out <= stage2;
                out_valid <= 1'b1;
            end else begin
                out_valid <= 1'b0;
            end
        end
    end
endmodule