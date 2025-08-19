//SystemVerilog
module ecc_parity #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,                    // 新增时钟输入
    input wire rst_n,                  // 新增复位信号
    input wire [DATA_WIDTH-1:0] data_in,
    input wire parity_in,
    output reg error_flag,
    output reg [DATA_WIDTH-1:0] data_corrected
);
    // 数据流中间变量
    reg [DATA_WIDTH-1:0] data_stage1;
    reg parity_stage1;
    reg calc_parity_stage1;
    reg [DATA_WIDTH-1:0] data_stage2;
    reg error_detected;

    // 合并的always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            parity_stage1 <= 1'b0;
            calc_parity_stage1 <= 1'b0;
            data_stage2 <= {DATA_WIDTH{1'b0}};
            error_detected <= 1'b0;
            error_flag <= 1'b0;
            data_corrected <= {DATA_WIDTH{1'b0}};
        end else begin
            // 第一阶段：计算奇偶校验
            data_stage1 <= data_in;
            parity_stage1 <= parity_in;
            calc_parity_stage1 <= ^data_in;
            
            // 第二阶段：错误检测
            data_stage2 <= data_stage1;
            error_detected <= calc_parity_stage1 ^ parity_stage1;

            // 第三阶段：数据修正和输出
            error_flag <= error_detected;
            data_corrected <= error_detected ? ~data_stage2 : data_stage2;
        end
    end

endmodule