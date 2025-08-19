module BCDSub(
    input [7:0] bcd_a,
    input [7:0] bcd_b,
    output reg [7:0] bcd_res
);

    reg [7:0] temp_diff;
    reg borrow;

    // Calculate raw difference
    always @(*) begin
        temp_diff = bcd_a - bcd_b;
    end

    // Determine borrow condition
    always @(*) begin
        borrow = (bcd_a < bcd_b);
    end

    // Apply BCD correction based on borrow
    always @(*) begin
        bcd_res = borrow ? (temp_diff - 6'h6) : temp_diff;
    end

endmodule