module bidir_arith_logical_shifter (
    input  [31:0] src,
    input  [4:0]  amount,
    input         direction,  // 0=left, 1=right
    input         arith_mode, // 0=logical, 1=arithmetic
    output [31:0] result
);
    // Combinational logic for all shift types
    reg [31:0] shift_result;
    
    always @(*) begin
        if (!direction)
            // Left shift (always logical)
            shift_result = src << amount;
        else if (!arith_mode)
            // Right logical shift
            shift_result = src >> amount;
        else
            // Right arithmetic shift (sign-extended)
            shift_result = $signed(src) >>> amount;
    end
    
    assign result = shift_result;
endmodule