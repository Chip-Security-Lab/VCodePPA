//SystemVerilog
module RangeDetector_MultiMode #(
    parameter WIDTH = 8
)(
    input clk, rst_n,
    input [1:0] mode,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag
);
    wire [WIDTH-1:0] diff;
    wire borrow;
    
    // 使用优化的先行借位减法器计算data_in - threshold
    OptimizedSubtractor #(
        .WIDTH(WIDTH)
    ) sub_inst (
        .a(data_in),
        .b(threshold),
        .diff(diff),
        .borrow_out(borrow)
    );
    
    // 优化模式判断逻辑
    always @(posedge clk) begin
        case(mode)
            2'b00: flag <= ~borrow;          // data_in >= threshold
            2'b01: flag <= borrow | ~|diff;  // data_in <= threshold，使用归约或非运算符
            2'b10: flag <= |diff;            // data_in != threshold，使用归约或运算符
            2'b11: flag <= ~|diff;           // data_in == threshold，使用归约或非运算符
        endcase
    end
endmodule

module OptimizedSubtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    wire [WIDTH:0] borrow;
    
    assign borrow[0] = 1'b0;
    
    // 优化的借位和差值计算
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: bit_calc
            // 优化的借位逻辑：使用简化的布尔表达式
            assign borrow[i+1] = (b[i] & ~a[i]) | (b[i] & borrow[i]) | (~a[i] & borrow[i]);
            // 直接计算差值
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
        end
    endgenerate
    
    assign borrow_out = borrow[WIDTH];
endmodule