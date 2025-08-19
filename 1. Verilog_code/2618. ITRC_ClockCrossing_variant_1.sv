//SystemVerilog
module ITRC_ClockCrossing #(
    parameter SYNC_STAGES = 4
)(
    input  logic src_clk,
    input  logic dst_clk,
    input  logic async_int,
    output logic sync_int
);

    // Synchronization chain registers
    logic [SYNC_STAGES-1:0] sync_chain;

    // Synchronization pipeline
    always_ff @(posedge dst_clk) begin
        sync_chain <= {sync_chain[SYNC_STAGES-2:0], async_int};
    end

    // Output assignment
    assign sync_int = sync_chain[SYNC_STAGES-1];

endmodule