//SystemVerilog
//IEEE 1364-2005
module programmable_clk_gen(
    input sys_clk,        // System clock
    input sys_rst_n,      // System reset (active low)
    input [15:0] divisor, // Clock divisor value
    input update,         // Update divisor value
    output reg clk_out    // Output clock
);
    // Pipeline registers for divisor value
    reg [15:0] div_value_stage1;
    reg [15:0] div_value_stage2;
    
    // Pipeline registers for counter
    reg [15:0] div_counter_stage1;
    reg [15:0] div_counter_stage2;
    
    // Valid signals for pipeline stages
    reg valid_stage1;
    reg valid_stage2;
    
    // Intermediate calculation signals
    reg counter_reset_stage1;
    reg counter_reset_stage2;
    reg clk_toggle_stage1;
    reg clk_toggle_stage2;
    
    // Stage 1: Update divisor and detect counter reset condition
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_value_stage1 <= 16'd1;
            div_counter_stage1 <= 16'd0;
            counter_reset_stage1 <= 1'b0;
            clk_toggle_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            
            // Update divisor if requested
            if (update)
                div_value_stage1 <= divisor;
                
            // Check if counter reached divisor value
            if (div_counter_stage1 >= div_value_stage1 - 16'd1) begin
                counter_reset_stage1 <= 1'b1;
                clk_toggle_stage1 <= 1'b1;
                div_counter_stage1 <= 16'd0;
            end else begin
                counter_reset_stage1 <= 1'b0;
                clk_toggle_stage1 <= 1'b0;
                div_counter_stage1 <= div_counter_stage1 + 16'd1;
            end
        end
    end
    
    // Stage 2: Propagate results and toggle clock
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_value_stage2 <= 16'd1;
            div_counter_stage2 <= 16'd0;
            counter_reset_stage2 <= 1'b0;
            clk_toggle_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            clk_out <= 1'b0;
        end else begin
            // Propagate values to next stage
            div_value_stage2 <= div_value_stage1;
            div_counter_stage2 <= div_counter_stage1;
            counter_reset_stage2 <= counter_reset_stage1;
            clk_toggle_stage2 <= clk_toggle_stage1;
            valid_stage2 <= valid_stage1;
            
            // Toggle clock output if required and pipeline is valid
            if (valid_stage2 && clk_toggle_stage2) begin
                clk_out <= ~clk_out;
            end
        end
    end
endmodule