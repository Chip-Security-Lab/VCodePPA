module sync_rst_synchronizer (
    input  wire clock,
    input  wire async_reset,
    input  wire sync_reset,
    output reg  reset_out
);
    reg meta;
    
    always @(posedge clock) begin
        if (sync_reset) begin
            meta <= 1'b1;
            reset_out <= 1'b1;
        end else begin
            meta <= async_reset;
            reset_out <= meta;
        end
    end
endmodule