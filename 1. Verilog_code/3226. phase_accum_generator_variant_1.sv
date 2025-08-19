//SystemVerilog
module phase_accum_generator(
    input clock,
    input reset_n,
    input [11:0] phase_increment,
    input [1:0] waveform_select,
    output reg [7:0] wave_out
);
    reg [11:0] phase_accumulator;
    wire [11:0] next_phase;
    
    // 使用并行前缀加法器实现
    parallel_prefix_adder #(
        .WIDTH(12)
    ) phase_adder (
        .a(phase_accumulator),
        .b(phase_increment),
        .cin(1'b0),
        .sum(next_phase)
    );
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n)
            phase_accumulator <= 12'd0;
        else
            phase_accumulator <= next_phase;
    end
    
    always @(posedge clock) begin
        case (waveform_select)
            2'b00: // Sawtooth
                wave_out <= phase_accumulator[11:4];
            2'b01: // Triangle
                wave_out <= phase_accumulator[11] ? ~phase_accumulator[10:3] : phase_accumulator[10:3];
            2'b10: // Square
                wave_out <= phase_accumulator[11] ? 8'd255 : 8'd0;
            2'b11: // Pulse
                wave_out <= (phase_accumulator[11:8] < 4'd4) ? 8'd255 : 8'd0;
        endcase
    end
endmodule

module parallel_prefix_adder #(
    parameter WIDTH = 12
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum
);
    // 生成传播和生成信号
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    
    // 第一级: 计算初始传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
    endgenerate
    
    // 定义组传播和组生成信号 - 使用Kogge-Stone算法
    wire [WIDTH-1:0] pp[0:$clog2(WIDTH)];
    wire [WIDTH-1:0] gg[0:$clog2(WIDTH)];
    
    // 初始化第0级
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: init_pg
            assign pp[0][i] = p[i];
            assign gg[0][i] = g[i];
        end
    endgenerate
    
    // 前缀计算 - Kogge-Stone并行前缀结构
    genvar j, k;
    generate
        for (j = 0; j < $clog2(WIDTH); j = j + 1) begin: prefix_level
            for (k = 0; k < WIDTH; k = k + 1) begin: prefix_bit
                if (k >= (1 << j)) begin
                    // 组合两组前缀
                    assign pp[j+1][k] = pp[j][k] & pp[j][k-(1<<j)];
                    assign gg[j+1][k] = gg[j][k] | (pp[j][k] & gg[j][k-(1<<j)]);
                end else begin
                    // 前面的位没有足够的前序位，保持不变
                    assign pp[j+1][k] = pp[j][k];
                    assign gg[j+1][k] = gg[j][k];
                end
            end
        end
    endgenerate
    
    // 计算进位信号
    wire [WIDTH:0] carry;
    assign carry[0] = cin;
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_carry
            // 使用最终级的组生成信号计算进位
            if (i == 0) begin
                assign carry[i+1] = gg[0][i] | (pp[0][i] & cin);
            end else begin
                assign carry[i+1] = gg[$clog2(WIDTH)][i-1] | (pp[$clog2(WIDTH)][i-1] & cin);
            end
        end
    endgenerate
    
    // 最终求和
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
endmodule