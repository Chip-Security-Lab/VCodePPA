//SystemVerilog
module debounced_rst_sync #(
    parameter DEBOUNCE_LEN = 8
)(
    input  wire clk,
    input  wire noisy_rst_n,
    output reg  clean_rst_n
);
    reg noisy_rst_n_reg;
    reg [1:0] sync_flops;
    reg [3:0] debounce_counter;
    
    // 并行前缀加法器信号
    wire [3:0] counter_plus_one;
    wire [3:0] p, g; // 传播(propagate)和生成(generate)信号
    wire [3:0] c; // 进位信号
    
    // 将输入寄存化以减少输入到第一级寄存器的延迟
    always @(posedge clk) begin
        noisy_rst_n_reg <= noisy_rst_n;
    end
    
    // 定义传播和生成信号 (第一级)
    assign p[0] = debounce_counter[0];
    assign p[1] = debounce_counter[1];
    assign p[2] = debounce_counter[2];
    assign p[3] = debounce_counter[3];
    
    assign g[0] = 1'b1; // 初始进位为1，用于+1操作
    assign g[1] = 1'b0;
    assign g[2] = 1'b0;
    assign g[3] = 1'b0;
    
    // 计算进位信号 (使用前缀并行算法)
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & c[1]);
    assign c[3] = g[3] | (p[3] & c[2]);
    
    // 计算结果
    assign counter_plus_one[0] = p[0] ^ c[0];
    assign counter_plus_one[1] = p[1] ^ c[1];
    assign counter_plus_one[2] = p[2] ^ c[2];
    assign counter_plus_one[3] = p[3] ^ c[3];
    
    always @(posedge clk) begin
        // 将同步器的第一级前移至输入寄存器之后
        sync_flops[0] <= noisy_rst_n_reg;
        sync_flops[1] <= sync_flops[0];
        
        if (sync_flops[1] == 1'b0) begin
            if (debounce_counter < DEBOUNCE_LEN-1)
                debounce_counter <= counter_plus_one;
            else
                clean_rst_n <= 1'b0;
        end else begin
            debounce_counter <= 0;
            clean_rst_n <= 1'b1;
        end
    end
endmodule