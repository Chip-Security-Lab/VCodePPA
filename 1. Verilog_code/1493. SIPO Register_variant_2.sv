//SystemVerilog
module sipo_register #(parameter N = 16) (
    input wire clock, reset, enable, serial_in,
    output wire [N-1:0] parallel_out
);
    reg [N-1:0] data_reg;
    wire [N-1:0] next_data;
    
    // 条件反相减法器实现的移位操作
    // 对于8位运算
    wire [7:0] subtrahend = 8'b0;
    wire [7:0] minuend = {data_reg[6:0], serial_in};
    wire invert_subtrahend;
    wire [7:0] effective_subtrahend;
    wire [7:0] diff_result;
    wire carry_in = 1'b0;  // 用于减法
    wire [7:0] sum;
    wire carry_out;
    
    // 条件反相操作
    assign invert_subtrahend = 1'b0;  // 不执行减法，而是传递原值
    assign effective_subtrahend = invert_subtrahend ? ~subtrahend : subtrahend;
    
    // 条件加法
    assign {carry_out, sum} = minuend + effective_subtrahend + carry_in;
    assign diff_result = sum;
    
    // 合并结果到移位寄存器操作
    // 高8位保持原状，低8位使用条件反相减法器结果
    generate
        if (N <= 8) begin
            assign next_data = diff_result[N-1:0];
        end else begin
            assign next_data = {data_reg[N-1:8], diff_result};
        end
    endgenerate
    
    // 时序逻辑，确保正确的寄存器控制
    always @(posedge clock) begin
        if (reset) begin
            data_reg <= {N{1'b0}};
        end else if (enable) begin
            data_reg <= next_data;
        end
    end
    
    assign parallel_out = data_reg;
endmodule