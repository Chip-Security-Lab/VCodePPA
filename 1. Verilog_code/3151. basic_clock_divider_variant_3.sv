//SystemVerilog
module basic_clock_divider(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    reg [3:0] counter;
    wire [3:0] next_counter;
    
    // 跳跃进位加法器实现
    wire [3:0] p; // 进位传播信号
    wire [3:0] g; // 进位生成信号
    wire [4:0] c; // 进位信号，包括输入进位c[0]
    
    // 计算进位传播和生成信号
    assign p[0] = counter[0];
    assign p[1] = counter[1];
    assign p[2] = counter[2];
    assign p[3] = counter[3];
    
    assign g[0] = 1'b0;
    assign g[1] = counter[1] & counter[0];
    assign g[2] = counter[2] & counter[1];
    assign g[3] = counter[3] & counter[2];
    
    // 计算跳跃进位
    assign c[0] = 1'b1; // 输入进位为1（加1操作）
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & c[1]);
    assign c[3] = g[2] | (p[2] & c[2]);
    assign c[4] = g[3] | (p[3] & c[3]);
    
    // 计算和
    assign next_counter[0] = p[0] ^ c[0];
    assign next_counter[1] = p[1] ^ c[1];
    assign next_counter[2] = p[2] ^ c[2];
    assign next_counter[3] = p[3] ^ c[3];
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            clk_out <= 1'b0;
        end else begin
            if (counter == 4'd9) begin
                counter <= 4'd0;
                clk_out <= ~clk_out;
            end else begin
                counter <= next_counter;
            end
        end
    end
endmodule