//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module debounced_rst_sync #(
    parameter DEBOUNCE_LEN = 8
)(
    input  wire clk,
    input  wire noisy_rst_n,
    output reg  clean_rst_n
);
    reg [1:0] sync_flops;
    reg [3:0] debounce_counter;
    
    // 使用并行前缀加法器算法的信号
    wire [3:0] counter_next;
    wire [3:0] increment = 4'b0001;
    
    // 前缀加法器信号
    wire [3:0] p; // 传播信号
    wire [3:0] g; // 生成信号
    wire [3:0] c; // 进位信号
    
    // 第一级：生成P和G信号
    assign p[0] = debounce_counter[0] | increment[0];
    assign p[1] = debounce_counter[1] | increment[1];
    assign p[2] = debounce_counter[2] | increment[2];
    assign p[3] = debounce_counter[3] | increment[3];
    
    assign g[0] = debounce_counter[0] & increment[0];
    assign g[1] = debounce_counter[1] & increment[1];
    assign g[2] = debounce_counter[2] & increment[2];
    assign g[3] = debounce_counter[3] & increment[3];
    
    // 第二级：计算进位信号
    assign c[0] = g[0];
    assign c[1] = g[1] | (p[1] & c[0]);
    assign c[2] = g[2] | (p[2] & c[1]);
    assign c[3] = g[3] | (p[3] & c[2]);
    
    // 第三级：计算和
    assign counter_next[0] = debounce_counter[0] ^ increment[0];
    assign counter_next[1] = debounce_counter[1] ^ increment[1] ^ c[0];
    assign counter_next[2] = debounce_counter[2] ^ increment[2] ^ c[1];
    assign counter_next[3] = debounce_counter[3] ^ increment[3] ^ c[2];
    
    always @(posedge clk) begin
        sync_flops <= {sync_flops[0], noisy_rst_n};
        
        if (sync_flops[1] == 1'b0 && debounce_counter < DEBOUNCE_LEN-1)
            debounce_counter <= counter_next;
        else if (sync_flops[1] == 1'b0 && debounce_counter >= DEBOUNCE_LEN-1)
            clean_rst_n <= 1'b0;
        else if (sync_flops[1] == 1'b1) begin
            debounce_counter <= 0;
            clean_rst_n <= 1'b1;
        end
    end
endmodule

`default_nettype wire