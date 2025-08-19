//SystemVerilog
module multi_stage_rst_sync #(
    parameter STAGES = 3
)(
    input  wire clock,
    input  wire raw_rst_n,
    output wire clean_rst_n
);

    wire [STAGES-1:0] sync_chain_next;
    reg  [STAGES-1:0] sync_chain_reg;

    // Combinational logic for next state
    assign sync_chain_next = (!raw_rst_n) ? {STAGES{1'b0}} : {sync_chain_reg[STAGES-2:0], 1'b1};

    // Sequential logic for register update
    always @(posedge clock or negedge raw_rst_n) begin
        if (!raw_rst_n)
            sync_chain_reg <= {STAGES{1'b0}};
        else
            sync_chain_reg <= sync_chain_next;
    end

    // Output assignment
    assign clean_rst_n = sync_chain_reg[STAGES-1];

endmodule