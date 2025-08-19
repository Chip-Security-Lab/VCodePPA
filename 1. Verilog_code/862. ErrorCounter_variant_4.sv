//SystemVerilog
module ErrorCounter #(parameter WIDTH=8, MAX_ERR=3) (
    input clk, rst_n,
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output reg alarm
);
    reg [3:0] err_count;
    wire pattern_match;
    wire [3:0] next_err_count;
    wire next_alarm;
    
    // 并行前缀减法器实现
    wire [3:0] borrow;
    wire [3:0] prop;
    wire [3:0] gen;
    
    // 生成和传播信号
    assign gen[0] = ~data[0] & pattern[0];
    assign prop[0] = data[0] ^ pattern[0];
    
    assign gen[1] = ~data[1] & pattern[1];
    assign prop[1] = data[1] ^ pattern[1];
    
    assign gen[2] = ~data[2] & pattern[2];
    assign prop[2] = data[2] ^ pattern[2];
    
    assign gen[3] = ~data[3] & pattern[3];
    assign prop[3] = data[3] ^ pattern[3];
    
    // 并行前缀计算
    wire [3:0] prop_01 = prop[0] & prop[1];
    wire [3:0] prop_23 = prop[2] & prop[3];
    wire [3:0] prop_0123 = prop_01 & prop_23;
    
    wire [3:0] gen_01 = gen[1] | (prop[1] & gen[0]);
    wire [3:0] gen_23 = gen[3] | (prop[3] & gen[2]);
    wire [3:0] gen_0123 = gen_23 | (prop_23 & gen_01);
    
    // 最终借位计算
    assign borrow[0] = gen[0];
    assign borrow[1] = gen_01;
    assign borrow[2] = gen[2] | (prop[2] & gen_01);
    assign borrow[3] = gen_0123;
    
    // 结果计算
    assign pattern_match = ~(|borrow);
    
    // 错误计数逻辑
    assign next_err_count = pattern_match ? 4'd0 : err_count + 4'd1;
    assign next_alarm = (next_err_count >= MAX_ERR);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            err_count <= 4'd0;
            alarm <= 1'b0;
        end else begin
            err_count <= next_err_count;
            alarm <= next_alarm;
        end
    end
endmodule