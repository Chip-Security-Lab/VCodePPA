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

    // First-level buffer registers for high fanout sync_chain_reg
    reg  sync_chain_reg_buf0;
    reg  sync_chain_reg_buf1;
    reg  sync_chain_reg_buf2;

    // Combinational logic for next state calculation
    assign sync_chain_next = (!raw_rst_n)                           ? {STAGES{1'b0}} :
                             (sync_chain_reg != {STAGES{1'b1}})     ? sync_chain_reg + {{(STAGES-1){1'b0}}, 1'b1} :
                                                                     sync_chain_reg;

    // Sequential logic for main register update
    always @(posedge clock or negedge raw_rst_n) begin
        if (!raw_rst_n)
            sync_chain_reg <= {STAGES{1'b0}};
        else
            sync_chain_reg <= sync_chain_next;
    end

    // First-level buffer registers to reduce fanout on sync_chain_reg
    always @(posedge clock or negedge raw_rst_n) begin
        if (!raw_rst_n) begin
            sync_chain_reg_buf0 <= 1'b0;
            sync_chain_reg_buf1 <= 1'b0;
            sync_chain_reg_buf2 <= 1'b0;
        end else begin
            sync_chain_reg_buf0 <= sync_chain_reg[0];
            sync_chain_reg_buf1 <= sync_chain_reg[1];
            sync_chain_reg_buf2 <= sync_chain_reg[2];
        end
    end

    // Output assignment using buffered signal
    assign clean_rst_n = sync_chain_reg_buf2;

endmodule