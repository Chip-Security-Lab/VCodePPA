//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: multibit_demux_top.v
// Description: Top module for multi-bit demultiplexer with hierarchical design
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module multibit_demux #(
    parameter DATA_WIDTH = 4,              // Width of data bus
    parameter OUT_COUNT = 4                // Number of outputs
) (
    input wire [DATA_WIDTH-1:0] data_in,   // Input data bus
    input wire [1:0] select,               // Selection input
    output wire [DATA_WIDTH*OUT_COUNT-1:0] demux_out // Combined outputs
);

    // Intermediate signals for connections between submodules
    wire [DATA_WIDTH-1:0] output_channels [OUT_COUNT-1:0];
    
    // Instantiate the selector module
    selector_decoder #(
        .DATA_WIDTH(DATA_WIDTH)
    ) selector_inst (
        .data_in(data_in),
        .select(select),
        .output_ch0(output_channels[0]),
        .output_ch1(output_channels[1]),
        .output_ch2(output_channels[2]),
        .output_ch3(output_channels[3])
    );
    
    // Instantiate the output formatter module
    output_formatter #(
        .DATA_WIDTH(DATA_WIDTH),
        .OUT_COUNT(OUT_COUNT)
    ) formatter_inst (
        .channel_outputs(output_channels),
        .demux_out(demux_out)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: selector_decoder.v
// Description: Decodes the select signal and routes data to appropriate output
///////////////////////////////////////////////////////////////////////////////

module selector_decoder #(
    parameter DATA_WIDTH = 4
) (
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [1:0] select,
    output wire [DATA_WIDTH-1:0] output_ch0,
    output wire [DATA_WIDTH-1:0] output_ch1,
    output wire [DATA_WIDTH-1:0] output_ch2,
    output wire [DATA_WIDTH-1:0] output_ch3
);

    // Selection logic optimized for better timing
    wire [3:0] select_decoded;
    
    // One-hot decoder to improve timing and reduce glitches
    assign select_decoded[0] = (select == 2'b00);
    assign select_decoded[1] = (select == 2'b01);
    assign select_decoded[2] = (select == 2'b10);
    assign select_decoded[3] = (select == 2'b11);
    
    // Implementation using conditional inverse subtractor for data routing
    wire [DATA_WIDTH-1:0] subtractor_result [3:0];
    wire [DATA_WIDTH-1:0] inverse_data;
    wire [DATA_WIDTH-1:0] constant_value;
    wire enable_inverse;
    
    // Generate inverse of input data when needed
    assign enable_inverse = |select;
    assign inverse_data = ~data_in;
    assign constant_value = 4'h1; // Constant for 2's complement
    
    // Conditional inverse subtractor implementation
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : subtractor_inst
            wire [DATA_WIDTH:0] temp_result;
            wire [DATA_WIDTH-1:0] operand_a;
            wire [DATA_WIDTH-1:0] operand_b;
            
            assign operand_a = (i == 0) ? data_in : 
                              (enable_inverse ? inverse_data : data_in);
            assign operand_b = (i == 0) ? 4'h0 : 
                              ((i == 1) ? constant_value : 
                              ((i == 2) ? constant_value << 1 : 
                                         constant_value << 2));
            
            assign temp_result = {1'b0, operand_a} - {1'b0, operand_b};
            assign subtractor_result[i] = temp_result[DATA_WIDTH-1:0];
        end
    endgenerate
    
    // Assign outputs based on decoded select signals
    assign output_ch0 = select_decoded[0] ? subtractor_result[0] : {DATA_WIDTH{1'b0}};
    assign output_ch1 = select_decoded[1] ? subtractor_result[1] : {DATA_WIDTH{1'b0}};
    assign output_ch2 = select_decoded[2] ? subtractor_result[2] : {DATA_WIDTH{1'b0}};
    assign output_ch3 = select_decoded[3] ? subtractor_result[3] : {DATA_WIDTH{1'b0}};

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: output_formatter.v
// Description: Formats individual channel outputs into a combined output bus
///////////////////////////////////////////////////////////////////////////////

module output_formatter #(
    parameter DATA_WIDTH = 4,
    parameter OUT_COUNT = 4
) (
    input wire [DATA_WIDTH-1:0] channel_outputs [OUT_COUNT-1:0],
    output wire [DATA_WIDTH*OUT_COUNT-1:0] demux_out
);

    // Map individual channel outputs to the combined output bus
    genvar j;
    generate
        for (j = 0; j < OUT_COUNT; j = j + 1) begin : output_mapping
            assign demux_out[DATA_WIDTH*(j+1)-1:DATA_WIDTH*j] = channel_outputs[j];
        end
    endgenerate

endmodule