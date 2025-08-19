//SystemVerilog
module partial_pattern_matcher #(parameter W = 16, SLICE = 8) (
    input [W-1:0] data, pattern,
    input match_upper,
    output match_result
);
    // 使用借位减法器实现比较
    wire [SLICE-1:0] upper_diff, lower_diff;
    wire upper_borrow, lower_borrow;
    
    // 高位比较
    subtractor #(.WIDTH(SLICE)) upper_sub (
        .a(data[W-1:W-SLICE]),
        .b(pattern[W-1:W-SLICE]),
        .borrow_in(1'b0),
        .diff(upper_diff),
        .borrow_out(upper_borrow)
    );
    
    // 低位比较
    subtractor #(.WIDTH(SLICE)) lower_sub (
        .a(data[SLICE-1:0]),
        .b(pattern[SLICE-1:0]),
        .borrow_in(1'b0),
        .diff(lower_diff),
        .borrow_out(lower_borrow)
    );
    
    // 比较结果判断
    wire upper_match = ~(|upper_diff) & ~upper_borrow;
    wire lower_match = ~(|lower_diff) & ~lower_borrow;
    
    assign match_result = match_upper ? upper_match : lower_match;
endmodule

module subtractor #(parameter WIDTH = 8) (
    input [WIDTH-1:0] a, b,
    input borrow_in,
    output [WIDTH-1:0] diff,
    output borrow_out
);
    wire [WIDTH:0] borrow;
    assign borrow[0] = borrow_in;
    
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : sub_stage
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
            assign borrow[i+1] = (~a[i] & b[i]) | ((~a[i] | b[i]) & borrow[i]);
        end
    endgenerate
    
    assign borrow_out = borrow[WIDTH];
endmodule