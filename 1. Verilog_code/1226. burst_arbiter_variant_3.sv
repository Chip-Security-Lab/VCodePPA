//SystemVerilog
module burst_arbiter #(WIDTH=4, BURST=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [3:0] counter;
    reg [WIDTH-1:0] current;
    wire [WIDTH-1:0] neg_req_i;
    wire [WIDTH-1:0] prefix_sub_result;

    // 并行前缀减法器实现
    parallel_prefix_subtractor #(.WIDTH(WIDTH)) subtractor (
        .minuend(4'b0),
        .subtrahend(req_i),
        .result(neg_req_i)
    );

    // 计算req_i & (~req_i + 1)，使用并行前缀减法器的结果
    assign prefix_sub_result = req_i & neg_req_i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <= 0;
            current <= 0;
        end else begin
            if(counter == 0) begin
                current <= prefix_sub_result;
                counter <= prefix_sub_result ? BURST-1 : 0;
            end else begin
                counter <= counter - 1;
            end
            grant_o <= current;
        end
    end
endmodule

// 并行前缀减法器模块
module parallel_prefix_subtractor #(parameter WIDTH=4) (
    input [WIDTH-1:0] minuend,
    input [WIDTH-1:0] subtrahend,
    output [WIDTH-1:0] result
);
    // 并行前缀减法器的内部信号
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    wire [WIDTH:0] c;   // 进位信号
    wire [WIDTH-1:0] sub_not;

    // 第一阶段：生成初始的传播和生成信号
    assign sub_not = ~subtrahend;
    assign p = minuend ^ sub_not;
    assign g = minuend & sub_not;
    
    // 设置初始进位为1（减法需要）
    assign c[0] = 1'b1;
    
    // 第二阶段：并行前缀树计算进位
    // 4位减法器的前缀计算
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // 第三阶段：计算最终结果
    assign result = p ^ c[WIDTH-1:0];
endmodule