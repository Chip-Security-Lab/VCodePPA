//SystemVerilog
module rst_sync_with_ack (
    input  wire clk,
    input  wire async_rst_n,
    input  wire ack_reset,
    output wire sync_rst_n,
    output wire rst_active
);
    // First synchronization stage
    reg meta_stage_reg;
    
    // Second synchronization stage
    reg sync_rst_n_reg;
    
    // Reset active status register
    reg rst_active_reg;
    
    // Register ack_reset to reduce input to first register delay
    reg ack_reset_reg;
    
    // Forward register retiming - move registers after combinational logic
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage_reg <= 1'b0;
            sync_rst_n_reg <= 1'b0;
            rst_active_reg <= 1'b1;
            ack_reset_reg  <= 1'b0;
        end else begin
            meta_stage_reg <= 1'b1;
            sync_rst_n_reg <= meta_stage_reg;
            ack_reset_reg  <= ack_reset;
            
            // Combinational logic moved before register
            if (ack_reset_reg)
                rst_active_reg <= 1'b0;
            else if (!meta_stage_reg)
                rst_active_reg <= 1'b1;
            else
                rst_active_reg <= rst_active_reg;
        end
    end
    
    // Connect registers to outputs
    assign sync_rst_n = sync_rst_n_reg;
    assign rst_active = rst_active_reg;
    
endmodule