//SystemVerilog
module config_poly_lfsr (
    input  wire        clock,
    input  wire        reset,
    input  wire [15:0] polynomial,
    output wire [15:0] rand_out
);

    reg  [15:0] lfsr_reg;
    wire        feedback_bit;

    // Optimized feedback calculation using reduction XOR and bitwise AND
    assign feedback_bit = ^(lfsr_reg & polynomial);

    always @(posedge clock) begin
        if (reset) begin
            lfsr_reg <= 16'h1;
        end else begin
            lfsr_reg <= {lfsr_reg[14:0], feedback_bit};
        end
    end

    assign rand_out = lfsr_reg;

endmodule