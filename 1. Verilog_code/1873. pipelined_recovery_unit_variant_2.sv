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
    
    // 用于减法实现的信号
    wire [DATA_WIDTH-1:0] subtrahend_complement;
    wire [DATA_WIDTH-1:0] sub_result;
    
    // 常量减数的补码
    assign subtrahend_complement = ~16'h00FF + 1'b1;
    // 预计算减法结果
    assign sub_result = data_in + subtrahend_complement;
    
    // 第一阶段 - 处理数据减法和有效信号
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            stage1 <= {DATA_WIDTH{1'b0}};
            stage1_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                stage1 <= sub_result;
            end
            stage1_valid <= in_valid;
        end
    end
    
    // 第二阶段 - 传递数据和有效信号
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            stage2 <= {DATA_WIDTH{1'b0}};
            stage2_valid <= 1'b0;
        end else begin
            stage2 <= stage1_valid ? stage1 : stage2;
            stage2_valid <= stage1_valid;
        end
    end
    
    // 输出阶段 - 更新输出数据和有效信号
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            data_out <= {DATA_WIDTH{1'b0}};
            out_valid <= 1'b0;
        end else begin
            data_out <= stage2_valid ? stage2 : data_out;
            out_valid <= stage2_valid;
        end
    end
endmodule