module sync_multi_timer (
    input wire master_clk, slave_clk, reset, sync_en,
    output reg [31:0] master_count, slave_count,
    output wire synced
);
    reg sync_req, sync_ack;
    reg [2:0] sync_shift;
    always @(posedge master_clk) begin
        if (reset) begin master_count <= 32'h0; sync_req <= 1'b0; end
        else begin
            master_count <= master_count + 32'h1;
            sync_req <= sync_en & (master_count[7:0] == 8'h0);
        end
    end
    always @(posedge slave_clk) begin
        if (reset) sync_shift <= 3'b0;
        else sync_shift <= {sync_shift[1:0], sync_req};
    end
    always @(posedge slave_clk) begin
        if (reset) begin slave_count <= 32'h0; sync_ack <= 1'b0; end
        else begin
            slave_count <= (~sync_shift[2] & sync_shift[1]) ? 32'h0 : slave_count + 32'h1;
            sync_ack <= (~sync_shift[2] & sync_shift[1]);
        end
    end
    assign synced = sync_ack;
endmodule