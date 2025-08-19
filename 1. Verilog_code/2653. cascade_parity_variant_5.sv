//SystemVerilog
module cascade_parity (
    input        clk,       // 添加时钟信号用于流水线寄存器
    input        rst_n,     // 添加复位信号
    input  [7:0] data,      // 输入数据
    output reg   parity     // 修改为寄存器输出
);

    // 第一级流水线 - 计算各半字节的奇偶校验
    reg [3:0] nib_par_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nib_par_stage1 <= 4'b0;
        end else begin
            // 分别计算低4位和高4位的奇偶校验
            nib_par_stage1[0] <= ^data[3:0];
            nib_par_stage1[1] <= ^data[7:4];
            nib_par_stage1[2] <= 1'b0; // 未使用的位，设为0
            nib_par_stage1[3] <= 1'b0; // 未使用的位，设为0
        end
    end
    
    // 第二级流水线 - 合并半字节奇偶校验结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity <= 1'b0;
        end else begin
            // 计算最终奇偶校验值
            parity <= ^nib_par_stage1[1:0];
        end
    end

endmodule