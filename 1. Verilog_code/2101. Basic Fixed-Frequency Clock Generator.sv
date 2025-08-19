module basic_clock_gen(
    output reg clk_out,
    input wire rst_n
);
    parameter HALF_PERIOD = 5;  // Half period in time units
    
    initial clk_out = 0;
    
    always begin
        #HALF_PERIOD clk_out = ~clk_out;
    end
    
    // Reset handling
    always @(negedge rst_n) begin
        if (!rst_n) clk_out <= 0;
    end
endmodule