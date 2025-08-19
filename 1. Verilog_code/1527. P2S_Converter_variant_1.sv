//SystemVerilog
// IEEE 1364-2005
module P2S_Converter #(parameter WIDTH=8) (
    input clk, load,
    input [WIDTH-1:0] parallel_in,
    output reg serial_out
);
    reg [WIDTH-1:0] buffer;
    reg [3:0] count;
    
    // 前级寄存器 - 将输入数据提前缓存
    reg [WIDTH-1:0] parallel_in_reg;
    reg load_reg;
    
    // 并行前缀减法器信号
    wire [3:0] count_minus_one;
    wire [3:0] borrow;
    
    // 生成借位信号 (G - Generate, P - Propagate)
    wire [3:0] G, P;
    assign G = ~count & 4'b0001;  // 生成借位
    assign P = ~count;            // 传播借位
    
    // 前缀计算借位 - 并行树形结构
    assign borrow[0] = G[0];
    assign borrow[1] = G[1] | (P[1] & borrow[0]);
    assign borrow[2] = G[2] | (P[2] & borrow[1]);
    assign borrow[3] = G[3] | (P[3] & borrow[2]);
    
    // 并行前缀减法实现: count - 1
    assign count_minus_one = count ^ {borrow[2:0], 1'b1} ^ {3'b0, 1'b1};
    
    // 输入重定时 - 将寄存器移动到输入侧
    always @(posedge clk) begin
        parallel_in_reg <= parallel_in;
        load_reg <= load;
    end
    
    // 主逻辑 - 使用重定时后的信号
    always @(posedge clk) begin
        if (load_reg) begin
            buffer <= parallel_in_reg;
            count <= WIDTH-1;
        end else if (count > 0) begin
            serial_out <= buffer[count];
            count <= count_minus_one;
        end
    end
endmodule