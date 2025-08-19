//SystemVerilog
// 顶层模块
module binary_decoder (
    input [3:0] addr_in,
    output [15:0] select_out,
    // 新增乘法器接口
    input clk,
    input rst_n,
    input start,
    input [15:0] multiplicand,
    input [15:0] multiplier,
    output reg [31:0] product,
    output reg done
);
    // 地址解码信号
    wire [15:0] decoded_out;
    
    // 地址解码子模块实例化
    address_decoder decoder_inst (
        .addr(addr_in),
        .decoded_out(decoded_out)
    );
    
    // 连接解码输出到选择输出
    assign select_out = decoded_out;
    
    // Booth乘法器实现
    // 内部寄存器和状态定义
    reg [4:0] state;
    reg [15:0] A, S, P_upper;
    reg [16:0] P_lower; // 包含额外位用于Booth算法
    reg [4:0] counter;
    
    // 状态定义
    localparam IDLE = 5'd0;
    localparam INIT = 5'd1;
    localparam CALC = 5'd2;
    localparam SHIFT = 5'd3;
    localparam DONE = 5'd4;
    
    // Booth乘法器状态机
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            product <= 32'd0;
            done <= 1'b0;
            counter <= 5'd0;
            A <= 16'd0;
            S <= 16'd0;
            P_upper <= 16'd0;
            P_lower <= 17'd0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        state <= INIT;
                    end
                end
                
                INIT: begin
                    // 初始化Booth乘法器
                    A <= multiplicand;
                    S <= (~multiplicand) + 1'b1; // 负的被乘数
                    P_upper <= 16'd0;
                    P_lower <= {multiplier, 1'b0}; // 附加一个0位
                    counter <= 5'd16; // 16位乘法需要16次操作
                    state <= CALC;
                end
                
                CALC: begin
                    // 根据Booth算法检查最低两位
                    case (P_lower[1:0])
                        2'b01: P_upper <= P_upper + A; // +A
                        2'b10: P_upper <= P_upper + S; // -A
                        default: ; // 00或11不需要操作
                    endcase
                    state <= SHIFT;
                end
                
                SHIFT: begin
                    // 算术右移
                    {P_upper, P_lower} <= {P_upper[15], P_upper, P_lower[16:1]};
                    counter <= counter - 1'b1;
                    
                    if (counter == 5'd1) begin
                        state <= DONE;
                    end else begin
                        state <= CALC;
                    end
                end
                
                DONE: begin
                    product <= {P_upper, P_lower[16:1]}; // 组合最终结果
                    done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// 地址解码子模块
module address_decoder (
    input [3:0] addr,
    output reg [15:0] decoded_out
);
    // 使用参数定义总线宽度，提高可复用性
    parameter ADDR_WIDTH = 4;
    parameter OUT_WIDTH = 16;
    
    // 地址译码过程
    always @(*) begin
        decoded_out = {OUT_WIDTH{1'b0}}; // 清零所有输出位
        decoded_out[addr] = 1'b1;        // 根据地址置位对应输出
    end
endmodule