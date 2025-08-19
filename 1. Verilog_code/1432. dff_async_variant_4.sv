//SystemVerilog
module dff_async (
    input wire clk,    // Clock input
    input wire arst_n, // Active-low asynchronous reset
    input wire d,      // Data input
    output reg q       // Output register
);

    // Pre-registered data signal to optimize timing path
    reg d_pre_reg;
    
    // First stage: pre-register the input data
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            d_pre_reg <= 1'b0;
        else
            d_pre_reg <= d;
    end
    
    // Second stage: final output register
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            q <= 1'b0;
        else
            q <= d_pre_reg;
    end

endmodule