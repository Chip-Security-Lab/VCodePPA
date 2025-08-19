//SystemVerilog
module rst_sync_with_status (
    input  wire clock,
    input  wire async_reset_n,
    output wire sync_reset_n,
    output wire reset_active
);
    reg [1:0] sync_ff;
    
    always @(posedge clock or negedge async_reset_n) begin
        sync_ff <= (!async_reset_n) ? 2'b00 : {sync_ff[0], 1'b1};
    end
    
    assign sync_reset_n = sync_ff[1];
    assign reset_active = ~sync_ff[1];
endmodule