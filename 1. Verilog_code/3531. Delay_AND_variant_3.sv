//SystemVerilog
`timescale 1ns/1ns

module Delay_AND (
    input  wire clk,        // Clock input
    input  wire rst_n,      // Reset signal (active low)
    input  wire a,          // Input signal A
    input  wire b,          // Input signal B
    output wire z           // Delayed output signal
);

    // Stage 1: Input Registration
    reg a_reg, b_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 1'b0;
            b_reg <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end
    
    // Stage 2: Logic Operation
    reg and_result;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 1'b0;
        end else begin
            and_result <= a_reg & b_reg;
        end
    end
    
    // Stage 3: Delay Pipeline (3 clock cycles to approximate the 3ns delay)
    reg [2:0] delay_pipe;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_pipe <= 3'b000;
        end else begin
            delay_pipe <= {delay_pipe[1:0], and_result};
        end
    end
    
    // Output assignment
    assign z = delay_pipe[2];

endmodule