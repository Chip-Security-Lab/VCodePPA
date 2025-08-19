//SystemVerilog
module latch_based_clock_gate (
    input  wire clk_in,
    input  wire enable,
    output wire clk_out
);
    reg latch_out;
    
    // 使用非阻塞赋值以避免竞态条件
    always @(negedge clk_in) begin
        latch_out <= enable;
    end
    
    assign clk_out = clk_in & latch_out;
endmodule

module booth_multiplier_8bit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  multiplicand, // 被乘数
    input  wire [7:0]  multiplier,   // 乘数
    output reg  [15:0] product,      // 乘积结果
    output reg         done          // 乘法完成信号
);
    // 状态定义
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0]  state, next_state;
    reg [3:0]  count;
    
    // 流水线寄存器
    reg [16:0] acc_stage1;           // 第一级流水线累加器
    reg [16:0] acc_stage2;           // 第二级流水线累加器
    reg [16:0] acc_stage3;           // 第三级流水线累加器
    
    reg [8:0]  multiplier_q_stage1;  // 第一级流水线乘数
    reg [8:0]  multiplier_q_stage2;  // 第二级流水线乘数
    reg [8:0]  multiplier_q_stage3;  // 第三级流水线乘数
    
    reg [7:0]  multiplicand_stage1;  // 第一级流水线被乘数
    reg [7:0]  multiplicand_stage2;  // 第二级流水线被乘数
    reg [7:0]  multiplicand_stage3;  // 第三级流水线被乘数
    
    reg [1:0]  booth_op_stage1;      // Booth操作码第一级
    reg [16:0] acc_after_add_stage2; // 加法结果第二级
    
    reg [3:0]  count_stage1;         // 计数器流水线寄存器
    reg [3:0]  count_stage2;
    reg [3:0]  count_stage3;
    
    reg        valid_stage1;         // 有效标志，指示流水线各级是否有效数据
    reg        valid_stage2;
    reg        valid_stage3;
    
    // 状态转换逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 下一状态逻辑
    always @(*) begin
        case (state)
            IDLE: next_state = start ? CALC : IDLE;
            CALC: next_state = (count_stage3 == 4'd8 && valid_stage3) ? DONE : CALC;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 流水线第一级 - 分析Booth操作和准备操作数
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage1 <= 4'd0;
            acc_stage1 <= 17'd0;
            multiplier_q_stage1 <= 9'd0;
            multiplicand_stage1 <= 8'd0;
            booth_op_stage1 <= 2'b00;
            valid_stage1 <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        count_stage1 <= 4'd0;
                        acc_stage1 <= 17'd0;
                        multiplier_q_stage1 <= {multiplier, 1'b0}; // 扩展一位用于Booth算法
                        multiplicand_stage1 <= multiplicand;
                        valid_stage1 <= 1'b1;
                    end else begin
                        valid_stage1 <= 1'b0;
                    end
                end
                
                CALC: begin
                    if (valid_stage1 || count == 4'd0) begin
                        // 准备Booth编码
                        booth_op_stage1 <= multiplier_q_stage1[1:0];
                        
                        // 计数更新
                        if (count < 4'd8) begin
                            count_stage1 <= count + 1'b1;
                        end
                        valid_stage1 <= 1'b1;
                    end
                    
                    // 传递寄存器到下一级
                    multiplicand_stage1 <= multiplicand_stage1;
                    multiplier_q_stage1 <= multiplier_q_stage1;
                    acc_stage1 <= acc_stage3; // 从最后一级获取更新后的累加器结果
                end
                
                DONE: begin
                    valid_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // 流水线第二级 - 执行加/减操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_stage2 <= 17'd0;
            multiplier_q_stage2 <= 9'd0;
            multiplicand_stage2 <= 8'd0;
            acc_after_add_stage2 <= 17'd0;
            count_stage2 <= 4'd0;
            valid_stage2 <= 1'b0;
        end else begin
            // 传递流水线有效信号
            valid_stage2 <= valid_stage1;
            count_stage2 <= count_stage1;
            
            if (valid_stage1) begin
                // 根据Booth编码执行不同操作
                case (booth_op_stage1)
                    2'b01: acc_after_add_stage2 <= acc_stage1 + {multiplicand_stage1, 8'd0}; // +A
                    2'b10: acc_after_add_stage2 <= acc_stage1 - {multiplicand_stage1, 8'd0}; // -A
                    default: acc_after_add_stage2 <= acc_stage1; // 不操作
                endcase
                
                // 传递数据到下一级
                multiplicand_stage2 <= multiplicand_stage1;
                multiplier_q_stage2 <= multiplier_q_stage1;
                acc_stage2 <= acc_stage1; // 直接传递，不修改
            end
        end
    end
    
    // 流水线第三级 - 执行移位操作和准备下一轮
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_stage3 <= 17'd0;
            multiplier_q_stage3 <= 9'd0;
            multiplicand_stage3 <= 8'd0;
            count_stage3 <= 4'd0;
            valid_stage3 <= 1'b0;
            count <= 4'd0;
            product <= 16'd0;
            done <= 1'b0;
        end else begin
            // 传递流水线有效信号
            valid_stage3 <= valid_stage2;
            count_stage3 <= count_stage2;
            count <= count_stage3;
            
            if (valid_stage2) begin
                // 执行算术右移
                acc_stage3 <= {acc_after_add_stage2[16], acc_after_add_stage2[16:1]};
                multiplier_q_stage3 <= {1'b0, multiplier_q_stage2[8:1]};
                multiplicand_stage3 <= multiplicand_stage2;
            end
            
            // 处理完成状态
            if (state == DONE) begin
                product <= acc_stage3[15:0];
                done <= 1'b1;
            end else begin
                done <= 1'b0;
            end
        end
    end
endmodule