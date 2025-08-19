//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: multibit_demux_top.v
// Description: Top level module for multi-bit demultiplexer with carry-lookahead adder
// Standard: IEEE 1364-2005 Verilog
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`default_nettype none

module multibit_demux #(
    parameter DATA_WIDTH = 4,                    // Width of data bus
    parameter OUT_COUNT = 4                      // Number of outputs
) (
    input wire [DATA_WIDTH-1:0] data_in,         // Input data bus
    input wire [1:0] select,                     // Selection input
    output wire [DATA_WIDTH*OUT_COUNT-1:0] demux_out // Combined outputs
);

    // Internal connections between modules
    wire [DATA_WIDTH-1:0] channel_data [0:OUT_COUNT-1];
    
    // Instantiate the decoder module to generate select signals
    wire [OUT_COUNT-1:0] channel_select;
    binary_decoder #(
        .SEL_WIDTH(2),
        .OUT_COUNT(OUT_COUNT)
    ) decoder_inst (
        .select(select),
        .decoded_out(channel_select)
    );
    
    // Instantiate the channel selector module with CLA adder
    channel_selector_with_cla #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(OUT_COUNT)
    ) selector_inst (
        .data_in(data_in),
        .channel_select(channel_select),
        .channel_data_out(channel_data)
    );
    
    // Instantiate the output formatter module
    output_formatter #(
        .DATA_WIDTH(DATA_WIDTH),
        .CHANNEL_COUNT(OUT_COUNT)
    ) formatter_inst (
        .channel_data(channel_data),
        .demux_out(demux_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Binary Decoder: Converts binary select input to one-hot select signals
///////////////////////////////////////////////////////////////////////////////

module binary_decoder #(
    parameter SEL_WIDTH = 2,                     // Width of select input
    parameter OUT_COUNT = 4                      // Number of decoded outputs
) (
    input wire [SEL_WIDTH-1:0] select,           // Binary select input
    output wire [OUT_COUNT-1:0] decoded_out      // One-hot decoded output
);

    genvar i;
    generate
        for (i = 0; i < OUT_COUNT; i = i + 1) begin : decode_bits
            assign decoded_out[i] = (select == i);
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////////////////////////
// Channel Selector with CLA: Routes input data to selected channel with adder
///////////////////////////////////////////////////////////////////////////////

module channel_selector_with_cla #(
    parameter DATA_WIDTH = 4,                    // Width of data bus
    parameter CHANNEL_COUNT = 4                  // Number of output channels
) (
    input wire [DATA_WIDTH-1:0] data_in,         // Input data
    input wire [CHANNEL_COUNT-1:0] channel_select, // One-hot channel select
    output wire [DATA_WIDTH-1:0] channel_data_out [0:CHANNEL_COUNT-1] // Output per channel
);

    // Internal signals
    wire [1:0] processed_data;
    wire [1:0] constant_value;
    
    // Constant value for addition
    assign constant_value = 2'b01;
    
    // Instantiate 2-bit Carry-Lookahead Adder
    carry_lookahead_adder_2bit cla_inst (
        .a(data_in[1:0]),              // Use the lower 2 bits of data_in
        .b(constant_value),            // Add a constant value
        .cin(1'b0),                    // No carry-in
        .sum(processed_data),          // 2-bit sum output
        .cout()                        // Carry-out (not used)
    );
    
    genvar i, j;
    generate
        for (i = 0; i < CHANNEL_COUNT; i = i + 1) begin : channels
            // For the first 2 bits, use the processed data from the CLA adder
            for (j = 0; j < 2; j = j + 1) begin : lower_data_bits
                assign channel_data_out[i][j] = channel_select[i] ? processed_data[j] : 1'b0;
            end
            
            // For the remaining bits (if any), use the original data
            for (j = 2; j < DATA_WIDTH; j = j + 1) begin : upper_data_bits
                assign channel_data_out[i][j] = channel_select[i] ? data_in[j] : 1'b0;
            end
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////////////////////////
// Output Formatter: Combines individual channel outputs into a single bus
///////////////////////////////////////////////////////////////////////////////

module output_formatter #(
    parameter DATA_WIDTH = 4,                    // Width of data bus
    parameter CHANNEL_COUNT = 4                  // Number of input channels
) (
    input wire [DATA_WIDTH-1:0] channel_data [0:CHANNEL_COUNT-1], // Data for each channel
    output wire [DATA_WIDTH*CHANNEL_COUNT-1:0] demux_out           // Combined output bus
);

    genvar i, j;
    generate
        for (i = 0; i < CHANNEL_COUNT; i = i + 1) begin : format_channels
            for (j = 0; j < DATA_WIDTH; j = j + 1) begin : format_bits
                assign demux_out[i*DATA_WIDTH+j] = channel_data[i][j];
            end
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////////////////////////
// 2-bit Carry-Lookahead Adder
///////////////////////////////////////////////////////////////////////////////

module carry_lookahead_adder_2bit (
    input wire [1:0] a,       // 2-bit input A
    input wire [1:0] b,       // 2-bit input B
    input wire cin,           // Carry input
    output wire [1:0] sum,    // 2-bit sum output
    output wire cout          // Carry output
);
    
    // Generate and Propagate signals
    wire [1:0] g; // Generate
    wire [1:0] p; // Propagate
    wire [1:0] c; // Carries
    
    // Generate and Propagate terms
    assign g[0] = a[0] & b[0];
    assign g[1] = a[1] & b[1];
    
    assign p[0] = a[0] ^ b[0];
    assign p[1] = a[1] ^ b[1];
    
    // Carry terms using CLA logic
    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    
    // Final carry out
    assign cout = g[1] | (p[1] & c[1]);
    
    // Sum computation
    assign sum[0] = p[0] ^ c[0];
    assign sum[1] = p[1] ^ c[1];
    
endmodule

`default_nettype wire