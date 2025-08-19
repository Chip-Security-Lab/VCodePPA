//SystemVerilog IEEE 1364-2005 Standard
module Demux_OneHot #(
    parameter DW = 16,  // Data width
    parameter N = 4     // Number of output channels
) (
    input wire [DW-1:0] din,           // Input data
    input wire [N-1:0] sel,            // One-hot selection signal
    output wire [N-1:0][DW-1:0] dout   // Demuxed output data
);

    // Instantiate the channel controller to manage demux operation
    Demux_Controller #(
        .DW(DW),
        .N(N)
    ) controller_inst (
        .din(din),
        .sel(sel),
        .dout(dout)
    );

endmodule

// Controller module to manage the demux channels
module Demux_Controller #(
    parameter DW = 16,  // Data width
    parameter N = 4     // Number of output channels
) (
    input wire [DW-1:0] din,           // Input data
    input wire [N-1:0] sel,            // One-hot selection signal
    output wire [N-1:0][DW-1:0] dout   // Demuxed output data
);

    // Input validation module to check for one-hot property
    wire valid_sel;
    Demux_Validator #(
        .N(N)
    ) validator_inst (
        .sel(sel),
        .valid(valid_sel)
    );

    // Channel array instantiation
    Demux_ChannelArray #(
        .DW(DW),
        .N(N)
    ) channel_array_inst (
        .din(din),
        .sel(sel),
        .valid_sel(valid_sel),
        .dout(dout)
    );

endmodule

// Validator module to check one-hot property
module Demux_Validator #(
    parameter N = 4     // Number of output channels
) (
    input wire [N-1:0] sel,            // One-hot selection signal
    output wire valid                   // Valid one-hot signal
);
    
    // Count active bits in selection signal
    wire [$clog2(N+1)-1:0] active_bits;
    Demux_BitCounter #(
        .N(N)
    ) bit_counter_inst (
        .data(sel),
        .count(active_bits)
    );
    
    // Selection is valid if exactly one bit is active
    assign valid = (active_bits == 1'b1);

endmodule

// Bit counter module
module Demux_BitCounter #(
    parameter N = 4     // Width of input data
) (
    input wire [N-1:0] data,           // Input data to count bits
    output wire [$clog2(N+1)-1:0] count // Count of active bits
);
    
    integer i;
    reg [$clog2(N+1)-1:0] bit_count;
    
    always @(*) begin
        bit_count = 0;
        for (i = 0; i < N; i = i + 1) begin
            if (data[i]) bit_count = bit_count + 1'b1;
        end
    end
    
    assign count = bit_count;

endmodule

// Channel array module to handle multiple channels
module Demux_ChannelArray #(
    parameter DW = 16,  // Data width
    parameter N = 4     // Number of output channels
) (
    input wire [DW-1:0] din,            // Input data
    input wire [N-1:0] sel,             // One-hot selection signal
    input wire valid_sel,               // Valid one-hot indicator
    output wire [N-1:0][DW-1:0] dout    // Demuxed output data
);

    // Instantiate output channel modules
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : output_channels
            Demux_Channel #(
                .DW(DW)
            ) channel_inst (
                .din(din),
                .sel(sel[i] & valid_sel), // Only enable if selection is valid
                .dout(dout[i])
            );
        end
    endgenerate

endmodule

// Single channel module for the demux with optimized enable logic
module Demux_Channel #(
    parameter DW = 16  // Data width
) (
    input wire [DW-1:0] din,     // Input data
    input wire sel,              // Selection signal for this channel
    output wire [DW-1:0] dout    // Output data for this channel
);

    // Use efficient enable gating
    Demux_DataGate #(
        .DW(DW)
    ) data_gate_inst (
        .data_in(din),
        .enable(sel),
        .data_out(dout)
    );

endmodule

// Optimized data gating module
module Demux_DataGate #(
    parameter DW = 16  // Data width
) (
    input wire [DW-1:0] data_in,  // Input data
    input wire enable,            // Enable signal
    output wire [DW-1:0] data_out // Gated output data
);

    // Efficiently gate data with enable signal
    assign data_out = enable ? data_in : {DW{1'b0}};

endmodule