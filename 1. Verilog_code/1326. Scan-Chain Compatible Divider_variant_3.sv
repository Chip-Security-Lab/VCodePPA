//SystemVerilog
module scan_divider (
    input clk, rst_n, scan_en, scan_in,
    output reg clk_div,
    output scan_out
);
    reg [2:0] counter;
    wire [2:0] next_counter;
    wire counter_reset;
    wire counter_toggle;
    
    // 组合逻辑部分 - 曼彻斯特进位链加法器
    manchester_adder adder_inst (
        .counter(counter),
        .sum(next_counter)
    );
    
    // 组合逻辑部分 - 控制信号生成
    assign counter_reset = (counter == 3'b111);
    assign counter_toggle = counter_reset;
    assign scan_out = counter[2];
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'b000;
            clk_div <= 1'b0;
        end else if (scan_en) begin
            counter <= {counter[1:0], scan_in};
        end else if (counter_reset) begin
            counter <= 3'b000;
            clk_div <= ~clk_div;
        end else begin
            counter <= next_counter;
        end
    end
    
endmodule

// 组合逻辑模块 - 曼彻斯特进位链加法器
module manchester_adder (
    input [2:0] counter,
    output [2:0] sum
);
    // 曼彻斯特进位链加法器信号
    wire [2:0] p; // 传播信号
    wire [2:0] g; // 生成信号
    wire [3:0] c; // 进位信号
    
    // 生成传播和生成信号
    assign p = counter | 3'b001; // 传播 = a OR b
    assign g = counter & 3'b001; // 生成 = a AND b
    
    // 曼彻斯特进位链实现
    assign c[0] = 1'b0; // 初始进位为0
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    
    // 使用XOR计算和
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    assign sum[2] = p[2] ^ c[2];
    
endmodule