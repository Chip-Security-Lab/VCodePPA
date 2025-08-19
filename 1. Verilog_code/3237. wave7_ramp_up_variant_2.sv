//SystemVerilog
module wave7_ramp_up #(
    parameter WIDTH = 8,
    parameter STEP  = 2
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // 定义内部信号
    wire [WIDTH-1:0] next_wave;
    
    // 实例化优化的加法器
    optimized_adder #(
        .WIDTH(WIDTH),
        .STEP(STEP)
    ) adder_inst (
        .a(wave_out),
        .sum(next_wave)
    );
    
    // 寄存器逻辑
    always @(posedge clk) begin
        if(rst) wave_out <= 0;
        else    wave_out <= next_wave;
    end
endmodule

// 优化的加法器模块 - 使用常量步进值进行优化
module optimized_adder #(
    parameter WIDTH = 8,
    parameter STEP = 2
)(
    input  wire [WIDTH-1:0] a,
    output wire [WIDTH-1:0] sum
);
    // 优化1: 对固定的STEP值进行专门优化
    generate
        if (STEP == 1) begin : step_is_one
            // STEP为1时的简单递增
            assign sum = a + 1'b1;
        end
        else if (STEP == 2) begin : step_is_two
            // STEP为2时的优化加法
            wire carry;
            // 仅需计算最低位的进位
            assign carry = a[0] & 1'b1;
            // 采用简化的加法逻辑
            assign sum[0] = ~a[0];             // LSB翻转
            assign sum[1] = a[1] ^ carry;      // 根据进位计算第二位
            // 其余位的进位传播
            genvar i;
            for(i = 2; i < WIDTH; i = i + 1) begin : gen_higher_bits
                assign sum[i] = a[i] ^ (a[i-1] & a[i-2]);
            end
        end
        else begin : general_step
            // 一般情况下的加法逻辑 - 使用优化的超前进位结构
            wire [WIDTH:0] c;  // 进位信号
            wire [WIDTH-1:0] g;  // 生成
            wire [WIDTH-1:0] p;  // 传播
            
            // 固定STEP值的处理
            wire [WIDTH-1:0] fixed_b;
            assign fixed_b = STEP[WIDTH-1:0];
            
            // 初始进位
            assign c[0] = 1'b0;
            
            genvar i;
            for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
                // 简化生成和传播计算
                assign g[i] = a[i] & fixed_b[i];
                assign p[i] = a[i] | fixed_b[i];
            end
            
            // 分组进位计算 - 使用2位分组的超前进位结构
            for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
                if (i == 0)
                    assign c[i+1] = g[i];
                else if (i % 2 == 1)
                    assign c[i+1] = g[i] | (p[i] & c[i]);
                else
                    assign c[i+1] = g[i] | (p[i] & c[i-1]);
            end
            
            // 计算最终和
            for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
                assign sum[i] = a[i] ^ fixed_b[i] ^ c[i];
            end
        end
    endgenerate
endmodule