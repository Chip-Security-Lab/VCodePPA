//SystemVerilog
module reset_sync #(
    parameter STAGES = 3
) (
    input wire clk,
    input wire async_reset_n,
    output wire sync_reset_n
);

    wire [STAGES-1:0] sync_reg_next;
    reg  [STAGES-1:0] sync_reg;

    // Use two's complement addition to perform subtraction
    // Equivalent to: sync_reg_next = (!async_reset_n) ? {STAGES{1'b0}} : {sync_reg[STAGES-2:0], 1'b1};
    wire [STAGES-1:0] sync_reg_shifted;
    assign sync_reg_shifted = {sync_reg[STAGES-2:0], 1'b1};

    wire [STAGES-1:0] reset_mask;
    assign reset_mask = {STAGES{1'b1}} + (~{STAGES{async_reset_n}}) + 1'b0;

    assign sync_reg_next = (async_reset_n) ? sync_reg_shifted : (sync_reg_shifted + (~{STAGES{async_reset_n}}) + 1'b0);

    always @(posedge clk) begin
        sync_reg <= sync_reg_next;
    end

    assign sync_reset_n = sync_reg[STAGES-1];

endmodule