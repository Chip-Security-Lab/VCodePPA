module reset_sync #(parameter STAGES = 3) (
    input wire clk,
    input wire async_reset_n,
    output wire sync_reset_n
);
    reg [STAGES-1:0] reset_sync_reg;
    
    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n)
            reset_sync_reg <= {STAGES{1'b0}};
        else
            reset_sync_reg <= {reset_sync_reg[STAGES-2:0], 1'b1};
    end
    
    assign sync_reset_n = reset_sync_reg[STAGES-1];
endmodule