//SystemVerilog
module multi_stage_rst_sync #(
    parameter STAGES = 3
)(
    input  wire clock,
    input  wire raw_rst_n,
    output wire clean_rst_n
);
    reg [STAGES-1:0] sync_chain;

    always @(posedge clock or negedge raw_rst_n) begin
        sync_chain <= (!raw_rst_n) ? {STAGES{1'b0}} : {sync_chain[STAGES-2:0], 1'b1};
    end

    assign clean_rst_n = sync_chain[STAGES-1];
endmodule