//SystemVerilog
module I2C_Controller #(
    parameter ADDR_WIDTH = 7
)(
    input clk, rst_n,
    input start,
    input [ADDR_WIDTH-1:0] dev_addr,
    input [7:0] data_tx,
    output reg [7:0] data_rx,
    output reg ack_error,
    inout sda,
    inout scl
);
    // 使用localparam代替typedef enum
    localparam IDLE = 3'b000, START = 3'b001, ADDR = 3'b010, 
             ACK1 = 3'b011, DATA = 3'b100, ACK2 = 3'b101, STOP = 3'b110;
    
    reg [2:0] current_state, next_state;
    reg [2:0] current_state_stage1, next_state_stage1;
    
    reg sda_out, scl_out;
    reg sda_out_stage1, scl_out_stage1;
    reg [3:0] bit_counter, bit_counter_stage1;
    reg [7:0] shift_reg, shift_reg_stage1;
    reg rw_bit, rw_bit_stage1;
    reg sda_oe, sda_oe_stage1; // 添加输出使能控制

    // Kogge-Stone加法器信号
    wire [3:0] ks_sum;
    reg [3:0] ks_a;
    reg [3:0] ks_b;
    reg [3:0] ks_a_stage1, ks_b_stage1;
    wire [3:0] ks_sum_stage1;
    
    // 流水线寄存器
    reg start_stage1;
    reg [ADDR_WIDTH-1:0] dev_addr_stage1;
    reg [7:0] data_tx_stage1;
    reg sda_sample, sda_sample_stage1;
    
    // Kogge-Stone加法器实例 - 第一级流水线
    kogge_stone_adder ks_adder_stage1(
        .a(ks_a_stage1),
        .b(ks_b_stage1),
        .sum(ks_sum_stage1)
    );
    
    // Kogge-Stone加法器实例 - 第二级流水线
    kogge_stone_adder ks_adder(
        .a(ks_a),
        .b(ks_b),
        .sum(ks_sum)
    );

    // 三态缓冲实现
    assign sda = sda_oe ? 1'b0 : 1'bz; // 当sda_oe为1时输出低电平，否则高阻态
    assign scl = scl_out ? 1'bz : 1'b0; // 当scl_out为1时高阻态，否则输出低电平

    // 采样SDA信号
    always @(posedge clk) begin
        sda_sample <= sda;
    end

    // 第一级流水线 - 状态转移和数据预处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state_stage1 <= IDLE;
            start_stage1 <= 1'b0;
            dev_addr_stage1 <= 0;
            data_tx_stage1 <= 0;
            sda_sample_stage1 <= 1'b0;
            bit_counter_stage1 <= 0;
            shift_reg_stage1 <= 0;
            rw_bit_stage1 <= 0;
            scl_out_stage1 <= 1'b1;
            sda_oe_stage1 <= 1'b0;
            ks_a_stage1 <= 4'b0000;
            ks_b_stage1 <= 4'b0000;
        end else begin
            current_state_stage1 <= next_state;
            start_stage1 <= start;
            dev_addr_stage1 <= dev_addr;
            data_tx_stage1 <= data_tx;
            sda_sample_stage1 <= sda_sample;
            
            // 预处理逻辑
            case(current_state)
                IDLE: begin
                    scl_out_stage1 <= 1'b1;
                    sda_oe_stage1 <= 1'b0;
                    if (start) begin
                        shift_reg_stage1 <= {dev_addr, rw_bit};
                    end
                end
                ADDR, DATA: begin
                    if (bit_counter < 8) begin
                        // 预计算Kogge-Stone加法器
                        ks_a_stage1 <= bit_counter;
                        ks_b_stage1 <= 4'b0001;
                    end
                    bit_counter_stage1 <= bit_counter;
                    shift_reg_stage1 <= shift_reg;
                    rw_bit_stage1 <= rw_bit;
                    scl_out_stage1 <= scl_out;
                    sda_oe_stage1 <= sda_oe;
                end
                default: begin
                    bit_counter_stage1 <= bit_counter;
                    shift_reg_stage1 <= shift_reg;
                    rw_bit_stage1 <= rw_bit;
                    scl_out_stage1 <= scl_out;
                    sda_oe_stage1 <= sda_oe;
                end
            endcase
        end
    end

    // 第二级流水线 - 主状态机和I2C操作执行
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            scl_out <= 1'b1;
            sda_out <= 1'b1;
            sda_oe <= 1'b0; // 默认为高阻态
            bit_counter <= 0;
            shift_reg <= 0;
            data_rx <= 0;
            ack_error <= 0;
            rw_bit <= 0;
            ks_a <= 4'b0000;
            ks_b <= 4'b0000;
        end else begin
            current_state <= current_state_stage1;
            
            // 主状态机逻辑
            case(current_state_stage1)
                IDLE: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0; // 高阻态
                    if (start_stage1) begin
                        shift_reg <= {dev_addr_stage1, rw_bit_stage1};
                    end
                end
                START: begin
                    sda_oe <= 1'b1; // 产生START条件：SDA从高到低
                    scl_out <= 1'b1;
                end
                ADDR: begin
                    if (bit_counter_stage1 < 8) begin
                        if (scl_out_stage1 == 1'b0) begin
                            sda_oe <= ~shift_reg_stage1[7]; // 注意反转，因为sda_oe=1输出低电平
                            scl_out <= 1'b1; // 产生时钟上升沿
                        end else begin
                            scl_out <= 1'b0; // 产生时钟下降沿
                            shift_reg <= {shift_reg_stage1[6:0], 1'b0};
                            // 使用Kogge-Stone加法器递增bit_counter
                            bit_counter <= ks_sum_stage1;
                        end
                    end
                end
                ACK1: begin
                    if (scl_out_stage1 == 1'b0) begin
                        sda_oe <= 1'b0; // 释放SDA线等待ACK
                        scl_out <= 1'b1;
                    end else begin
                        ack_error <= sda_sample_stage1; // 采样SDA线
                        scl_out <= 1'b0;
                        bit_counter <= 0;
                        if (!rw_bit_stage1) shift_reg <= data_tx_stage1;
                    end
                end
                DATA: begin
                    if (bit_counter_stage1 < 8) begin
                        if (scl_out_stage1 == 1'b0) begin
                            sda_oe <= rw_bit_stage1 ? 1'b0 : ~shift_reg_stage1[7];
                            scl_out <= 1'b1;
                        end else begin
                            if (rw_bit_stage1) shift_reg <= {shift_reg_stage1[6:0], sda_sample_stage1};
                            scl_out <= 1'b0;
                            if (!rw_bit_stage1) shift_reg <= {shift_reg_stage1[6:0], 1'b0};
                            // 使用Kogge-Stone加法器递增bit_counter
                            bit_counter <= ks_sum_stage1;
                        end
                    end
                end
                ACK2: begin
                    if (scl_out_stage1 == 1'b0) begin
                        sda_oe <= rw_bit_stage1 ? 1'b1 : 1'b0; // 主机给出ACK或等待从机ACK
                        scl_out <= 1'b1;
                    end else begin
                        if (!rw_bit_stage1) ack_error <= sda_sample_stage1;
                        scl_out <= 1'b0;
                        data_rx <= shift_reg_stage1;
                    end
                end
                STOP: begin
                    if (scl_out_stage1 == 1'b0) begin
                        sda_oe <= 1'b1; // SDA先保持低
                        scl_out <= 1'b1;
                    end else begin
                        sda_oe <= 1'b0; // 然后拉高产生STOP条件
                    end
                end
                default: begin
                    scl_out <= 1'b1;
                    sda_oe <= 1'b0;
                end
            endcase
        end
    end

    // 状态转移逻辑 - 提前一级流水线
    always @(*) begin
        next_state = current_state;
        case(current_state)
            IDLE: if (start) next_state = START;
            START: next_state = ADDR;
            ADDR: if (bit_counter == 8) next_state = ACK1;
            ACK1: next_state = DATA;
            DATA: if (bit_counter == 8) next_state = ACK2;
            ACK2: next_state = STOP;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
endmodule

// Kogge-Stone 4位并行前缀加法器流水线优化版
module kogge_stone_adder(
    input [3:0] a,
    input [3:0] b,
    output [3:0] sum
);
    // 第一阶段：生成和传播信号
    wire [3:0] p, g;
    assign p = a ^ b;          // 生成传播信号
    assign g = a & b;          // 生成生成信号
    
    // 第二阶段：前缀计算
    // Level 1: 距离为1的前缀计算
    wire [3:0] p1, g1;
    assign g1[0] = g[0];
    assign p1[0] = p[0];
    
    assign g1[1] = g[1] | (p[1] & g[0]);
    assign p1[1] = p[1] & p[0];
    
    assign g1[2] = g[2] | (p[2] & g[1]);
    assign p1[2] = p[2] & p[1];
    
    assign g1[3] = g[3] | (p[3] & g[2]);
    assign p1[3] = p[3] & p[2];
    
    // Level 2: 距离为2的前缀计算
    wire [3:0] p2, g2;
    assign g2[0] = g1[0];
    assign p2[0] = p1[0];
    
    assign g2[1] = g1[1];
    assign p2[1] = p1[1];
    
    assign g2[2] = g1[2] | (p1[2] & g1[0]);
    assign p2[2] = p1[2] & p1[0];
    
    assign g2[3] = g1[3] | (p1[3] & g1[1]);
    assign p2[3] = p1[3] & p1[1];
    
    // 第三阶段：计算和
    wire [4:0] carry;
    assign carry[0] = 1'b0;    // 初始进位为0
    assign carry[1] = g2[0];
    assign carry[2] = g2[1];
    assign carry[3] = g2[2];
    assign carry[4] = g2[3];
    
    // 计算最终结果
    assign sum = p ^ carry[3:0];
endmodule