//SystemVerilog
module parity_check_async_rst (
    input clk, arst,
    input [3:0] addr,
    input [7:0] data,
    input valid_in,         // 输入数据有效信号
    output reg valid_out,   // 输出数据有效信号
    output reg parity
);

    // 第一级流水线：计算低4位数据的奇偶校验
    reg [3:0] data_stage1;
    reg valid_stage1;
    reg parity_stage1;
    
    // 第二级流水线：结合高4位计算最终奇偶校验
    reg [3:0] data_stage2;
    reg valid_stage2;
    
    // 流水线第一级：处理低4位
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            data_stage1 <= 4'b0;
            parity_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else begin
            data_stage1 <= data[3:0]; // 修正为低4位
            parity_stage1 <= ^data[3:0];
            valid_stage1 <= valid_in;
        end
    end
    
    // 流水线第二级：处理高4位并结合低4位结果
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            data_stage2 <= 4'b0;
            valid_stage2 <= 1'b0;
        end
        else begin
            data_stage2 <= data[7:4]; // 修正为高4位
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 流水线第三级：计算最终校验结果
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            parity <= 1'b0;
            valid_out <= 1'b0;
        end
        else begin
            parity <= parity_stage1 ^ (^data_stage2);
            valid_out <= valid_stage2;
        end
    end

endmodule