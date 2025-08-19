//SystemVerilog
module error_detect_decoder(
    input [1:0] addr,
    input valid,
    input clk,        // 添加时钟信号用于移位累加乘法器
    input reset,      // 添加复位信号
    input start,      // 乘法开始信号
    input [3:0] multiplicand,    // 被乘数
    input [3:0] multiplier,      // 乘数
    output reg [3:0] select,
    output reg error,
    output reg [7:0] product,    // 乘法结果
    output reg done              // 乘法完成信号
);
    // 原始译码器功能
    always @(*) begin
        select = valid ? (4'b0001 << addr) : 4'b0000;
        error = valid ? 1'b0 : 1'b1;
    end
    
    // 移位累加乘法器实现
    reg [3:0] mcand_reg;        // 被乘数寄存器
    reg [3:0] mplier_reg;       // 乘数寄存器
    reg [7:0] product_temp;     // 乘积临时寄存器
    reg [2:0] bit_count;        // 位计数器
    reg computing;              // 计算状态标志
    
    // 状态定义
    localparam IDLE = 1'b0;
    localparam COMPUTING = 1'b1;
    reg state;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mcand_reg <= 4'b0;
            mplier_reg <= 4'b0;
            product_temp <= 8'b0;
            bit_count <= 3'b0;
            product <= 8'b0;
            done <= 1'b0;
            computing <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        mcand_reg <= multiplicand;
                        mplier_reg <= multiplier;
                        product_temp <= 8'b0;
                        bit_count <= 3'b0;
                        done <= 1'b0;
                        state <= COMPUTING;
                    end
                end
                
                COMPUTING: begin
                    if (bit_count < 4) begin
                        // 检查乘数当前位
                        if (mplier_reg[0]) begin
                            // 如果当前位为1，则累加被乘数
                            product_temp <= product_temp + {4'b0000, mcand_reg};
                        end
                        
                        // 被乘数左移，乘数右移
                        mcand_reg <= mcand_reg << 1;
                        mplier_reg <= mplier_reg >> 1;
                        bit_count <= bit_count + 1;
                    end else begin
                        // 乘法完成
                        product <= product_temp;
                        done <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule