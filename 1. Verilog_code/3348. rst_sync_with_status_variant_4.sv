//SystemVerilog
module rst_sync_with_status (
    input  wire clock,
    input  wire async_reset_n,
    output wire sync_reset_n,
    output wire reset_active
);
    reg [1:0] sync_ff;

    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_ff <= 2'b00;
        end else begin
            case (sync_ff)
                2'b00,
                2'b01,
                2'b10: sync_ff <= sync_ff + 1'b1;
                2'b11: sync_ff <= sync_ff;
                default: sync_ff <= 2'b00;
            endcase
        end
    end

    assign sync_reset_n = sync_ff[1];
    assign reset_active = ~sync_ff[1];
endmodule