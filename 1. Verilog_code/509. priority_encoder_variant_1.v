module priority_encoder(
    input [7:0] req,
    input [7:0] data_in,
    output reg [2:0] code,
    output reg [15:0] mult_result
);

    // Internal signals for signed multiplication
    reg [7:0] abs_a, abs_b;
    reg sign_a, sign_b;
    reg [15:0] unsigned_mult;
    reg [15:0] sign_corrected_result;

    // Priority encoder logic
    always @(*) begin
        casex(req)
            8'b1xxxxxxx: code = 3'b111;
            8'b01xxxxxx: code = 3'b110;
            8'b001xxxxx: code = 3'b101;
            8'b0001xxxx: code = 3'b100;
            default:     code = 3'b000;
        endcase
    end

    // Sign extraction
    always @(*) begin
        sign_a = data_in[7];
        sign_b = req[0];
    end

    // Absolute value calculation
    always @(*) begin
        abs_a = sign_a ? ~data_in + 1'b1 : data_in;
        abs_b = sign_b ? ~req[0] + 1'b1 : req[0];
    end

    // Unsigned multiplication
    always @(*) begin
        unsigned_mult = abs_a * abs_b;
    end

    // Sign correction
    always @(*) begin
        sign_corrected_result = (sign_a ^ sign_b) ? ~unsigned_mult + 1'b1 : unsigned_mult;
    end

    // Final result assignment
    always @(*) begin
        mult_result = sign_corrected_result;
    end

endmodule