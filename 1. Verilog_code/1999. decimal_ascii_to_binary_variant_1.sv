//SystemVerilog
module decimal_ascii_to_binary #(
    parameter MAX_DIGITS = 3
)(
    input wire [8*MAX_DIGITS-1:0] ascii_in,
    output reg [$clog2(10**MAX_DIGITS)-1:0] binary_out,
    output reg valid
);
    integer idx;
    reg [7:0] current_ascii;
    reg [3:0] digit_value;

    always @* begin
        binary_out = 0;
        valid = 1;
        for (idx = 0; idx < MAX_DIGITS; idx = idx + 1) begin
            current_ascii = ascii_in[8*idx +: 8];
            case (current_ascii)
                8'h30: digit_value = 4'd0;
                8'h31: digit_value = 4'd1;
                8'h32: digit_value = 4'd2;
                8'h33: digit_value = 4'd3;
                8'h34: digit_value = 4'd4;
                8'h35: digit_value = 4'd5;
                8'h36: digit_value = 4'd6;
                8'h37: digit_value = 4'd7;
                8'h38: digit_value = 4'd8;
                8'h39: digit_value = 4'd9;
                8'h20: digit_value = 4'd15; // Space character
                default: digit_value = 4'd14; // Invalid character
            endcase

            case (digit_value)
                4'd0, 4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 4'd7, 4'd8, 4'd9: begin
                    binary_out = binary_out * 10 + digit_value;
                end
                4'd15: begin
                    // Space character, do nothing
                end
                default: begin
                    valid = 0;
                end
            endcase
        end
    end
endmodule