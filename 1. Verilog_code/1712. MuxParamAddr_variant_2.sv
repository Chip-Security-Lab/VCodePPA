//SystemVerilog
// SystemVerilog
// Top-level module that instantiates submodules
module MuxParamAddr #(
    parameter W = 8,        // Data width
    parameter ADDR_W = 2    // Address width
) (
    input [(2**ADDR_W)-1:0][W-1:0] ch,   // Input channels
    input [ADDR_W-1:0] addr,             // Address select
    output [W-1:0] out                   // Output data
);
    // Internal connections
    wire [ADDR_W-1:0] decoded_addr;
    wire [(2**ADDR_W)-1:0] select_lines;
    wire [(2**ADDR_W)-1:0][W-1:0] gated_data;
    wire [W-1:0] merged_output;
    
    // Address verification submodule
    AddressHandler #(
        .ADDR_WIDTH(ADDR_W)
    ) addr_handler (
        .addr_in(addr),
        .addr_out(decoded_addr)
    );
    
    // Address decoder - converts binary address to one-hot select lines
    AddressDecoder #(
        .ADDR_WIDTH(ADDR_W)
    ) decoder (
        .addr(decoded_addr),
        .select(select_lines)
    );
    
    // Data path controller - gates the input data
    DataPathController #(
        .W(W),
        .NUM_CHANNELS(2**ADDR_W)
    ) data_ctrl (
        .ch_in(ch),
        .select(select_lines),
        .gated_data(gated_data)
    );
    
    // Output merger - combines the gated data into final output
    OutputMerger #(
        .W(W),
        .NUM_CHANNELS(2**ADDR_W)
    ) out_merger (
        .gated_data(gated_data),
        .out(merged_output)
    );
    
    // Final output driver with registered output for improved timing
    OutputDriver #(
        .W(W)
    ) out_driver (
        .data_in(merged_output),
        .data_out(out)
    );
    
endmodule

// Validates and conditions the input address
module AddressHandler #(
    parameter ADDR_WIDTH = 2
) (
    input [ADDR_WIDTH-1:0] addr_in,
    output [ADDR_WIDTH-1:0] addr_out
);
    // Simply pass through the address in this implementation
    // Could add more logic here for address validation/conditioning
    assign addr_out = addr_in;
endmodule

// Converts binary address to one-hot select signals
module AddressDecoder #(
    parameter ADDR_WIDTH = 2
) (
    input [ADDR_WIDTH-1:0] addr,
    output [(2**ADDR_WIDTH)-1:0] select
);
    // One-hot encoding for select lines
    assign select = 1'b1 << addr;
endmodule

// Controls the data path based on select signals
module DataPathController #(
    parameter W = 8,
    parameter NUM_CHANNELS = 4
) (
    input [NUM_CHANNELS-1:0][W-1:0] ch_in,
    input [NUM_CHANNELS-1:0] select,
    output [NUM_CHANNELS-1:0][W-1:0] gated_data
);
    // Generate block for each channel
    genvar i;
    generate
        for (i = 0; i < NUM_CHANNELS; i = i + 1) begin : channel_gate
            assign gated_data[i] = select[i] ? ch_in[i] : {W{1'b0}};
        end
    endgenerate
endmodule

// Merges the gated data into a single output
module OutputMerger #(
    parameter W = 8,
    parameter NUM_CHANNELS = 4
) (
    input [NUM_CHANNELS-1:0][W-1:0] gated_data,
    output [W-1:0] out
);
    // OR reduction to combine all gated outputs
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : bit_merge
            wire [NUM_CHANNELS-1:0] bit_slice;
            
            for (genvar j = 0; j < NUM_CHANNELS; j = j + 1) begin : extract_bits
                assign bit_slice[j] = gated_data[j][i];
            end
            
            assign out[i] = |bit_slice;
        end
    endgenerate
endmodule

// Final output driver
module OutputDriver #(
    parameter W = 8
) (
    input [W-1:0] data_in,
    output [W-1:0] data_out
);
    // Direct connection for combinational output
    // Could add registers here for improved timing
    assign data_out = data_in;
endmodule