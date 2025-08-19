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
    reg [WIDTH-1:0] period_stage1, period_stage2;
    reg [WIDTH-1:0] counter_stage1, counter_stage2, counter_stage3;
    reg enable_stage1, enable_stage2, enable_stage3;
    reg counter_at_period_stage1, counter_at_period_stage2;
    
    // Intermediate comparison signals
    wire counter_at_period;
    wire [WIDTH-1:0] next_counter;
    
    // Valid signals for pipeline control
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Input Registration and Period Capture
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_stage1 <= {WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            period_stage1 <= period;
            enable_stage1 <= enable;
            valid_stage1 <= enable;
        end
    end
    
    // Stage 2: Comparison and Counter Update Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= {WIDTH{1'b0}};
            period_stage2 <= {WIDTH{1'b0}};
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            counter_stage1 <= counter_stage3;  // Feedback from stage 3
            period_stage2 <= period_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Comparison logic - broken into smaller parts for better timing
    wire [WIDTH/2-1:0] upper_equal, lower_equal;
    wire upper_greater, lower_greater_equal;
    
    assign upper_equal = (counter_stage1[WIDTH-1:WIDTH/2] == period_stage2[WIDTH-1:WIDTH/2]);
    assign lower_equal = (counter_stage1[WIDTH/2-1:0] == period_stage2[WIDTH/2-1:0] - 1'b1);
    assign upper_greater = (counter_stage1[WIDTH-1:WIDTH/2] > period_stage2[WIDTH-1:WIDTH/2]);
    assign lower_greater_equal = (counter_stage1[WIDTH/2-1:0] >= period_stage2[WIDTH/2-1:0] - 1'b1);
    
    assign counter_at_period = upper_greater || (upper_equal && lower_greater_equal);
    
    // Stage 3: Result Calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= {WIDTH{1'b0}};
            counter_at_period_stage1 <= 1'b0;
            enable_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            counter_at_period_stage1 <= counter_at_period && valid_stage2 && enable_stage2;
            enable_stage3 <= enable_stage2;
            valid_stage3 <= valid_stage2;
            
            if (valid_stage2 && enable_stage2) begin
                if (counter_at_period) begin
                    counter_stage2 <= {WIDTH{1'b0}};
                end else begin
                    counter_stage2 <= counter_stage1 + 1'b1;
                end
            end else begin
                counter_stage2 <= counter_stage1;
            end
        end
    end
    
    // Stage 4: Final Output Stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage3 <= {WIDTH{1'b0}};
            counter_at_period_stage2 <= 1'b0;
            timeout <= 1'b0;
        end else begin
            counter_stage3 <= counter_stage2;
            counter_at_period_stage2 <= counter_at_period_stage1;
            
            if (valid_stage3 && enable_stage3) begin
                timeout <= counter_at_period_stage2;
            end
        end
    end
endmodule