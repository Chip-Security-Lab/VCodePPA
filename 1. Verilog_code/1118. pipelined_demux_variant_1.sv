//SystemVerilog
// Top-level module: pipelined_demux
module pipelined_demux (
    input  wire        clk,         // System clock
    input  wire        data_in,     // Input data
    input  wire [1:0]  addr,        // Address selection
    output wire [3:0]  demux_out    // Output channels
);

    // No pipeline registers between input and demux logic after retiming

    // Stage 1: Demux logic (combinational)
    wire [3:0] demux_logic_out;
    assign demux_logic_out = 4'b0001 << addr & {4{data_in}};

    // Stage 2: Pipeline register after demux logic
    demux_stage_pipeline u_demux_stage_pipeline (
        .clk        (clk),
        .demux_in   (demux_logic_out),
        .demux_out  (demux_out)
    );

endmodule

//-----------------------------------------------------------------------------
// Module: demux_stage_pipeline
// Function: Output pipeline register for demux output (Stage 2)
//-----------------------------------------------------------------------------
module demux_stage_pipeline (
    input  wire        clk,            // System clock
    input  wire [3:0]  demux_in,       // Demuxed data (combinational)
    output reg [3:0]   demux_out       // Registered output channels
);
    always @(posedge clk) begin
        demux_out <= demux_in;
    end
endmodule