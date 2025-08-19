//SystemVerilog
module struct_unpack #(parameter TOTAL_W=32, FIELD_N=4) (
    input clk,                              // 时钟信号
    input rst_n,                            // 复位信号
    input start,                            // 乘法启动信号
    input [7:0] multiplicand,               // 被乘数
    input [7:0] multiplier,                 // 乘数
    output reg [15:0] product,              // 乘法结果
    output reg done                         // 计算完成标志
);
    // 内部寄存器和状态控制
    reg [7:0] mcand_reg;                    // 被乘数寄存器
    reg [7:0] mplier_reg;                   // 乘数寄存器
    reg [15:0] product_reg;                 // 乘积累加寄存器
    reg [3:0] bit_count;                    // 位计数器
    reg computing;                          // 正在计算标志

    // 状态机 - 移位累加乘法器实现
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            mcand_reg <= 8'h0;
            mplier_reg <= 8'h0;
            product_reg <= 16'h0;
            bit_count <= 4'h0;
            computing <= 1'b0;
            done <= 1'b0;
            product <= 16'h0;
        end else begin
            if (start && !computing) begin
                // 开始新的乘法计算
                mcand_reg <= multiplicand;
                mplier_reg <= multiplier;
                product_reg <= 16'h0;
                bit_count <= 4'h0;
                computing <= 1'b1;
                done <= 1'b0;
            end else if (computing) begin
                if (bit_count < 8) begin
                    // 检查当前位是否为1，如果是则累加被乘数
                    if (mplier_reg[0]) begin
                        product_reg <= product_reg + {8'h0, mcand_reg};
                    end
                    
                    // 乘数右移1位，被乘数左移1位
                    mplier_reg <= mplier_reg >> 1;
                    mcand_reg <= mcand_reg << 1;
                    bit_count <= bit_count + 1;
                end else begin
                    // 计算完成
                    product <= product_reg;
                    computing <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end
endmodule