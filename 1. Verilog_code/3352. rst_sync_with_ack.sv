module rst_sync_with_ack (
    input  wire clk,
    input  wire async_rst_n,
    input  wire ack_reset,
    output reg  sync_rst_n,
    output reg  rst_active
);
    reg meta_stage;
    
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage <= 1'b0;
            sync_rst_n <= 1'b0;
            rst_active <= 1'b1;
        end else begin
            meta_stage <= 1'b1;
            sync_rst_n <= meta_stage;
            
            if (ack_reset)
                rst_active <= 1'b0;
            else if (!sync_rst_n)
                rst_active <= 1'b1;
        end
    end
endmodule
