//SystemVerilog
module sync_integrator #(
    parameter DATA_W = 16,
    parameter ACC_W = 24
)(
    input clk, rst, clear_acc,
    input [DATA_W-1:0] in_data,
    input valid_in,
    output reg valid_out,
    output reg [ACC_W-1:0] out_data
);
    // 定义流水线寄存器
    reg [DATA_W-1:0] in_data_stage1;
    reg [ACC_W-1:0] out_data_stage1;
    reg [ACC_W-1:0] mult_result_stage1;
    reg [ACC_W-1:0] shifted_result_stage2;
    reg valid_stage1, valid_stage2;
    reg clear_acc_stage1, clear_acc_stage2;
    
    // 第一级流水线：捕获输入并计算乘积
    always @(posedge clk) begin
        if (rst) begin
            in_data_stage1 <= 0;
            out_data_stage1 <= 0;
            mult_result_stage1 <= 0;
            valid_stage1 <= 0;
            clear_acc_stage1 <= 0;
        end else begin
            in_data_stage1 <= in_data;
            out_data_stage1 <= out_data;
            // 使用15/16的系数计算
            mult_result_stage1 <= (out_data << 4) - out_data; // 15*out_data = 16*out_data - out_data
            valid_stage1 <= valid_in;
            clear_acc_stage1 <= clear_acc;
        end
    end
    
    // 第二级流水线：执行移位操作
    always @(posedge clk) begin
        if (rst) begin
            shifted_result_stage2 <= 0;
            valid_stage2 <= 0;
            clear_acc_stage2 <= 0;
        end else begin
            // 桶形移位器实现右移4位
            shifted_result_stage2 <= mult_result_stage1 >> 4;
            valid_stage2 <= valid_stage1;
            clear_acc_stage2 <= clear_acc_stage1;
        end
    end
    
    // 第三级流水线：更新累加器并输出
    always @(posedge clk) begin
        if (rst) begin
            out_data <= 0;
            valid_out <= 0;
        end else if (clear_acc_stage2) begin
            out_data <= 0;
            valid_out <= valid_stage2;
        end else if (valid_stage2) begin
            // 漏积分器: y[n] = x[n] + a*y[n-1]
            out_data <= in_data_stage1 + shifted_result_stage2;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule