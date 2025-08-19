//SystemVerilog
module dram_cdc_sync #(
    parameter SYNC_STAGES = 4
)(
    input wire src_clk,
    input wire dst_clk,
    input wire async_cmd,
    output reg sync_cmd
);

    // Synchronization chain registers
    reg [SYNC_STAGES-1:0] sync_chain;
    
    // First stage synchronization
    always @(posedge dst_clk) begin
        sync_chain[0] <= async_cmd;
    end
    
    // Middle stages synchronization
    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge dst_clk) begin
                sync_chain[i] <= sync_chain[i-1];
            end
        end
    endgenerate
    
    // Output stage
    always @(posedge dst_clk) begin
        sync_cmd <= sync_chain[SYNC_STAGES-1];
    end

endmodule