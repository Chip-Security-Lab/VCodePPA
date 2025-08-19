//SystemVerilog
module multi_waveform(
    input clk,
    input rst_n,
    input [1:0] wave_sel,
    output reg [7:0] wave_out
);
    reg [7:0] counter;
    reg direction;
    wire [7:0] next_counter;
    wire [7:0] triangle_value;
    
    // 使用改进的加法器进行计数器递增
    brent_kung_adder counter_adder(
        .a(counter),
        .b(8'd1),
        .sum(next_counter)
    );
    
    // 使用改进的加法器计算三角波反向值
    brent_kung_adder triangle_adder(
        .a(8'd255),
        .b(~counter),
        .sum(triangle_value)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;
            direction <= 1'b0;
            wave_out <= 8'd0;
        end else begin
            counter <= next_counter;
            
            case (wave_sel)
                2'b00: // Square wave
                    wave_out <= {8{counter[7]}};
                2'b01: // Sawtooth wave
                    wave_out <= counter;
                2'b10: begin // Triangle wave
                    if (!direction) begin
                        if (&counter) direction <= 1'b1;
                        wave_out <= counter;
                    end else begin
                        if (~|counter) direction <= 1'b0;
                        wave_out <= triangle_value;
                    end
                end
                2'b11: // Staircase wave
                    wave_out <= {counter[7:2], 2'b00};
            endcase
        end
    end
endmodule

// 优化的Brent-Kung加法器子模块
module brent_kung_adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    wire [7:0] p, g;
    
    // 阶段1: 生成传播(p)和生成(g)信号 - 简化表达
    assign p = a ^ b;
    assign g = a & b;
    
    // 阶段2: 计算组传播和组生成信号 - 优化布尔表达式
    // 第一级
    wire [3:0] p_1, g_1;
    assign p_1[0] = p[1] & p[0];
    assign g_1[0] = g[1] | (p[1] & g[0]);
    
    assign p_1[1] = p[3] & p[2];
    assign g_1[1] = g[3] | (p[3] & g[2]);
    
    assign p_1[2] = p[5] & p[4];
    assign g_1[2] = g[5] | (p[5] & g[4]);
    
    assign p_1[3] = p[7] & p[6];
    assign g_1[3] = g[7] | (p[7] & g[6]);
    
    // 第二级 - 优化表达式
    wire [1:0] p_2, g_2;
    assign p_2[0] = p_1[1] & p_1[0];
    assign g_2[0] = g_1[1] | (p_1[1] & g_1[0]);
    
    assign p_2[1] = p_1[3] & p_1[2];
    assign g_2[1] = g_1[3] | (p_1[3] & g_1[2]);
    
    // 第三级 - 保持不变，这已经是最优表达
    wire p_3, g_3;
    assign p_3 = p_2[1] & p_2[0];
    assign g_3 = g_2[1] | (p_2[1] & g_2[0]);
    
    // 阶段3: 计算进位信号 - 优化布尔表达式
    wire [7:0] c;
    assign c[0] = g[0];
    assign c[1] = g_1[0];
    assign c[2] = g[2] | (p[2] & c[1]);
    assign c[3] = g_2[0];
    assign c[4] = g[4] | (p[4] & c[3]);
    assign c[5] = g_1[2] | (p_1[2] & c[3]);
    
    // 简化c[6]的表达式，避免冗余项
    assign c[6] = g[6] | (p[6] & c[5]);
    assign c[7] = g_3;
    
    // 阶段4: 计算最终和 - 无需不必要的分割
    assign sum = p ^ {c[6:0], 1'b0};
endmodule