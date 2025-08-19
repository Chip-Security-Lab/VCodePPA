//SystemVerilog
module rst_sync_with_status (
    input  wire clock,
    input  wire async_reset_n,
    output wire sync_reset_n,
    output wire reset_active
);
    reg [1:0] sync_ff;
    reg       sync_reset_n_reg;
    reg       reset_active_reg;

    // Pipeline stage 1: Synchronizer flip-flops moved after combination logic
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n)
            sync_ff <= 2'b00;
        else
            sync_ff <= {sync_ff[0], 1'b1};
    end

    // Pipeline stage 2: Register output signals after combination logic
    always @(posedge clock or negedge async_reset_n) begin
        if (!async_reset_n) begin
            sync_reset_n_reg <= 1'b0;
            reset_active_reg <= 1'b1;
        end else begin
            sync_reset_n_reg <= sync_ff[1];
            reset_active_reg <= ~sync_ff[1];
        end
    end

    assign sync_reset_n = sync_reset_n_reg;
    assign reset_active = reset_active_reg;
endmodule