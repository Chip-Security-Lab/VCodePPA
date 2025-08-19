//SystemVerilog
module basic_rom_with_multiplier (
    input [3:0] addr,
    output reg [7:0] data,
    // 新增乘法器接口
    input clk,
    input rst_n,
    input start,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg [15:0] product,
    output reg done
);
    // 移位累加乘法器实现
    reg [7:0] mcand_reg;       // 被乘数寄存器
    reg [7:0] mplier_reg;      // 乘数寄存器
    reg [15:0] product_reg;    // 乘积寄存器
    reg [3:0] bit_counter;     // 位计数器
    reg computing;             // 计算状态标志
    
    // 状态机定义
    localparam IDLE = 1'b0;
    localparam CALC = 1'b1;
    reg state;
    
    // ROM功能和时序逻辑合并
    always @(*) begin
        case (addr)
            4'h0: data = 8'h12;
            4'h1: data = 8'h34;
            4'h2: data = 8'h56;
            4'h3: data = 8'h78;
            4'h4: data = 8'h9A;
            4'h5: data = 8'hBC;
            4'h6: data = 8'hDE;
            4'h7: data = 8'hF0;
            default: data = 8'h00;
        endcase
    end
    
    // 乘法器状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mcand_reg <= 8'h0;
            mplier_reg <= 8'h0;
            product_reg <= 16'h0;
            bit_counter <= 4'h0;
            computing <= 1'b0;
            done <= 1'b0;
            product <= 16'h0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        mcand_reg <= multiplicand;
                        mplier_reg <= multiplier;
                        product_reg <= 16'h0;
                        bit_counter <= 4'h0;
                        computing <= 1'b1;
                        done <= 1'b0;
                        state <= CALC;
                    end
                end
                
                CALC: begin
                    if (computing) begin
                        if (bit_counter < 8) begin
                            // 检查当前乘数位并在同一个周期内完成加法和移位操作
                            if (mplier_reg[0]) 
                                product_reg <= product_reg + {8'h0, mcand_reg};
                            
                            mplier_reg <= mplier_reg >> 1;
                            mcand_reg <= mcand_reg << 1;
                            bit_counter <= bit_counter + 4'h1;
                        end else begin
                            product <= product_reg;
                            computing <= 1'b0;
                            done <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule