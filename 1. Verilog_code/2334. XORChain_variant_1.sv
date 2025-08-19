//SystemVerilog
module XORChain (
    input clk, rst_n,
    input [7:0] din,
    input valid_in,
    output reg valid_out,
    output reg [7:0] dout
);
    // 声明流水线寄存器
    reg [7:0] din_stage1;
    reg [7:0] din_stage2;
    reg valid_stage1;
    reg valid_stage2;
    
    // 第一级流水线：捕获输入数据和有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            din_stage1 <= din;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：存储数据用于XOR运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end else begin
            din_stage2 <= din_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线：执行XOR运算并输出结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            dout <= din_stage1 ^ din_stage2;
            valid_out <= valid_stage2;
        end
    end
endmodule