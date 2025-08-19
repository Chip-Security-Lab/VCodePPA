//SystemVerilog
module duty_preserve_divider (
    input wire clock_in, 
    input wire n_reset, 
    input wire [3:0] div_ratio,
    output wire clock_out
);
    reg [3:0] counter;
    reg toggle_signal;
    reg out_reg;
    
    wire [3:0] next_counter;
    
    // Han-Carlson 4-bit adder implementation
    han_carlson_adder #(
        .WIDTH(4)
    ) counter_adder (
        .a(counter),
        .b(4'b0001),
        .sum(next_counter),
        .cout()
    );
    
    // 计算阶段 - 确定是否需要翻转输出
    always @(posedge clock_in or negedge n_reset) begin
        if (!n_reset) begin
            counter <= 4'd0;
            toggle_signal <= 1'b0;
        end else begin
            toggle_signal <= 1'b0; // Default value
            if (counter >= div_ratio - 1) begin
                counter <= 4'd0;
                toggle_signal <= 1'b1; // Signal to toggle in next stage
            end else
                counter <= next_counter;
        end
    end
    
    // 输出阶段 - 实际翻转输出寄存器
    always @(posedge clock_in or negedge n_reset) begin
        if (!n_reset) begin
            out_reg <= 1'b0;
        end else begin
            if (toggle_signal)
                out_reg <= ~out_reg;
        end
    end
    
    // 分配输出
    assign clock_out = out_reg;
    
endmodule

module han_carlson_adder #(
    parameter WIDTH = 4
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // 阶段 1: 生成和传播信号
    wire [WIDTH-1:0] g_in, p_in;
    wire [WIDTH:0] g_out, p_out;
    wire [WIDTH-1:0] g_mid, p_mid;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign g_in[i] = a[i] & b[i];       // 生成信号
            assign p_in[i] = a[i] | b[i];       // 传播信号
        end
    endgenerate
    
    // 阶段 2: 前缀计算 - Han-Carlson算法的核心
    // 偶数位先进行并行前缀计算
    assign g_mid[0] = g_in[0];
    assign p_mid[0] = p_in[0];
    
    generate
        for (i = 2; i < WIDTH; i = i + 2) begin : gen_even_prefix
            assign g_mid[i] = g_in[i] | (p_in[i] & g_in[i-1]);
            assign p_mid[i] = p_in[i] & p_in[i-1];
        end
    endgenerate
    
    // 奇数位基于偶数位更新
    generate
        for (i = 1; i < WIDTH; i = i + 2) begin : gen_odd_prefix
            if (i == 1) begin
                assign g_mid[i] = g_in[i] | (p_in[i] & g_in[i-1]);
                assign p_mid[i] = p_in[i] & p_in[i-1];
            end else begin
                assign g_mid[i] = g_in[i] | (p_in[i] & g_mid[i-2]);
                assign p_mid[i] = p_in[i] & p_mid[i-2];
            end
        end
    endgenerate
    
    // 最终进位传播
    assign g_out[0] = 1'b0; // 初始进位为0
    
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
            assign g_out[i+1] = g_mid[i] | (p_mid[i] & g_out[i]);
        end
    endgenerate
    
    // 阶段 3: 和的计算
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = a[i] ^ b[i] ^ g_out[i];
        end
    endgenerate
    
    // 最终进位输出
    assign cout = g_out[WIDTH];
    
endmodule