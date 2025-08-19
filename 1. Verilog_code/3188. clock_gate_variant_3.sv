//SystemVerilog
// 顶层模块
module clock_gate (
    input  wire clk,
    input  wire enable,
    output wire gated_clk
);
    // 内部信号声明
    wire latch_output;
    
    // 实例化子模块
    enable_latch u_enable_latch (
        .clk    (clk),
        .enable (enable),
        .q      (latch_output)
    );
    
    gate_logic u_gate_logic (
        .clk          (clk),
        .latch_output (latch_output),
        .gated_clk    (gated_clk)
    );
    
endmodule

// 时钟使能锁存器子模块
module enable_latch (
    input  wire clk,
    input  wire enable,
    output reg  q
);
    // 锁存器设计，在时钟高电平时锁存enable信号
    always @(*) begin
        if (clk) 
            q = enable;
    end
    
endmodule

// 门控逻辑子模块
module gate_logic (
    input  wire clk,
    input  wire latch_output,
    output wire gated_clk
);
    // 使用AND门实现时钟门控
    assign gated_clk = clk & latch_output;
    
endmodule

// 基拉斯基乘法器模块
module karatsuba_multiplier (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [15:0] result
);
    // 内部信号声明
    wire [3:0] a_high, a_low, b_high, b_low;
    wire [7:0] z0, z1, z2;
    wire [7:0] temp1, temp2;
    
    // 分解输入为高4位和低4位
    assign a_high = a[7:4];
    assign a_low = a[3:0];
    assign b_high = b[7:4];
    assign b_low = b[3:0];
    
    // 计算z0 = a_low * b_low
    assign z0 = a_low * b_low;
    
    // 计算z1 = a_high * b_high
    assign z1 = a_high * b_high;
    
    // 计算z2 = (a_high + a_low) * (b_high + b_low)
    assign temp1 = a_high + a_low;
    assign temp2 = b_high + b_low;
    assign z2 = temp1 * temp2;
    
    // 计算最终结果: result = z1 * 2^8 + (z2 - z1 - z0) * 2^4 + z0
    assign result = {z1, 8'b0} + ((z2 - z1 - z0) << 4) + z0;
    
endmodule