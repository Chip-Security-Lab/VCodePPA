//SystemVerilog
/* IEEE 1364-2005 Verilog标准 */
module async_rst_low_comb #(parameter WIDTH=16)(
    input wire rst_n,
    input wire [WIDTH-1:0] in_data,
    output reg [WIDTH-1:0] out_data
);
    // 使用条件反相减法器算法实现8位减法器
    
    // 内部信号定义
    reg [7:0] a_temp;
    wire [7:0] a, b;
    wire [7:0] b_complement;
    wire [7:0] diff;
    wire [8:0] carry;  // 增加一位用于最终进位
    
    // 输入处理
    always @(*) begin
        if (rst_n) begin
            a_temp = in_data[7:0];
        end else begin
            a_temp = 8'b0;
        end
    end
    
    assign a = a_temp;
    assign b = 8'b0; // 实际上是0
    
    // 条件反相减法实现
    // 1. 对减数取反
    assign b_complement = ~b;
    
    // 2. 执行加法：A + (~B) + 1
    assign carry[0] = 1'b1; // 初始进位为1，相当于补码操作的+1
    
    // 3. 位级进位计算
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : carry_gen
            assign carry[i+1] = (a[i] & b_complement[i]) | ((a[i] | b_complement[i]) & carry[i]);
        end
    endgenerate
    
    // 4. 计算结果
    assign diff = a ^ b_complement ^ carry[7:0];
    
    // 输出映射
    always @(*) begin
        if (rst_n) begin
            if (WIDTH > 8) begin
                out_data = {in_data[WIDTH-1:8], diff};
            end else begin
                out_data = diff;
            end
        end else begin
            out_data = {WIDTH{1'b0}};
        end
    end

endmodule