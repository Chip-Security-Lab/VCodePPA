//SystemVerilog
module parity_buf #(parameter DW=9) (
    input clk,
    input rst_n,  // 添加复位信号
    input en,
    input data_valid_in,  // 输入数据有效信号
    input [DW-2:0] data_in,
    output reg [DW-1:0] data_out,
    output reg data_valid_out  // 输出数据有效信号
);
    // 流水线第一级 - 计算校验位
    reg parity_stage1;
    reg [DW-2:0] data_stage1;
    reg valid_stage1;
    
    // 流水线第二级 - 组合数据
    reg [DW-1:0] data_stage2;
    reg valid_stage2;
    
    // 第一级流水线 - 计算校验位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_stage1 <= 1'b0;
            data_stage1 <= {(DW-1){1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en) begin
            parity_stage1 <= ^data_in;
            data_stage1 <= data_in;
            valid_stage1 <= data_valid_in;
        end
    end
    
    // 第二级流水线 - 组合校验位和数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (en) begin
            data_stage2 <= {parity_stage1, data_stage1};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出级 - 最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DW{1'b0}};
            data_valid_out <= 1'b0;
        end else if (en) begin
            data_out <= data_stage2;
            data_valid_out <= valid_stage2;
        end
    end
    
endmodule