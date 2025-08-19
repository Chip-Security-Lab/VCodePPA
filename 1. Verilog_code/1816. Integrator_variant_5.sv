//SystemVerilog
module Integrator #(
    parameter W = 8,      // Data width
    parameter MAX = 255   // Maximum accumulation value
)(
    input                  clk,    // System clock
    input                  rst,    // Active high reset
    input      [W-1:0]     din,    // Input data
    output reg [W-1:0]     dout    // Output data
);
    // Pipeline stage registers
    reg [W-1:0]   din_reg;         // Registered input
    reg [W+1:0]   accumulator;     // Extended accumulator for overflow detection
    reg [W+1:0]   acc_result;      // Intermediate accumulation result
    reg           overflow_flag;   // Flag indicating accumulator overflow
    
    // Input registration stage
    always @(posedge clk or posedge rst) begin
        if (rst)
            din_reg <= {W{1'b0}};
        else
            din_reg <= din;
    end
    
    // Accumulation stage
    always @(posedge clk or posedge rst) begin
        if (rst)
            acc_result <= {(W+2){1'b0}};
        else
            acc_result <= accumulator + din_reg;
    end
    
    // Overflow detection stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accumulator <= {(W+2){1'b0}};
            overflow_flag <= 1'b0;
        end
        else begin
            accumulator <= acc_result;
            overflow_flag <= (acc_result > MAX);
        end
    end
    
    // Output stage with saturation logic
    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= {W{1'b0}};
        else
            dout <= overflow_flag ? MAX : accumulator[W-1:0];
    end
    
endmodule