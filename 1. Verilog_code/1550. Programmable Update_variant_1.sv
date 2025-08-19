//SystemVerilog
module programmable_shadow_reg #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [1:0] update_mode,
    input wire manual_trigger,
    input wire [WIDTH-1:0] threshold,
    output reg [WIDTH-1:0] shadow_data,
    output reg updated
);
    // Main data register
    reg [WIDTH-1:0] main_reg;
    
    // Update condition signals
    wire manual_update_cond = (update_mode == 2'b00) & manual_trigger;
    wire threshold_update_cond = (update_mode == 2'b01) & (main_reg > threshold);
    wire change_update_cond = (update_mode == 2'b10) & (main_reg != shadow_data);
    wire periodic_update_cond = (update_mode == 2'b11) & (main_reg != data_in);
    
    // Combined update condition
    wire update_shadow = manual_update_cond | threshold_update_cond | 
                         change_update_cond | periodic_update_cond;
    
    // Combined always block for main register and shadow update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_reg <= {WIDTH{1'b0}};
            shadow_data <= {WIDTH{1'b0}};
            updated <= 1'b0;
        end else begin
            main_reg <= data_in;
            updated <= update_shadow;
            
            if (update_shadow)
                shadow_data <= main_reg;
        end
    end
endmodule