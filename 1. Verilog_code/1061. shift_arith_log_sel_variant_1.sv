//SystemVerilog
module shift_arith_log_sel #(
    parameter WIDTH = 8
)(
    input mode, // 0-logical, 1-arithmetic
    input [WIDTH-1:0] din,
    input [2:0] shift,
    output reg [WIDTH-1:0] dout
);

    integer bit_idx;
    reg [WIDTH-1:0] shifted_value;
    reg sign_extension;
    reg [2:0] shift_amount;

    always @* begin
        shift_amount = shift[2:0];
        sign_extension = din[WIDTH-1];
        if (mode == 1'b0) begin
            // Logical right shift
            shifted_value = din >> shift_amount;
        end else begin
            // Arithmetic right shift with optimized comparison logic
            for (bit_idx = 0; bit_idx < WIDTH; bit_idx = bit_idx + 1) begin
                if (bit_idx + shift_amount < WIDTH)
                    shifted_value[bit_idx] = din[bit_idx + shift_amount];
                else
                    shifted_value[bit_idx] = sign_extension;
            end
        end
        dout = shifted_value;
    end

endmodule