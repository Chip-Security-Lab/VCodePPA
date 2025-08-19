//SystemVerilog
module sync_integrator #(
    parameter DATA_W = 16,
    parameter ACC_W = 24
)(
    input clk, rst, clear_acc,
    input [DATA_W-1:0] in_data,
    output reg [ACC_W-1:0] out_data
);
    // 内部信号声明
    reg [ACC_W-1:0] scaled_out;
    reg [ACC_W-1:0] leak_factor;
    reg [ACC_W:0] borrow;  // 借位信号，比ACC_W多一位
    
    // 带状进位加法器的内部信号
    wire [7:0] a, b, sum;
    wire [7:0] p, g; // 传播和生成信号
    wire [7:0] c;    // 进位信号
    
    // 计算漏积分值 - 使用借位减法器思想
    // 漏积分器实现: y[n] = x[n] + a*y[n-1]，其中a=15/16
    always @(posedge clk) begin
        if (rst | clear_acc) begin
            out_data <= 0;
            scaled_out <= 0;
            leak_factor <= 0;
            borrow <= 0;
        end else begin
            // 计算漏因子(15/16)，使用借位减法而非乘法和移位
            leak_factor <= out_data;
            borrow[0] <= 0;
            
            // 使用借位减法器计算out_data - (out_data >> 4)
            // 相当于out_data * (1 - 1/16) = out_data * 15/16
            for (integer i = 0; i < ACC_W; i = i + 1) begin
                if (i < (ACC_W-4)) begin
                    scaled_out[i] <= out_data[i+4] ^ borrow[i];
                    borrow[i+1] <= out_data[i+4] ? 0 : borrow[i];
                end else begin
                    scaled_out[i] <= 0 ^ borrow[i];
                    borrow[i+1] <= borrow[i];
                end
            end
            
            // 使用带状进位加法器实现加法操作
            out_data <= carry_lookahead_adder(in_data[7:0], scaled_out[7:0], 1'b0)
                      | ({16'b0, carry_lookahead_adder(in_data[15:8], scaled_out[15:8], c[7])})
                      | ({24'b0, carry_lookahead_adder(8'b0, scaled_out[23:16], c[7])});
        end
    end
    
    // 带状进位加法器函数实现
    function [8:0] carry_lookahead_adder;
        input [7:0] a, b;
        input cin;
        
        reg [7:0] sum;
        reg [7:0] p, g; // 传播与生成信号
        reg [8:0] c; // 进位信号，包括最终进位
        
        begin
            // 计算传播和生成信号
            p = a ^ b;
            g = a & b;
            
            // 计算每一位的进位
            c[0] = cin;
            c[1] = g[0] | (p[0] & c[0]);
            c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
            c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
            c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
            c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | 
                   (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | 
                   (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                   (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | 
                   (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                   (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                   (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            c[8] = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | 
                   (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | 
                   (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | 
                   (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | 
                   (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
            
            // 计算每一位的和
            sum = p ^ c[7:0];
            
            // 返回结果（8位和+进位）
            carry_lookahead_adder = {c[8], sum};
        end
    endfunction
endmodule