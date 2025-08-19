//SystemVerilog
module Demux_Feedback #(parameter DW=8) (
    input clk, 
    input [DW-1:0] data_in,
    input [1:0] sel,
    input [3:0] busy,
    output reg [3:0][DW-1:0] data_out
);
    // Register input data to reduce input-to-register delay
    reg [DW-1:0] data_in_reg;
    reg [1:0] sel_reg;
    reg [3:0] busy_reg;
    
    // Use packed array for more efficient storage and routing
    reg [3:0] update_enable;
    
    always @(posedge clk) begin
        // Register inputs
        data_in_reg <= data_in;
        sel_reg <= sel;
        busy_reg <= busy;
        
        // Generate update enables directly in sequential block
        // Clear the previous enables
        update_enable <= 4'b0000;
        
        // Set the enable bit based on selector if not busy
        // Consolidates combinational and sequential logic for better resource utilization
        if (!busy_reg[sel_reg])
            update_enable[sel_reg] <= 1'b1;
            
        // Single vectorized conditional update for all channels
        // Reduces redundant logic and improves timing paths
        for (int i = 0; i < 4; i++) begin
            if (update_enable[i])
                data_out[i] <= data_in_reg;
        end
    end
endmodule