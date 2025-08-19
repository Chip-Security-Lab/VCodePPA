//SystemVerilog
module rng_poly_8(
    input                 clk,
    input                 en,
    output reg [11:0]     r_out
);
    reg [11:0] lfsr_reg;
    reg [11:0] lfsr_buf;

    wire feedback;
    assign feedback = ^(lfsr_buf & 12'b100010010001); // taps at [11],[9],[6],[3]

    always @(posedge clk) begin
        lfsr_buf <= lfsr_reg;
        if (en) begin
            lfsr_reg <= {lfsr_buf[10:0], feedback};
        end
        r_out <= lfsr_buf;
    end

    initial begin
        lfsr_reg = 12'hABC;
        lfsr_buf = 12'hABC;
        r_out = 12'hABC;
    end
endmodule