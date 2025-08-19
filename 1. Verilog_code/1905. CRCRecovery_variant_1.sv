//SystemVerilog
// Top-level module
module CRCRecovery #(
    parameter WIDTH = 8
)(
    input wire clk, 
    input wire [WIDTH+3:0] coded_in, // 4-bit CRC
    output wire [WIDTH-1:0] data_out,
    output wire crc_error
);
    // Internal signals
    wire [3:0] calculated_crc;
    
    // Instantiate CRC Verification sub-module
    CRC_Calculator #(
        .WIDTH(WIDTH)
    ) crc_calc_inst (
        .coded_data(coded_in),
        .calculated_crc(calculated_crc)
    );
    
    // Instantiate Error Detection sub-module
    Error_Detector error_detect_inst (
        .clk(clk),
        .calculated_crc(calculated_crc),
        .crc_error(crc_error)
    );
    
    // Instantiate Data Output Handler sub-module
    Data_Output_Handler #(
        .WIDTH(WIDTH)
    ) data_out_inst (
        .clk(clk),
        .coded_data(coded_in),
        .crc_error(crc_error),
        .data_out(data_out)
    );
    
endmodule

// CRC Calculator sub-module
module CRC_Calculator #(
    parameter WIDTH = 8
)(
    input wire [WIDTH+3:0] coded_data,
    output wire [3:0] calculated_crc
);
    // Calculate CRC by XORing the received CRC with the data bits
    assign calculated_crc = coded_data[WIDTH+3:WIDTH] ^ coded_data[WIDTH-1:0];
    
endmodule

// Error Detector sub-module
module Error_Detector (
    input wire clk,
    input wire [3:0] calculated_crc,
    output reg crc_error
);
    // Check if any bit in calculated CRC is non-zero (indicating error)
    always @(posedge clk) begin
        crc_error <= |calculated_crc;
    end
    
endmodule

// Data Output Handler sub-module
module Data_Output_Handler #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire [WIDTH+3:0] coded_data,
    input wire crc_error,
    output reg [WIDTH-1:0] data_out
);
    // Output data or error pattern based on CRC verification
    always @(posedge clk) begin
        data_out <= crc_error ? {WIDTH{1'b1}} : coded_data[WIDTH-1:0];
    end
    
endmodule