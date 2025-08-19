//SystemVerilog
module WindowAvgRecovery #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] din,
    output [WIDTH-1:0] dout
);
    // 内部寄存器和信号声明
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [WIDTH-1:0] dout_reg;
    wire [WIDTH-1:0] sum_result;
    wire [WIDTH-1:0] shift_result;
    
    // 组合逻辑：计算buffer内所有元素的和
    BufferSumCombLogic #(.WIDTH(WIDTH), .DEPTH(DEPTH)) 
        sum_calc (.buffer(buffer), .sum(sum_result));
    
    // 组合逻辑：先行借位减法器 - 实现除以4的功能
    LookaheadSubtractor #(.WIDTH(WIDTH)) 
        shift_sub (.a(sum_result), .b({2'b00, sum_result[WIDTH-1:2]}), .result(shift_result));
    
    // 时序逻辑：处理buffer移位和输出寄存
    integer i;
    always @(posedge clk) begin
        for (i = DEPTH-1; i > 0; i = i - 1) begin
            buffer[i] <= rst_n ? buffer[i-1] : {WIDTH{1'b0}};
        end
        buffer[0] <= rst_n ? din : {WIDTH{1'b0}};
        dout_reg <= rst_n ? shift_result : {WIDTH{1'b0}};
    end
    
    // 输出赋值
    assign dout = dout_reg;
    
endmodule

// 组合逻辑模块：计算buffer总和
module BufferSumCombLogic #(parameter WIDTH=8, DEPTH=4) (
    input [WIDTH-1:0] buffer [0:DEPTH-1],
    output [WIDTH-1:0] sum
);
    // 纯组合逻辑实现
    assign sum = buffer[0] + buffer[1] + buffer[2] + buffer[3];
endmodule

// 先行借位减法器模块 - 纯组合逻辑
module LookaheadSubtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] p, g;
    
    // 生成传播和生成信号
    assign p = a ^ b;
    assign g = (~a) & b;
    
    // 计算借位信号
    assign borrow[0] = 1'b0;  // 初始无借位
    
    genvar j;
    generate
        for (j = 0; j < WIDTH; j = j + 1) begin: borrow_gen
            assign borrow[j+1] = g[j] | (p[j] & borrow[j]);
        end
    endgenerate
    
    // 计算最终结果
    assign result = p ^ borrow[WIDTH-1:0];
    
endmodule