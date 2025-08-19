//SystemVerilog
module edge_detect_sync (
    input        clkA,
    input        clkB,
    input        rst_n,
    input        signal_in,
    output       pos_edge,
    output       neg_edge
);
    reg [2:0] sync_chain_reg;
    reg [2:0] sync_chain_buf1;
    reg [2:0] sync_chain_buf2;

    reg        pos_edge_reg;
    reg        neg_edge_reg;
    reg        pos_edge_buf;
    reg        neg_edge_buf;

    // First stage: original synchronizer chain
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n)
            sync_chain_reg <= 3'b000;
        else
            sync_chain_reg <= {sync_chain_reg[1:0], signal_in};
    end

    // First buffer stage for sync_chain
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n)
            sync_chain_buf1 <= 3'b000;
        else
            sync_chain_buf1 <= sync_chain_reg;
    end

    // Second buffer stage for sync_chain (multi-level fanout balancing)
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n)
            sync_chain_buf2 <= 3'b000;
        else
            sync_chain_buf2 <= sync_chain_buf1;
    end

    // Edge detection logic with buffered sync_chain
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            pos_edge_reg <= 1'b0;
            neg_edge_reg <= 1'b0;
        end else begin
            pos_edge_reg <= (sync_chain_buf2[2:1] == 2'b01) ? 1'b1 : 1'b0;
            neg_edge_reg <= (sync_chain_buf2[2:1] == 2'b10) ? 1'b1 : 1'b0;
        end
    end

    // Output buffer for pos_edge and neg_edge (fanout reduction)
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            pos_edge_buf <= 1'b0;
            neg_edge_buf <= 1'b0;
        end else begin
            pos_edge_buf <= pos_edge_reg;
            neg_edge_buf <= neg_edge_reg;
        end
    end

    assign pos_edge = pos_edge_buf;
    assign neg_edge = neg_edge_buf;

endmodule