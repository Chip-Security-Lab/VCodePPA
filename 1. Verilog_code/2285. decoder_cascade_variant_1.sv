//SystemVerilog
// 顶层模块
module decoder_cascade (
    input en_in,
    input [2:0] addr,
    output [7:0] decoded,
    output en_out,
    // 新增乘法器接口
    input clk,
    input rst_n,
    input start,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output [15:0] product,
    output done
);
    wire enable_signal;
    
    // 实例化使能控制子模块
    enable_controller enable_ctrl (
        .en_in(en_in),
        .enable_out(enable_signal),
        .en_out(en_out)
    );
    
    // 实例化3-8解码器子模块
    decoder_3to8 decoder (
        .enable(enable_signal),
        .addr(addr),
        .decoded(decoded)
    );
    
    // 实例化移位累加乘法器
    shift_add_multiplier mult (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .multiplicand(multiplicand),
        .multiplier(multiplier),
        .product(product),
        .done(done)
    );
    
endmodule

// 使能控制子模块
module enable_controller (
    input en_in,
    output enable_out,
    output en_out
);
    // 负责处理使能信号的传递
    assign enable_out = en_in;
    assign en_out = en_in;
endmodule

// 3-8解码器子模块
module decoder_3to8 (
    input enable,
    input [2:0] addr,
    output reg [7:0] decoded
);
    // 实现3-8解码功能
    always @(*) begin
        if (enable)
            decoded = (1'b1 << addr);
        else
            decoded = 8'h0;
    end
endmodule

// 移位累加乘法器模块（8位）
module shift_add_multiplier (
    input clk,
    input rst_n,
    input start,
    input [7:0] multiplicand,
    input [7:0] multiplier,
    output reg [15:0] product,
    output reg done
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam FINISH = 2'b10;
    
    reg [1:0] state, next_state;
    reg [7:0] mcand_reg;       // 被乘数寄存器
    reg [7:0] mplier_reg;      // 乘数寄存器
    reg [15:0] product_temp;   // 累加结果寄存器
    reg [3:0] bit_count;       // 计数器，8位乘法需要8个周期
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 状态转换逻辑
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = CALC;
                else
                    next_state = IDLE;
            end
            CALC: begin
                if (bit_count == 4'd8)
                    next_state = FINISH;
                else
                    next_state = CALC;
            end
            FINISH: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mcand_reg <= 8'b0;
            mplier_reg <= 8'b0;
            product_temp <= 16'b0;
            bit_count <= 4'b0;
            done <= 1'b0;
            product <= 16'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        mcand_reg <= multiplicand;
                        mplier_reg <= multiplier;
                        product_temp <= 16'b0;
                        bit_count <= 4'b0;
                        done <= 1'b0;
                    end
                end
                CALC: begin
                    // 检查当前乘数位
                    if (mplier_reg[0]) begin
                        product_temp <= product_temp + {8'b0, mcand_reg};
                    end
                    // 移位操作
                    mcand_reg <= mcand_reg << 1;
                    mplier_reg <= mplier_reg >> 1;
                    bit_count <= bit_count + 1'b1;
                end
                FINISH: begin
                    product <= product_temp;
                    done <= 1'b1;
                end
            endcase
        end
    end
    
endmodule