//SystemVerilog
`timescale 1ns / 1ps
`default_nettype none

module bus_width_display_codec #(
    parameter INBUS_WIDTH = 32,
    parameter OUTBUS_WIDTH = 16
) (
    input wire clk, rst_n,
    input wire clk_en,  // Clock gating control
    input wire [INBUS_WIDTH-1:0] data_in,
    input wire [1:0] format_select,  // 0: RGB, 1: YUV, 2: MONO, 3: RAW
    output reg [OUTBUS_WIDTH-1:0] data_out
);
    // Internal gated clock
    wire gated_clk;
    assign gated_clk = clk & clk_en;
    
    // Buffered input data to reduce fanout
    reg [INBUS_WIDTH-1:0] data_in_buf1, data_in_buf2;
    // Buffered format select to reduce fanout
    reg [1:0] format_select_buf1, format_select_buf2;
    // Intermediate data output for pipeline stage
    reg [OUTBUS_WIDTH-1:0] data_out_int;
    
    // Lookup table for output data processing methods
    reg [1:0] process_mode;
    
    // Input buffering for high fanout signals
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_buf1 <= {INBUS_WIDTH{1'b0}};
            data_in_buf2 <= {INBUS_WIDTH{1'b0}};
            format_select_buf1 <= 2'b00;
            format_select_buf2 <= 2'b00;
        end else begin
            data_in_buf1 <= data_in;
            data_in_buf2 <= data_in_buf1;
            format_select_buf1 <= format_select;
            format_select_buf2 <= format_select_buf1;
        end
    end
    
    // Determine process mode based on format and bus width (LUT approach)
    always @(*) begin
        // Default mode: passthrough with truncation
        process_mode = 2'b11;
        
        case (format_select_buf2)
            2'b00: begin  // RGB format
                process_mode = (INBUS_WIDTH >= 24 && OUTBUS_WIDTH >= 16) ? 2'b00 : 2'b11;
            end
            2'b01: begin  // YUV format
                process_mode = 2'b11;  // Use passthrough for YUV
            end
            2'b10: begin  // MONO format
                process_mode = 2'b01;  // Special mono processing
            end
            2'b11: begin  // RAW format
                process_mode = 2'b11;  // Default passthrough
            end
        endcase
    end
    
    // Data processing based on process_mode from LUT
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_int <= {OUTBUS_WIDTH{1'b0}};
        end else begin
            case (process_mode)
                2'b00: begin
                    // RGB888 to RGB565 conversion
                    data_out_int[OUTBUS_WIDTH-1:OUTBUS_WIDTH-5] <= data_in_buf2[INBUS_WIDTH-1:INBUS_WIDTH-5];
                    data_out_int[OUTBUS_WIDTH-6:OUTBUS_WIDTH-11] <= data_in_buf2[INBUS_WIDTH-9:INBUS_WIDTH-14];
                    data_out_int[OUTBUS_WIDTH-12:OUTBUS_WIDTH-16] <= data_in_buf2[INBUS_WIDTH-17:INBUS_WIDTH-21];
                    if (OUTBUS_WIDTH > 16)
                        data_out_int[OUTBUS_WIDTH-17:0] <= {(OUTBUS_WIDTH-16){1'b0}};
                end
                2'b01: begin
                    // MONO conversion
                    data_out_int <= {OUTBUS_WIDTH{data_in_buf2[INBUS_WIDTH-1]}};
                end
                default: begin
                    // Default passthrough with truncation/padding
                    data_out_int <= data_in_buf2[INBUS_WIDTH-1:INBUS_WIDTH-OUTBUS_WIDTH];
                end
            endcase
        end
    end
    
    // Output buffer to reduce fanout
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {OUTBUS_WIDTH{1'b0}};
        end else begin
            data_out <= data_out_int;
        end
    end
    
endmodule