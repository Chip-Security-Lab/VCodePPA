//SystemVerilog
module rst_sync_with_status (
    input  wire clock,
    input  wire async_reset_n,
    output wire sync_reset_n,
    output wire reset_active
);

    wire [1:0] sync_ff_next;
    reg  [1:0] sync_ff_reg;

    // Combinational logic for next state
    assign sync_ff_next = (!async_reset_n) ? 2'b00 : {sync_ff_reg[0], 1'b1};

    // Sequential logic for synchronization flip-flops
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n)
            sync_ff_reg <= 2'b00;
        else
            sync_ff_reg <= sync_ff_next;
    end

    // Combinational logic for outputs
    assign sync_reset_n = sync_ff_reg[1];
    assign reset_active = ~sync_ff_reg[1];

endmodule