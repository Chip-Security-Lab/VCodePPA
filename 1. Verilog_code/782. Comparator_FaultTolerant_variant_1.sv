//SystemVerilog
module Comparator_FaultTolerant #(
    parameter WIDTH = 8,
    parameter PARITY_TYPE = 0
)(
    input  [WIDTH:0]   data_a,
    input  [WIDTH:0]   data_b,
    output             safe_equal
);

    // 校验位验证模块
    wire parity_ok_a, parity_ok_b;
    ParityChecker #(
        .WIDTH(WIDTH),
        .PARITY_TYPE(PARITY_TYPE)
    ) parity_checker_a (
        .data(data_a),
        .parity_ok(parity_ok_a)
    );

    ParityChecker #(
        .WIDTH(WIDTH),
        .PARITY_TYPE(PARITY_TYPE)
    ) parity_checker_b (
        .data(data_b),
        .parity_ok(parity_ok_b)
    );

    // 比较器模块
    wire data_equal;
    Comparator #(
        .WIDTH(WIDTH)
    ) comparator (
        .data_a(data_a[WIDTH-1:0]),
        .data_b(data_b[WIDTH-1:0]),
        .equal(data_equal)
    );

    // 最终结果组合
    assign safe_equal = parity_ok_a & parity_ok_b & data_equal;

endmodule

module ParityChecker #(
    parameter WIDTH = 8,
    parameter PARITY_TYPE = 0
)(
    input [WIDTH:0] data,
    output parity_ok
);
    wire parity_bit = data[WIDTH];
    wire [WIDTH-1:0] data_bits = data[WIDTH-1:0];
    
    assign parity_ok = (^data_bits) == (PARITY_TYPE ? ~parity_bit : parity_bit);
endmodule

module Comparator #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] data_a,
    input [WIDTH-1:0] data_b,
    output equal
);
    wire [WIDTH-1:0] diff;
    wire borrow_out;
    
    SubtractionLUT #(
        .WIDTH(WIDTH)
    ) subtractor (
        .a(data_a),
        .b(data_b),
        .diff(diff),
        .borrow_out(borrow_out)
    );
    
    assign equal = (diff == {(WIDTH){1'b0}});
endmodule

module SubtractionLUT #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    wire [WIDTH:0] borrow;
    reg [WIDTH-1:0] result;
    
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: sub_lut
            always @(*) begin
                case ({a[i], b[i], borrow[i]})
                    3'b000: result[i] = 1'b0;
                    3'b001: result[i] = 1'b1;
                    3'b010: result[i] = 1'b1;
                    3'b011: result[i] = 1'b0;
                    3'b100: result[i] = 1'b1;
                    3'b101: result[i] = 1'b0;
                    3'b110: result[i] = 1'b0;
                    3'b111: result[i] = 1'b1;
                    default: result[i] = 1'bx;
                endcase
            end
            
            assign borrow[i+1] = (b[i] & ~a[i]) | (borrow[i] & (b[i] | ~a[i]));
        end
    endgenerate
    
    assign diff = result;
    assign borrow_out = borrow[WIDTH];
endmodule