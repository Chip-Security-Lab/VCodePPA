//SystemVerilog
module programmable_clk_gen(
    input sys_clk,        // System clock
    input sys_rst_n,      // System reset (active low)
    input [15:0] divisor, // Clock divisor value
    input update,         // Update divisor value
    output reg clk_out    // Output clock
);
    // Counters and registers
    reg [15:0] div_counter;
    reg [15:0] div_value;
    reg [15:0] div_value_stage1;
    
    // Pipeline registers for critical path optimization
    reg [15:0] div_counter_stage1;
    reg [15:0] div_counter_stage2;
    reg [15:0] div_counter_next_stage1;
    reg [15:0] div_counter_next_stage2;
    
    // Comparison pipeline registers
    reg [15:0] compare_value_stage1;
    reg compare_result_stage1;
    reg compare_result_stage2;
    reg compare_result_stage3;
    
    // Stage 1: Store divisor and prepare for comparison
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_value_stage1 <= 16'd1;
            div_counter_stage1 <= 16'd0;
            compare_value_stage1 <= 16'd0;
        end else begin
            div_value_stage1 <= div_value;
            div_counter_stage1 <= div_counter;
            compare_value_stage1 <= div_value_stage1 - 16'd1;
        end
    end
    
    // Stage 2: Calculate intermediate comparison result
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            compare_result_stage1 <= 1'b0;
        end else begin
            compare_result_stage1 <= (div_counter_stage1 >= compare_value_stage1);
        end
    end
    
    // Stage 3: Calculate next counter value based on comparison
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_counter_next_stage1 <= 16'd0;
        end else begin
            if (compare_result_stage1)
                div_counter_next_stage1 <= 16'd0;
            else
                div_counter_next_stage1 <= div_counter_stage1 + 16'd1;
        end
    end
    
    // Stage 4: Prepare final values for counter update
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_counter_next_stage2 <= 16'd0;
            compare_result_stage2 <= 1'b0;
        end else begin
            div_counter_next_stage2 <= div_counter_next_stage1;
            compare_result_stage2 <= compare_result_stage1;
        end
    end
    
    // Stage 5: Final pipeline stage for synchronization
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            compare_result_stage3 <= 1'b0;
        end else begin
            compare_result_stage3 <= compare_result_stage2;
        end
    end
    
    // Output stage: Update counter and clock output
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            div_counter <= 16'd0;
            div_value <= 16'd1;
            clk_out <= 1'b0;
        end else begin
            // Update divisor value when requested
            if (update)
                div_value <= divisor;
            
            // Update counter with pipelined value
            div_counter <= div_counter_next_stage2;
            
            // Toggle clock based on deeply pipelined comparison result
            if (compare_result_stage3)
                clk_out <= ~clk_out;
        end
    end
endmodule