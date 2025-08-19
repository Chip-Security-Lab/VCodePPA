//SystemVerilog
module debug_crc8(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data,
    input wire valid,
    output reg [7:0] crc_out,
    output reg error_detected,
    output reg [3:0] bit_position,
    output reg processing_active
);
    parameter [7:0] POLY = 8'h07;
    
    // Pre-calculate the CRC next value to reduce critical path
    wire msb_xor_data = crc_out[7] ^ data[0];
    wire [7:0] poly_select = msb_xor_data ? POLY : 8'h0;
    
    // Carry Look-ahead Adder implementation for {crc_out[6:0], 1'b0} ^ poly_select
    wire [7:0] crc_shifted = {crc_out[6:0], 1'b0};
    
    // Generate and Propagate signals
    wire [7:0] g = crc_shifted & poly_select;
    wire [7:0] p = crc_shifted | poly_select;
    
    // Carry generation
    wire [8:0] c;
    assign c[0] = 1'b0; // Initial carry
    
    // Compute carries using carry look-ahead logic
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    
    // For higher bits, we use a simplified approach to avoid excessive logic
    assign c[5] = g[4] | (p[4] & c[4]);
    assign c[6] = g[5] | (p[5] & c[5]);
    assign c[7] = g[6] | (p[6] & c[6]);
    assign c[8] = g[7] | (p[7] & c[7]);
    
    // Sum computation using carry look-ahead
    wire [7:0] next_crc = crc_shifted ^ poly_select ^ c[7:0];
    
    // Pre-calculate error condition
    wire is_last_bit = (bit_position == 4'd7);
    wire has_error = (crc_out != 8'h00) && is_last_bit;
    
    // Register update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out <= 8'h00;
            error_detected <= 1'b0;
            bit_position <= 4'd0;
            processing_active <= 1'b0;
        end else if (valid) begin
            processing_active <= 1'b1;
            crc_out <= next_crc;
            bit_position <= bit_position + 1;
            error_detected <= has_error;
        end else begin
            processing_active <= 1'b0;
        end
    end
endmodule