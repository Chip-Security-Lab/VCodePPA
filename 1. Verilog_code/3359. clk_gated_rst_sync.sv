module clk_gated_rst_sync (
    input  wire clk,
    input  wire clk_en,
    input  wire async_rst_n,
    output wire sync_rst_n
);
    reg [1:0] sync_stages;
    wire      gated_clk;
    
    assign gated_clk = clk & clk_en;
    
    always @(posedge gated_clk or negedge async_rst_n) begin
        if (!async_rst_n)
            sync_stages <= 2'b00;
        else
            sync_stages <= {sync_stages[0], 1'b1};
    end
    
    assign sync_rst_n = sync_stages[1];
endmodule