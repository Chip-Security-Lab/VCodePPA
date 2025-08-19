//SystemVerilog
module param_clock_divider #(
    parameter DIVISOR = 4,
    parameter WIDTH = $clog2(DIVISOR)
)(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);

    reg [WIDTH-1:0] counter_reg;
    reg [WIDTH-1:0] counter_next;
    reg clk_out_next;

    ////////////////////////////////////////////////////////////////////////////////
    // Counter Next-State Calculation (Combinational)
    ////////////////////////////////////////////////////////////////////////////////
    // Purpose: Calculate the next value of the counter based on the current state.
    always @* begin
        if (counter_reg == (DIVISOR - 1))
            counter_next = {WIDTH{1'b0}};
        else
            counter_next = counter_reg + 1'b1;
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Clock Output Next-State Calculation (Combinational)
    ////////////////////////////////////////////////////////////////////////////////
    // Purpose: Determine the next state of clk_out based on the counter.
    always @* begin
        if (counter_reg == (DIVISOR - 1))
            clk_out_next = ~clk_out;
        else
            clk_out_next = clk_out;
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Counter Register Update (Sequential)
    ////////////////////////////////////////////////////////////////////////////////
    // Purpose: Register the counter value on the rising edge of clk_in.
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            counter_reg <= {WIDTH{1'b0}};
        else
            counter_reg <= counter_next;
    end

    ////////////////////////////////////////////////////////////////////////////////
    // Clock Output Update (Sequential)
    ////////////////////////////////////////////////////////////////////////////////
    // Purpose: Register the clk_out value on the rising edge of clk_in.
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            clk_out <= 1'b0;
        else
            clk_out <= clk_out_next;
    end

endmodule