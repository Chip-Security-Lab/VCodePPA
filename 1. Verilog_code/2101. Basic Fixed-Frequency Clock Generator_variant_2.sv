//SystemVerilog
`timescale 1ns/1ps
module basic_clock_gen(
    output reg clk_out,
    input wire rst_n
);
    parameter HALF_PERIOD = 5;  // Half period in time units

    reg clk_toggle;

    initial begin
        clk_toggle = 1'b0;
        clk_out = 1'b0;
    end

    always begin
        #(HALF_PERIOD)
        if (rst_n)
            clk_toggle = ~clk_toggle;
        else
            clk_toggle = 1'b0;
    end

    always @(*) begin
        clk_out = clk_toggle & rst_n;
    end

endmodule