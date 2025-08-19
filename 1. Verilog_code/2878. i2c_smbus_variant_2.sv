//SystemVerilog
`timescale 1ns / 1ps
module i2c_smbus #(
    parameter CRC_ENABLE = 1
)(
    input clk,
    input rst_sync_n,
    inout sda,
    inout scl,
    output reg crc_error,
    input  [7:0] pkt_command,
    output [15:0] pkt_data
);
// Unique feature: SMBus extension + CRC8 verification
reg [7:0] crc_calculator_reg;
wire [7:0] crc_received;
wire sda_in_raw; // Raw SDA input directly from pin
wire scl_in_raw; // Raw SCL input directly from pin
reg sda_in_reg;  // Registered SDA input
reg scl_in_reg;  // Registered SCL input

// SMBus timeout counter with pre-calculated comparison value
reg [31:0] timeout_counter;
wire timeout_detected;
localparam TIMEOUT_THRESHOLD = 32'd34_000_000;

// Registered data output
reg [15:0] pkt_data_reg;
assign pkt_data = pkt_data_reg;

// Direct input connection - removes first pipeline stage to reduce input latency
assign sda_in_raw = sda;
assign scl_in_raw = scl;
assign scl_reg = scl_in_reg;

// Pre-computed timeout detection to reduce critical path
assign timeout_detected = (timeout_counter > TIMEOUT_THRESHOLD);

// CRC received value 
assign crc_received = 8'h00;

// Optimized pipeline - single stage register for input sampling
always @(posedge clk) begin
    if (!rst_sync_n) begin
        sda_in_reg <= 1'b1;
        scl_in_reg <= 1'b1;
    end else begin
        sda_in_reg <= sda_in_raw;
        scl_in_reg <= scl_in_raw;
    end
end

// CRC calculation - optimized sequential logic with reduced computation per cycle
always @(posedge clk) begin
    if (!rst_sync_n) begin
        crc_calculator_reg <= 8'hFF;
    end else begin
        // Single-bit CRC update per cycle reduces combinational logic depth
        crc_calculator_reg <= (crc_calculator_reg << 1) ^ 
                            ((crc_calculator_reg[7] ^ sda_in_reg) ? 8'h07 : 8'h00);
    end
end

// SMBus timeout counter with improved reset logic
always @(posedge clk) begin
    if (!rst_sync_n) begin
        timeout_counter <= 32'h0;
        crc_error <= 1'b0;
    end else begin
        // Separated timeout detection and counter update for better timing
        if (scl_in_reg && timeout_detected) begin
            crc_error <= 1'b1;
        end
        
        // Counter logic moved after error detection
        if (scl_in_reg)
            timeout_counter <= timeout_counter + 1;
        else
            timeout_counter <= 32'h0;
    end
end

// Data output register - optimized to reduce latency
always @(posedge clk) begin
    if (!rst_sync_n) begin
        pkt_data_reg <= 16'h0000;
    end else begin
        // Direct mapping reduces combinational path
        pkt_data_reg <= {8'h00, pkt_command};
    end
end

endmodule