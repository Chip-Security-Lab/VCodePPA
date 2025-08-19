//SystemVerilog
module edge_detect_sync (
    input  wire clkA,
    input  wire clkB,
    input  wire rst_n,
    input  wire signal_in,
    output wire pos_edge,
    output wire neg_edge
);
    // Synchronization flip-flops
    reg sync_ff1;
    reg sync_ff2;
    reg sync_ff3;
    reg prev_sync;

    // Edge detection flip-flops
    reg pos_edge_reg;
    reg neg_edge_reg;

    // Balanced combinational logic for edge detection
    wire sync_now, sync_prev;
    assign sync_now  = sync_ff3;
    assign sync_prev = prev_sync;

    wire rising_edge_int, falling_edge_int;

    assign rising_edge_int  = sync_now & ~sync_prev;
    assign falling_edge_int = ~sync_now & sync_prev;

    // Synchronization stages
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1   <= 1'b0;
            sync_ff2   <= 1'b0;
            sync_ff3   <= 1'b0;
            prev_sync  <= 1'b0;
        end else begin
            sync_ff1   <= signal_in;
            sync_ff2   <= sync_ff1;
            sync_ff3   <= sync_ff2;
            prev_sync  <= sync_ff3;
        end
    end

    // Edge detection output registers
    always @(posedge clkB or negedge rst_n) begin
        if (!rst_n) begin
            pos_edge_reg <= 1'b0;
            neg_edge_reg <= 1'b0;
        end else begin
            pos_edge_reg <= rising_edge_int;
            neg_edge_reg <= falling_edge_int;
        end
    end

    assign pos_edge = pos_edge_reg;
    assign neg_edge = neg_edge_reg;

endmodule