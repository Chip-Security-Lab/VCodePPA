//SystemVerilog
//-----------------------------------------------------------------------------
// Filename: multiplier_top.v
// Description: Top level module with 8-bit Baugh-Wooley multiplier architecture
//-----------------------------------------------------------------------------

`timescale 1ns / 1ps
`default_nettype none

module multiplier_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output wire [15:0] product
);
    
    // Internal signals
    wire        control_signal;
    wire [15:0] mult_result;
    
    // Control unit handles enable logic
    control_unit u_control (
        .clk          (clk),
        .rst_n        (rst_n),
        .enable_in    (enable),
        .control_out  (control_signal)
    );
    
    // Baugh-Wooley multiplier for data processing
    baugh_wooley_multiplier u_bw_mult (
        .clk         (clk),
        .rst_n       (rst_n),
        .a           (a),
        .b           (b),
        .mult_result (mult_result)
    );
    
    // Output register unit
    output_unit u_output (
        .clk         (clk),
        .rst_n       (rst_n),
        .control_in  (control_signal),
        .data_in     (mult_result),
        .product_out (product)
    );
    
endmodule

//-----------------------------------------------------------------------------
// Control unit module - Processes enable signal
//-----------------------------------------------------------------------------
module control_unit (
    input  wire clk,
    input  wire rst_n,
    input  wire enable_in,
    output reg  control_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_out <= 1'b0;
        end else begin
            control_out <= enable_in;
        end
    end
    
endmodule

//-----------------------------------------------------------------------------
// Baugh-Wooley 8-bit Multiplier Implementation
//-----------------------------------------------------------------------------
module baugh_wooley_multiplier (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [7:0]   a,
    input  wire [7:0]   b,
    output reg  [15:0]  mult_result
);
    
    // Partial products
    reg [7:0] pp [7:0];
    reg [15:0] sum;
    integer i, j;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                pp[i] <= 8'b0;
            end
            sum <= 16'b0;
            mult_result <= 16'b0;
        end else begin
            // Generate partial products using Baugh-Wooley algorithm
            for (i = 0; i < 7; i = i + 1) begin
                for (j = 0; j < 7; j = j + 1) begin
                    pp[i][j] = a[i] & b[j];
                end
                // Special handling for MSB of each partial product row
                pp[i][7] = ~(a[i] & b[7]);
            end
            
            // Last row partial products
            for (j = 0; j < 7; j = j + 1) begin
                pp[7][j] = ~(a[7] & b[j]);
            end
            pp[7][7] = a[7] & b[7];
            
            // Sum partial products (simple version for clarity)
            sum = 16'b0;
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    sum[i+j] = sum[i+j] ^ pp[i][j];
                    if (i+j+1 < 16) begin
                        sum[i+j+1] = sum[i+j+1] ^ (pp[i][j] & sum[i+j]);
                    end
                end
            end
            
            // Add 1 to two's complement result
            sum = sum + 16'b1;
            
            // Register output
            mult_result <= sum;
        end
    end
    
endmodule

//-----------------------------------------------------------------------------
// Output unit module - Registers multiplication result
//-----------------------------------------------------------------------------
module output_unit (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         control_in,
    input  wire [15:0]  data_in,
    output reg  [15:0]  product_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_out <= 16'b0;
        end else if (control_in) begin
            product_out <= data_in;
        end
    end
    
endmodule

`default_nettype wire