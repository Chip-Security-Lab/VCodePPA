//SystemVerilog
module edge_detect_sync (
    input  wire clkA,
    input  wire clkB,
    input  wire rst_n,
    input  wire signal_in,
    output wire pos_edge,
    output wire neg_edge
);

    reg  [2:0] sync_chain_reg;

    // Synchronizer chain sequential logic
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n)
            sync_chain_reg <= 3'b000;
        else
            sync_chain_reg <= {sync_chain_reg[1:0], signal_in};
    end

    // Optimized edge detection logic
    assign pos_edge = ~sync_chain_reg[2] & sync_chain_reg[1];
    assign neg_edge = sync_chain_reg[2] & ~sync_chain_reg[1];

endmodule