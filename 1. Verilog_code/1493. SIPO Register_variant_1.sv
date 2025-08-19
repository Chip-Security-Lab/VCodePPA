//SystemVerilog
module sipo_register #(
    parameter N = 16
)(
    input  wire        clock,
    input  wire        reset,
    input  wire        enable,
    input  wire        serial_in,
    input  wire [7:0]  a_in,       // 8位减法操作数A
    input  wire [7:0]  b_in,       // 8位减法操作数B
    output wire [N-1:0] parallel_out,
    output wire [7:0]  diff_out    // 减法结果输出
);
    // 主移位寄存器
    reg [N-1:0] data_reg;
    
    // 优化的移位操作
    always @(posedge clock) begin
        if (reset) begin
            data_reg <= {N{1'b0}};
        end
        else if (enable) begin
            // 使用连接操作符优化移位操作，更清晰地表达移位行为
            data_reg <= {data_reg[N-2:0], serial_in};
        end
    end
    
    // 直接输出赋值，避免不必要的中间信号
    assign parallel_out = data_reg;
    
    // 8位先行借位减法器实现
    wire [8:0] borrow; // 额外一位用于最高位借位
    wire [7:0] diff;
    
    // 初始借位为0
    assign borrow[0] = 1'b0;
    
    // 生成每一位的借位和差值
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_sub
            // 先行借位算法:
            // 当前位借位产生条件: !a_in[i] & b_in[i]
            // 当前位借位传递条件: (a_in[i] == b_in[i]) & borrow[i]
            assign borrow[i+1] = (!a_in[i] & b_in[i]) | ((a_in[i] == b_in[i]) & borrow[i]);
            // 差值计算
            assign diff[i] = a_in[i] ^ b_in[i] ^ borrow[i];
        end
    endgenerate
    
    // 差值输出
    assign diff_out = diff;
    
endmodule