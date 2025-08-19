//SystemVerilog
module HysteresisFilter #(parameter W=8, HYST=4) (
    input clk, 
    input [W-1:0] din,
    output reg out
);
    reg [W-1:0] prev;
    wire [W-1:0] upper_threshold, lower_threshold;
    wire upper_compare, lower_compare;
    
    // 借位减法器实现上阈值比较
    BorrowSubtractor #(.WIDTH(W)) upper_sub (
        .a(din),
        .b(prev + HYST),
        .result(),
        .borrow_out(upper_compare)
    );
    
    // 借位减法器实现下阈值比较
    BorrowSubtractor #(.WIDTH(W)) lower_sub (
        .a(prev),
        .b(din + HYST),
        .result(),
        .borrow_out(lower_compare)
    );
    
    always @(posedge clk) begin
        if(!upper_compare) out <= 1;        // din >= prev + HYST
        else if(!lower_compare) out <= 0;   // prev >= din + HYST (等价于 din <= prev - HYST)
        prev <= din;
    end
endmodule

module BorrowSubtractor #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result,
    output borrow_out
);
    wire [WIDTH:0] borrow;
    assign borrow[0] = 0;
    
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: sub_bit
            assign result[i] = a[i] ^ b[i] ^ borrow[i];
            assign borrow[i+1] = (~a[i] & b[i]) | (~a[i] & borrow[i]) | (b[i] & borrow[i]);
        end
    endgenerate
    
    assign borrow_out = borrow[WIDTH];
endmodule