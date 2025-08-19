//SystemVerilog
module reset_sync #(parameter STAGES = 3) (
    input wire clk,
    input wire async_reset_n,
    output wire sync_reset_n
);

    reg [STAGES-1:0] reset_sync_reg;
    reg [STAGES-1:0] reset_sync_next;

    // Combinational logic for next state (if-else structure)
    always @(*) begin
        if (!async_reset_n) begin
            reset_sync_next = {STAGES{1'b0}};
        end else begin
            reset_sync_next = {reset_sync_reg[STAGES-2:0], 1'b1};
        end
    end

    // Sequential logic for flip-flops
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            reset_sync_reg <= {STAGES{1'b0}};
        end else begin
            reset_sync_reg <= reset_sync_next;
        end
    end

    // Output logic
    assign sync_reset_n = reset_sync_reg[STAGES-1];

endmodule