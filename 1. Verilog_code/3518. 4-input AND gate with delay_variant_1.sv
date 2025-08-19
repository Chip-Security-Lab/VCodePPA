//SystemVerilog
//IEEE 1364-2005 Verilog standard
`timescale 1ns/1ps
module divider_newton_raphson (
    input wire clk,         // Clock signal
    input wire reset_n,     // Active low reset
    input wire start,       // Start division operation
    input wire [7:0] dividend,  // 8-bit dividend (numerator)
    input wire [7:0] divisor,   // 8-bit divisor (denominator)
    output reg [7:0] quotient,  // 8-bit quotient result
    output reg [7:0] remainder, // 8-bit remainder result
    output reg done          // Division operation complete
);
    // States for the division FSM
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam COMPLETE = 2'b10;
    
    // Registers for Newton-Raphson iteration
    reg [1:0] state, next_state;
    reg [7:0] x, divisor_reg, dividend_reg;
    reg [15:0] temp_product;
    reg [3:0] iteration_count;
    reg [7:0] one_over_d_approx; // Approximate 1/divisor
    
    // Constants for the fixed-point representation
    localparam FIXED_POINT_WIDTH = 8;
    localparam MAX_ITERATIONS = 4;
    
    // Update state
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic and calculations
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            next_state <= IDLE;
            done <= 1'b0;
            quotient <= 8'b0;
            remainder <= 8'b0;
            iteration_count <= 4'b0;
            one_over_d_approx <= 8'b0;
            divisor_reg <= 8'b0;
            dividend_reg <= 8'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        if (divisor == 8'b0) begin
                            // Division by zero
                            quotient <= 8'hFF; // Set to all 1's to indicate error
                            remainder <= 8'hFF;
                            done <= 1'b1;
                            next_state <= COMPLETE;
                        end else begin
                            // Initialize Newton-Raphson iteration
                            divisor_reg <= divisor;
                            dividend_reg <= dividend;
                            
                            // Initial approximation for 1/divisor
                            // Using simple lookup for better convergence
                            if (divisor[7:4] == 4'b0000) begin
                                one_over_d_approx <= 8'hFF; // For small divisors
                            end else if (divisor[7:6] == 2'b00) begin
                                one_over_d_approx <= 8'h55; // ~0.33 in fixed point
                            end else if (divisor[7] == 1'b0) begin
                                one_over_d_approx <= 8'h20; // ~0.125 in fixed point
                            end else begin
                                one_over_d_approx <= 8'h10; // ~0.0625 in fixed point
                            end
                            
                            iteration_count <= 4'b0;
                            done <= 1'b0;
                            next_state <= CALC;
                        end
                    end else begin
                        done <= 1'b0;
                        next_state <= IDLE;
                    end
                end
                
                CALC: begin
                    if (iteration_count < MAX_ITERATIONS) begin
                        // Newton-Raphson iteration: x_new = x * (2 - d * x)
                        // Where x is an approximation of 1/d
                        
                        // Calculate d * x (fixed-point multiplication)
                        temp_product <= divisor_reg * one_over_d_approx;
                        
                        // Calculate 2 - d * x (fixed-point subtraction)
                        // 2.0 in our 8-bit fixed point is 256 (8'h100 >> 1 = 8'h80)
                        if (temp_product[15:8] > 8'h80) begin
                            x <= 8'h00; // Avoid underflow
                        end else begin
                            x <= 8'h80 - temp_product[15:8];
                        end
                        
                        // Update approximation: x_new = x * (2 - d * x)
                        one_over_d_approx <= (one_over_d_approx * x) >> 7;
                        
                        iteration_count <= iteration_count + 4'b1;
                        next_state <= CALC;
                    end else begin
                        // Compute final result: quotient = dividend * (1/divisor)
                        temp_product <= dividend_reg * one_over_d_approx;
                        quotient <= temp_product >> 8;
                        
                        // Calculate remainder = dividend - quotient * divisor
                        remainder <= dividend_reg - ((temp_product >> 8) * divisor_reg);
                        
                        done <= 1'b1;
                        next_state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    // Wait for start to be deasserted before going back to IDLE
                    if (!start) begin
                        next_state <= IDLE;
                        done <= 1'b0;
                    end else begin
                        next_state <= COMPLETE;
                    end
                end
                
                default: begin
                    next_state <= IDLE;
                end
            endcase
        end
    end
    
endmodule