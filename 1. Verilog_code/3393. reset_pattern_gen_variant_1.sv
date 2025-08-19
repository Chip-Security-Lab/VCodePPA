//SystemVerilog
module reset_pattern_gen(
    input wire clk,
    input wire trigger,
    input wire [7:0] pattern,
    output reg [7:0] reset_seq
);
    // 内部状态信号
    reg [2:0] bit_pos;
    reg pattern_loading;
    
    // 位置计数器和状态控制 - 优化比较逻辑
    always @(posedge clk) begin
        if (trigger) begin
            bit_pos <= 3'b0;
            pattern_loading <= 1'b1;
        end else if (pattern_loading) begin
            if (bit_pos == 3'b111) begin
                pattern_loading <= 1'b0;
            end else begin
                bit_pos <= bit_pos + 1'b1;
            end
        end
    end
    
    // 重置序列生成 - 优化比较和赋值逻辑
    always @(posedge clk) begin
        if (trigger) begin
            reset_seq <= 8'h0;
        end else if (pattern_loading) begin
            if (|bit_pos[2:0] != 3'b111) begin  // 使用归约运算符进行有效比较
                reset_seq[bit_pos] <= pattern[bit_pos];
            end
        end
    end
endmodule