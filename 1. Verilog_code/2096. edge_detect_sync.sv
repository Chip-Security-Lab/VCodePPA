module edge_detect_sync (
    input clkA, clkB, rst_n,
    input signal_in,
    output pos_edge, neg_edge
);
    reg [2:0] sync_chain;
    always @(posedge clkB or negedge rst_n) begin
        if(!rst_n) sync_chain <= 0;
        else sync_chain <= {sync_chain[1:0], signal_in};
    end
    assign pos_edge = (sync_chain[2:1] == 2'b01);
    assign neg_edge = (sync_chain[2:1] == 2'b10);
endmodule