//SystemVerilog
module basic_clock_gen(
    output reg clk_out,
    input wire rst_n
);
    parameter HALF_PERIOD = 5;  // Half period in time units

    reg internal_clk;

    initial begin
        clk_out = 1'b0;
        internal_clk = 1'b0;
    end

    always begin
        #(HALF_PERIOD) internal_clk = ~internal_clk;
    end

    always @(*) begin
        clk_out = internal_clk & rst_n;
    end

endmodule