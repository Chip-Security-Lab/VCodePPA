//SystemVerilog
module seg_dynamic_scan #(parameter N=4)(
    input clk,
    input [N*8-1:0] seg_data,
    input [7:0] mult_a,      // 新增: 乘法器输入A
    input [7:0] mult_b,      // 新增: 乘法器输入B
    output reg [3:0] sel,
    output [7:0] seg,
    output [15:0] mult_result // 新增: 乘法器结果输出
);
    reg [1:0] cnt;
    reg [7:0] seg_reg;
    
    // 实例化Booth乘法器
    booth_multiplier_8bit booth_mult (
        .clk(clk),
        .a(mult_a),
        .b(mult_b),
        .result(mult_result)
    );
    
    // 显示逻辑，使用乘法结果的低8位代替原始数据
    always @(*) begin
        case(cnt)
            2'b00: seg_reg = (mult_result[7:0] & 8'hF0) | (seg_data[7:0] & 8'h0F);  // 融合乘法结果
            2'b01: seg_reg = seg_data[15:8];
            2'b10: seg_reg = seg_data[23:16];
            2'b11: seg_reg = seg_data[31:24];
        endcase
    end
    
    assign seg = seg_reg;
    
    // 旋转扫描逻辑
    always @(posedge clk) begin
        cnt <= cnt + 1'b1;
        
        // 桶形解码器结构替代移位操作
        case(cnt)
            2'b00: sel <= 4'b1110;
            2'b01: sel <= 4'b1101;
            2'b10: sel <= 4'b1011;
            2'b11: sel <= 4'b0111;
        endcase
    end
endmodule

// Booth乘法器模块（8位）
module booth_multiplier_8bit (
    input clk,
    input [7:0] a,
    input [7:0] b,
    output reg [15:0] result
);
    // Booth乘法算法实现
    reg [16:0] A_reg;      // 扩展到17位，存储部分积
    reg [7:0] M_reg;       // 被乘数
    reg [8:0] Q_reg;       // 乘数加一位（用于Booth算法）
    reg [3:0] count;       // 迭代计数器
    
    // Booth乘法状态机
    reg [1:0] state;
    localparam IDLE = 2'b00, CALC = 2'b01, DONE = 2'b10;
    
    always @(posedge clk) begin
        case(state)
            IDLE: begin
                // 初始化
                M_reg <= a;                // 被乘数
                Q_reg <= {b, 1'b0};        // 乘数加一位
                A_reg <= 17'b0;            // 部分积初始化为0
                count <= 4'b0;             // 计数器清零
                state <= CALC;             // 进入计算状态
            end
            
            CALC: begin
                // Booth算法迭代
                if (count < 8) begin  // 8位乘数需要8次迭代
                    case(Q_reg[1:0])  // 检查乘数最低两位
                        2'b01: A_reg[16:9] <= A_reg[16:9] + M_reg;  // +M
                        2'b10: A_reg[16:9] <= A_reg[16:9] - M_reg;  // -M
                        default: ;  // 2'b00或2'b11，不操作
                    endcase
                    
                    // 算术右移一位
                    A_reg <= $signed(A_reg) >>> 1;
                    Q_reg <= {A_reg[0], Q_reg[8:1]};
                    count <= count + 1'b1;
                end
                else begin
                    state <= DONE;  // 完成计算
                end
            end
            
            DONE: begin
                // 更新结果
                result <= {A_reg[8:0], Q_reg[8:1]};
                state <= IDLE;  // 返回空闲状态，准备下一次计算
            end
            
            default: state <= IDLE;
        endcase
    end
endmodule