//SystemVerilog
///////////////////////////////////////////////////////////
// Module: Demux_RingBuffer_Top
// Description: Top level module for ring buffer implementation
// Parameters:
//   - DW: Data width in bits
//   - N: Buffer depth (number of entries)
///////////////////////////////////////////////////////////
module Demux_RingBuffer_Top #(
    parameter DW = 8,   // Data width
    parameter N = 8     // Buffer depth
) (
    input wire clk,                  // System clock
    input wire wr_en,                // Write enable signal
    input wire [$clog2(N)-1:0] ptr,  // Write pointer
    input wire [DW-1:0] data_in,     // Input data
    output wire [N-1:0][DW-1:0] buffer // Output buffer array
);

    // Internal signals for connecting submodules
    wire [$clog2(N)-1:0] next_ptr;

    // Instantiate the buffer write control submodule with integrated functionality
    Buffer_Write_Control #(
        .DW(DW),
        .N(N)
    ) buf_write_inst (
        .clk(clk),
        .wr_en(wr_en),
        .ptr(ptr),
        .data_in(data_in),
        .buffer(buffer)
    );

endmodule

///////////////////////////////////////////////////////////
// Module: Buffer_Write_Control
// Description: Controls writing to the buffer entries with integrated
// pointer calculation and data preparation for better timing and area
// Parameters:
//   - DW: Data width
//   - N: Buffer depth
///////////////////////////////////////////////////////////
module Buffer_Write_Control #(
    parameter DW = 8,
    parameter N = 8
) (
    input wire clk,                      // System clock
    input wire wr_en,                    // Write enable signal
    input wire [$clog2(N)-1:0] ptr,      // Current write pointer
    input wire [DW-1:0] data_in,         // Input data
    output reg [N-1:0][DW-1:0] buffer    // Output buffer array
);

    // Calculate next pointer efficiently
    wire [$clog2(N)-1:0] next_ptr;
    
    // Optimize pointer calculation for power of 2 buffers
    generate
        if ((N & (N-1)) == 0) begin : gen_pow2
            // For power of 2, use bit masking (more efficient)
            assign next_ptr = (ptr + 1'b1) & (N-1);
        end else begin : gen_non_pow2
            // For non-power of 2, use comparison-based approach
            assign next_ptr = (ptr == N-1) ? '0 : ptr + 1'b1;
        end
    endgenerate

    // Efficient write control logic with clock enable for power reduction
    always @(posedge clk) begin
        if (wr_en) begin
            buffer[ptr] <= data_in;
            buffer[next_ptr] <= '0; // Use SystemVerilog shorthand for zeros
        end
    end

endmodule