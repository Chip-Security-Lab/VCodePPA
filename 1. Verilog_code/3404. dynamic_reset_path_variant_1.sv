//SystemVerilog
module dynamic_reset_path(
    input wire clk,
    input wire [1:0] path_select,
    input wire [3:0] reset_sources,
    input wire valid_in,      // Valid signal for input data
    output wire valid_out,    // Valid signal for output data
    output wire reset_out     // Final reset output
);
    // Intermediate signal for combinational path selection
    wire selected_reset;
    
    // Select reset source based on path_select (moved before register)
    assign selected_reset = path_select[1] ? 
                          (path_select[0] ? reset_sources[3] : reset_sources[2]) : 
                          (path_select[0] ? reset_sources[1] : reset_sources[0]);
    
    // Pipeline registers - moved after combinational logic
    reg reset_out_reg;
    reg valid_out_reg;
    reg valid_stage1;
    
    // Stage 1: Register valid signal
    always @(posedge clk) begin
        valid_stage1 <= valid_in;
    end
    
    // Stage 2: Register selected reset and valid signal
    always @(posedge clk) begin
        valid_out_reg <= valid_stage1;
        
        if (valid_stage1) begin
            reset_out_reg <= selected_reset;
        end
    end
    
    // Connect output signals
    assign reset_out = reset_out_reg;
    assign valid_out = valid_out_reg;
    
endmodule