//SystemVerilog
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: int_ctrl_dist_arb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Pipelined priority arbitration with configurable width
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module int_ctrl_dist_arb #(
    parameter N = 4           // Number of request inputs
)(
    input wire clk,           // System clock
    input wire rst_n,         // Active low reset
    input wire [N-1:0] req,   // Request signals
    output reg [N-1:0] grant  // Grant signals
);

    // Internal pipeline registers
    reg [N-1:0] req_reg;      // Stage 1: Request register
    
    // Pipeline registers for subtraction operation
    reg [N-1:0] req_reg_p1;   // Additional pipeline register for request
    reg [N/2-1:0] req_lower_half;  // Lower half of request for staged subtraction
    reg [N/2-1:0] req_upper_half;  // Upper half of request for staged subtraction
    reg has_borrow;           // Borrow flag between lower and upper half
    reg [N/2-1:0] req_m1_lower;    // Lower half of req-1
    reg [N/2-1:0] req_m1_upper;    // Upper half of req-1
    
    reg [N-1:0] req_m1;       // Combined req-1 value
    reg [N-1:0] inverted;     // ~(req-1) value
    reg [N-1:0] req_reg_final; // Final req value aligned with inverted
    wire [N-1:0] grant_comb;  // Combinational grant signal

    // Stage 1: Register input requests
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            req_reg <= {N{1'b0}};
        else
            req_reg <= req;
    end

    // Stage 1.5: Additional pipeline stage for request and split into halves
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_reg_p1 <= {N{1'b0}};
            req_lower_half <= {(N/2){1'b0}};
            req_upper_half <= {(N/2){1'b0}};
        end 
        else begin
            req_reg_p1 <= req_reg;
            req_lower_half <= req_reg[N/2-1:0];
            req_upper_half <= req_reg[N-1:N/2];
        end
    end

    // Stage 2: Calculate req-1 in two stages (lower half first)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_m1_lower <= {(N/2){1'b0}};
            has_borrow <= 1'b0;
        end 
        else
            {has_borrow, req_m1_lower} <= req_lower_half - 1'b1;
    end

    // Stage 2.5: Calculate upper half of req-1 considering borrow
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_m1_upper <= {(N/2){1'b0}};
            req_m1 <= {N{1'b0}};
        end 
        else begin
            req_m1_upper <= req_upper_half - has_borrow;
            req_m1 <= {req_m1_upper, req_m1_lower}; // Combine results
        end
    end

    // Stage 3: Calculate ~(req-1) and align req_reg
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inverted <= {N{1'b0}};
            req_reg_final <= {N{1'b0}};
        end 
        else begin
            inverted <= ~req_m1;
            req_reg_final <= req_reg_p1; // Align with inverted
        end
    end

    // Combinational logic to calculate grant
    assign grant_comb = req_reg_final & inverted;

    // Final output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            grant <= {N{1'b0}};
        else
            grant <= grant_comb;
    end

endmodule