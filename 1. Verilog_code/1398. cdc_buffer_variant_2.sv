//SystemVerilog
//============================================================================
// Module: cdc_buffer_top
// Description: Top level CDC (Clock Domain Crossing) buffer module
// Standard: IEEE 1364-2005
//============================================================================
module cdc_buffer_top #(
    parameter DW = 8
)(
    input  wire            src_clk,   // Source clock domain
    input  wire            dst_clk,   // Destination clock domain
    input  wire [DW-1:0]   din,       // Input data
    output wire [DW-1:0]   dout       // Output data
);

    // Internal signals for module interconnection
    wire [DW-1:0] captured_data;
    
    // Source domain data capture module
    src_data_capture #(
        .DATA_WIDTH(DW)
    ) u_src_capture (
        .clk        (src_clk),
        .data_in    (din),
        .data_out   (captured_data)
    );
    
    // CDC synchronization module
    sync_stage #(
        .DATA_WIDTH(DW)
    ) u_sync (
        .clk        (dst_clk),
        .data_in    (captured_data),
        .data_out   (dout)
    );

endmodule

//============================================================================
// Module: src_data_capture
// Description: Captures data in the source clock domain
//============================================================================
module src_data_capture #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output reg  [DATA_WIDTH-1:0]   data_out
);

    // Capture input data on rising edge of source clock
    always @(posedge clk) begin
        data_out <= data_in;
    end

endmodule

//============================================================================
// Module: sync_stage
// Description: Implements synchronization for crossing clock domains
//              Uses two-stage synchronizer to reduce metastability
//============================================================================
module sync_stage #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire [DATA_WIDTH-1:0]   data_in,
    output wire [DATA_WIDTH-1:0]   data_out
);

    // Two-stage synchronizer registers
    reg [DATA_WIDTH-1:0] meta_reg;
    reg [DATA_WIDTH-1:0] sync_reg;
    
    // Implement two-stage synchronizer
    always @(posedge clk) begin
        meta_reg <= data_in;    // First stage (metastability capture)
        sync_reg <= meta_reg;   // Second stage (stabilization)
    end
    
    // Assign synchronized data to output
    assign data_out = sync_reg;

endmodule