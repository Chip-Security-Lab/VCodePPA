//SystemVerilog
module basic_timer #(
    parameter CLK_FREQ = 50000000,  // Clock frequency in Hz
    parameter WIDTH = 32            // Timer width in bits
)(
    input wire clk,                 // System clock
    input wire rst_n,               // Active-low reset
    input wire enable,              // Timer enable
    input wire [WIDTH-1:0] period,  // Timer period
    output reg timeout              // Timeout flag
);
    // Pipeline stage registers
    reg [WIDTH-1:0] counter;
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] counter_stage2;
    
    // Pipeline valid registers
    reg enable_stage1;
    reg enable_stage2;
    reg enable_stage3;
    
    // Pipeline registers for period
    reg [WIDTH-1:0] period_reg;
    reg [WIDTH-1:0] period_stage1;
    reg [WIDTH-1:0] period_stage2;
    
    // Pipeline registers for comparison results
    reg compare_result_stage1;
    reg compare_result_stage2;
    
    // Main counter logic (Input stage)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            period_reg <= {WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= enable;
            period_reg <= period;
            
            if (enable) begin
                if (counter >= period_reg - 1'b1 || compare_result_stage2) begin
                    counter <= {WIDTH{1'b0}};
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end
    
    // Stage 1: Counter recording and initial comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {WIDTH{1'b0}};
            period_stage1 <= {WIDTH{1'b0}};
            enable_stage2 <= 1'b0;
            compare_result_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= counter;
            period_stage1 <= period_reg;
            enable_stage2 <= enable_stage1;
            
            // Perform comparison in stage 1
            if (enable_stage1) begin
                compare_result_stage1 <= (counter >= period_reg - 1'b1);
            end else begin
                compare_result_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Refined comparison and preparation for timeout
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {WIDTH{1'b0}};
            period_stage2 <= {WIDTH{1'b0}};
            enable_stage3 <= 1'b0;
            compare_result_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            period_stage2 <= period_stage1;
            enable_stage3 <= enable_stage2;
            
            // Forward the comparison result
            compare_result_stage2 <= compare_result_stage1;
        end
    end
    
    // Output stage: Generate timeout signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeout <= 1'b0;
        end else begin
            if (enable_stage3) begin
                timeout <= compare_result_stage2;
            end else begin
                timeout <= 1'b0;
            end
        end
    end
endmodule