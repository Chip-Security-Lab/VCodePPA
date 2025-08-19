//SystemVerilog
//IEEE 1364-2005
module serial_display_codec (
    input clk, rst_n,
    input [23:0] rgb_in,
    input start_tx,
    output reg serial_data,
    output reg serial_clk,
    output reg tx_active,
    output reg tx_done
);
    
    reg [4:0] bit_counter;
    reg [15:0] shift_reg;
    reg data_update;
    
    // 优化后的计数器逻辑 - 不使用Han-Carlson加法器
    wire [4:0] next_bit_counter = bit_counter + 5'd1;
    wire bit_counter_done = (bit_counter == 5'd15);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_counter <= 5'd0;
            shift_reg <= 16'd0;
            serial_data <= 1'b0;
            serial_clk <= 1'b0;
            tx_active <= 1'b0;
            tx_done <= 1'b0;
            data_update <= 1'b0;
        end else begin
            // 默认赋值以防止锁存器
            data_update <= 1'b0;
            
            // 开始新传输逻辑
            if (start_tx && !tx_active && !tx_done) begin
                // 优化的RGB888到RGB565转换
                shift_reg <= {rgb_in[23:19], rgb_in[15:10], rgb_in[7:3]};
                bit_counter <= 5'd0;
                tx_active <= 1'b1;
                tx_done <= 1'b0;
                serial_clk <= 1'b0;
            end 
            // 传输进行中
            else if (tx_active) begin
                // 切换串行时钟
                serial_clk <= ~serial_clk;
                
                // 数据在串行时钟下降沿变化
                if (serial_clk && !data_update) begin
                    serial_data <= shift_reg[15];
                    shift_reg <= {shift_reg[14:0], 1'b0};
                    data_update <= 1'b1;
                    
                    // 检查传输是否完成
                    if (bit_counter_done) begin
                        tx_active <= 1'b0;
                        tx_done <= 1'b1;
                    end else begin
                        bit_counter <= next_bit_counter;
                    end
                end
            end 
            // 当开始信号取消断言时重置完成标志
            else if (tx_done && !start_tx) begin
                tx_done <= 1'b0;
            end
        end
    end
endmodule

module han_carlson_adder #(
    parameter WIDTH = 24
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // 预计算阶段
    wire [WIDTH-1:0] p, g;
    assign p = a ^ b;
    assign g = a & b;
    
    // 组传播和生成信号
    wire [WIDTH:0] P, G;
    assign P[0] = cin;
    assign G[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign P[i+1] = p[i];
            assign G[i+1] = g[i];
        end
    endgenerate
    
    // Han-Carlson优化的前缀树计算
    // 优化的级联处理
    wire [WIDTH:0] P_even, G_even;
    wire [WIDTH:0] P_L1, G_L1;
    wire [WIDTH:0] P_L2, G_L2;
    
    // 阶段1: 对偶数位进行处理
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : gen_stage1
            if (i % 2 == 0) begin
                assign P_even[i] = (i > 0) ? P[i] & P[i-1] : P[i];
                assign G_even[i] = (i > 0) ? G[i] | (P[i] & G[i-1]) : G[i];
            end else begin
                assign P_even[i] = P[i];
                assign G_even[i] = G[i];
            end
        end
    endgenerate
    
    // 阶段2: 对所有位合并进行处理
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : gen_stage2
            if (i % 2 == 0 && i > 1) begin
                // 使用范围比较优化逻辑
                assign P_L1[i] = P_even[i] & P_even[i-2];
                assign G_L1[i] = G_even[i] | (P_even[i] & G_even[i-2]);
            end else begin
                assign P_L1[i] = P_even[i];
                assign G_L1[i] = G_even[i];
            end
        end
    endgenerate
    
    // 阶段3: 奇数位处理
    generate
        for (i = 0; i <= WIDTH; i = i + 1) begin : gen_stage3
            if (i % 2 == 1) begin
                assign P_L2[i] = P_L1[i] & P_L1[i-1];
                assign G_L2[i] = G_L1[i] | (P_L1[i] & G_L1[i-1]);
            end else begin
                assign P_L2[i] = P_L1[i];
                assign G_L2[i] = G_L1[i];
            end
        end
    endgenerate
    
    // 优化的最终和计算
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = p[i] ^ G_L2[i];
        end
    endgenerate
    
    // 进位输出
    assign cout = G_L2[WIDTH];
    
endmodule