//SystemVerilog
module MIPI_CRC_Checker #(
    parameter POLYNOMIAL = 32'h04C11DB7,
    parameter SYNC_MODE = 1
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg crc_error,
    output reg [31:0] calc_crc
);
    // Internal signals
    wire [31:0] next_crc;
    
    // Instantiate the Karatsuba multiplier module
    Karatsuba_Multiplier karatsuba_mult_inst (
        .a({24'b0, data_in}),
        .b(POLYNOMIAL),
        .product(poly_mult)
    );
    
    // Instantiate the CRC calculator module
    CRC_Calculator #(
        .POLYNOMIAL(POLYNOMIAL)
    ) crc_calc_inst (
        .current_crc(calc_crc),
        .data_in(data_in),
        .data_valid(data_valid),
        .poly_mult(poly_mult),
        .next_crc(next_crc)
    );
    
    // Instantiate the appropriate CRC register module based on SYNC_MODE
    generate
        if (SYNC_MODE == 1) begin: sync_crc_reg
            Synchronous_CRC_Register crc_reg_inst (
                .clk(clk),
                .rst_n(rst_n),
                .next_crc(next_crc),
                .data_valid(data_valid),
                .calc_crc(calc_crc),
                .crc_error(crc_error)
            );
        end else begin: async_crc_reg
            Asynchronous_CRC_Register crc_reg_inst (
                .next_crc(next_crc),
                .data_valid(data_valid),
                .calc_crc(calc_crc),
                .crc_error(crc_error)
            );
        end
    endgenerate
    
    // Wire declaration for the multiplier output
    wire [31:0] poly_mult;
    
endmodule

//-------------------------------------------------------
// Karatsuba Multiplier Module
//-------------------------------------------------------
module Karatsuba_Multiplier (
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] product
);
    // Internal signals
    wire [15:0] a_high, a_low, b_high, b_low;
    wire [31:0] z0, z1, z2;
    wire [31:0] sum_a, sum_b, prod_sum;
    
    // Split inputs into high and low parts
    assign a_high = a[31:16];
    assign a_low = a[15:0];
    assign b_high = b[31:16];
    assign b_low = b[15:0];
    
    // Calculate intermediate sums
    assign sum_a = {16'b0, a_high} + {16'b0, a_low};
    assign sum_b = {16'b0, b_high} + {16'b0, b_low};
    
    // Compute partial products
    assign z0 = {16'b0, a_low} * {16'b0, b_low};
    assign z2 = {16'b0, a_high} * {16'b0, b_high};
    assign prod_sum = sum_a * sum_b;
    
    // Calculate z1 term
    assign z1 = prod_sum - z0 - z2;
    
    // Combine results to get final product
    assign product = (z2 << 32) | (z1 << 16) | z0;
    
endmodule

//-------------------------------------------------------
// CRC Calculator Module
//-------------------------------------------------------
module CRC_Calculator #(
    parameter POLYNOMIAL = 32'h04C11DB7
)(
    input wire [31:0] current_crc,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire [31:0] poly_mult,
    output wire [31:0] next_crc
);
    // Calculate next CRC value
    assign next_crc = data_valid ? (current_crc ^ poly_mult) : current_crc;
    
endmodule

//-------------------------------------------------------
// Synchronous CRC Register Module
//-------------------------------------------------------
module Synchronous_CRC_Register (
    input wire clk,
    input wire rst_n,
    input wire [31:0] next_crc,
    input wire data_valid,
    output reg [31:0] calc_crc,
    output reg crc_error
);
    // Sequential logic for synchronous mode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calc_crc <= 32'hFFFFFFFF;
            crc_error <= 0;
        end else if (data_valid) begin
            calc_crc <= next_crc;
            crc_error <= (next_crc != 32'h0);
        end
    end
    
endmodule

//-------------------------------------------------------
// Asynchronous CRC Register Module
//-------------------------------------------------------
module Asynchronous_CRC_Register (
    input wire [31:0] next_crc,
    input wire data_valid,
    output wire [31:0] calc_crc,
    output wire crc_error
);
    // Combinational logic for asynchronous mode
    assign calc_crc = next_crc;
    assign crc_error = (next_crc != 32'h0) && data_valid;
    
endmodule