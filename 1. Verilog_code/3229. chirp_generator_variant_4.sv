//SystemVerilog
module chirp_generator(
    input clk,
    input rst,
    input [15:0] start_freq,
    input [15:0] freq_step,
    input [7:0] step_interval,
    output reg [7:0] chirp_out
);
    reg [15:0] freq;
    reg [15:0] phase_acc;
    reg [7:0] interval_counter;
    
    wire [15:0] next_phase_acc;
    
    // 使用跳跃进位加法器实现相位累加
    carry_skip_adder_16bit phase_accumulator(
        .a(phase_acc),
        .b(freq),
        .sum(next_phase_acc),
        .cout()
    );
    
    // 使用跳跃进位加法器实现频率步进
    wire [15:0] next_freq;
    wire carry_freq;
    
    carry_skip_adder_16bit freq_stepper(
        .a(freq),
        .b(freq_step),
        .sum(next_freq),
        .cout(carry_freq)
    );
    
    always @(posedge clk) begin
        if (rst) begin
            freq <= start_freq;
            phase_acc <= 16'd0;
            interval_counter <= 8'd0;
            chirp_out <= 8'd128;
        end else begin
            // 相位累加使用跳跃进位加法器结果
            phase_acc <= next_phase_acc;
            
            // Simple sine approximation using MSBs
            if (phase_acc[15:14] == 2'b00)
                chirp_out <= 8'd128 + {1'b0, phase_acc[13:7]};
            else if (phase_acc[15:14] == 2'b01)
                chirp_out <= 8'd255 - {1'b0, phase_acc[13:7]};
            else if (phase_acc[15:14] == 2'b10)
                chirp_out <= 8'd127 - {1'b0, phase_acc[13:7]};
            else
                chirp_out <= 8'd0 + {1'b0, phase_acc[13:7]};
                
            // 频率步进使用跳跃进位加法器结果
            if (interval_counter >= step_interval) begin
                interval_counter <= 8'd0;
                freq <= next_freq;
            end else begin
                interval_counter <= interval_counter + 8'd1;
            end
        end
    end
endmodule

// 4位块的跳跃进位加法器
module carry_skip_block_4bit(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout,
    output block_prop
);
    wire [3:0] p;  // 传播信号
    wire [3:0] g;  // 生成信号
    wire [4:0] c;  // 进位信号
    
    assign c[0] = cin;
    
    // 计算传播和生成信号
    assign p = a ^ b;
    assign g = a & b;
    
    // 计算每一位的进位
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    
    // 计算块传播信号
    assign block_prop = &p;
    
    // 跳跃进位逻辑
    assign cout = block_prop ? cin : c[4];
    
    // 计算和
    assign sum = p ^ {c[3:0]};
endmodule

// 16位跳跃进位加法器，使用4个4位块
module carry_skip_adder_16bit(
    input [15:0] a,
    input [15:0] b,
    output [15:0] sum,
    output cout
);
    wire [4:0] c;  // 块间进位
    wire [3:0] block_prop;  // 块传播信号
    
    assign c[0] = 1'b0;  // 初始进位为0
    
    // 实例化4个4位跳跃进位块
    carry_skip_block_4bit block0(
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(c[0]),
        .sum(sum[3:0]),
        .cout(c[1]),
        .block_prop(block_prop[0])
    );
    
    carry_skip_block_4bit block1(
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(c[1]),
        .sum(sum[7:4]),
        .cout(c[2]),
        .block_prop(block_prop[1])
    );
    
    carry_skip_block_4bit block2(
        .a(a[11:8]),
        .b(b[11:8]),
        .cin(c[2]),
        .sum(sum[11:8]),
        .cout(c[3]),
        .block_prop(block_prop[2])
    );
    
    carry_skip_block_4bit block3(
        .a(a[15:12]),
        .b(b[15:12]),
        .cin(c[3]),
        .sum(sum[15:12]),
        .cout(c[4]),
        .block_prop(block_prop[3])
    );
    
    assign cout = c[4];
endmodule