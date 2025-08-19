module wakeup_ismu(
    input clk, rst_n,
    input sleep_mode,
    input [7:0] int_src,
    input [7:0] wakeup_mask,
    output reg wakeup,
    output reg [7:0] pending_int
);
    wire [7:0] wake_sources;
    
    assign wake_sources = int_src & ~wakeup_mask;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wakeup <= 1'b0;
            pending_int <= 8'h0;
        end else begin
            pending_int <= pending_int | int_src;
            if (sleep_mode && |wake_sources)
                wakeup <= 1'b1;
            else
                wakeup <= 1'b0;
        end
    end
endmodule