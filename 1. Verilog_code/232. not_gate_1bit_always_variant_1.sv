//SystemVerilog
module not_gate_1bit_pipeline (
    input  wire       clk,           // 时钟信号
    input  wire       rst_n,         // 复位信号，低电平有效
    input  wire       A_in,          // 输入数据
    input  wire       valid_in,      // 输入有效信号
    output reg        Y_out,         // 输出数据
    output reg        valid_out      // 输出有效信号
);

    // 内部流水线寄存器
    reg  A_stage1;
    reg  valid_stage1;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            A_stage1 <= A_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 非门操作和输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            Y_out <= ~A_stage1;
            valid_out <= valid_stage1;
        end
    end

endmodule