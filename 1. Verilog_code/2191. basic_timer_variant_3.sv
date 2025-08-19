//SystemVerilog
//IEEE 1364-2005
module basic_timer #(
    parameter CLK_FREQ = 50000000,  // Clock frequency in Hz
    parameter WIDTH = 32,           // Timer width in bits
    parameter PIPELINE_STAGES = 4   // Number of pipeline stages
)(
    input wire clk,                 // System clock
    input wire rst_n,               // Active-low reset
    input wire enable,              // Timer enable
    input wire [WIDTH-1:0] period,  // Timer period
    output reg timeout              // Timeout flag
);
    // Pipeline stage registers for counter
    reg [WIDTH-1:0] counter_stage1;
    reg [WIDTH-1:0] counter_stage2;
    reg [WIDTH-1:0] counter_stage3;
    reg [WIDTH-1:0] counter_stage4;
    
    // Pipeline valid signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    reg valid_stage4;
    
    // Pipeline comparison results
    reg compare_stage2;
    reg compare_stage3;
    reg compare_stage4;
    
    // Registered period values for each stage
    reg [WIDTH-1:0] period_reg;
    reg [WIDTH-1:0] period_stage1;
    reg [WIDTH-1:0] period_stage2;
    
    // Stage 0: Register inputs first to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_reg <= {WIDTH{1'b0}};
        end else begin
            period_reg <= period;
        end
    end
    
    // Stage 1: Counter initialization and increment with pre-registered inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
            period_stage1 <= {WIDTH{1'b0}};
        end else if (enable) begin
            valid_stage1 <= 1'b1;
            period_stage1 <= period_reg;
            
            if (valid_stage4 && compare_stage4) begin
                counter_stage1 <= {WIDTH{1'b0}}; // Reset counter on timeout
            end else if (valid_stage1) begin
                counter_stage1 <= counter_stage1 + 1'b1;
            end
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Pass counter value and perform early comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            period_stage2 <= {WIDTH{1'b0}};
            compare_stage2 <= 1'b0;
        end else begin
            counter_stage2 <= counter_stage1;
            valid_stage2 <= valid_stage1;
            period_stage2 <= period_stage1;
            
            // Move comparison earlier in the pipeline
            if (valid_stage1) begin
                compare_stage2 <= (counter_stage1 >= period_stage1 - 1);
            end else begin
                compare_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Pipeline the comparison result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            compare_stage3 <= 1'b0;
        end else begin
            counter_stage3 <= counter_stage2;
            valid_stage3 <= valid_stage2;
            compare_stage3 <= compare_stage2;
        end
    end
    
    // Stage 4: Generate timeout signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage4 <= {WIDTH{1'b0}};
            valid_stage4 <= 1'b0;
            compare_stage4 <= 1'b0;
            timeout <= 1'b0;
        end else begin
            counter_stage4 <= counter_stage3;
            valid_stage4 <= valid_stage3;
            compare_stage4 <= compare_stage3;
            
            // Generate timeout
            if (valid_stage3) begin
                timeout <= compare_stage3;
            end else begin
                timeout <= 1'b0;
            end
        end
    end
endmodule