//SystemVerilog
module capture_compare_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire capture_trig,
    input wire [WIDTH-1:0] compare_val,
    output reg compare_match,
    output reg [WIDTH-1:0] capture_val
);
    // Pipeline stage 1 - Counter and edge detection
    reg [WIDTH-1:0] counter_stage1;
    reg capture_trig_prev_stage1;
    reg capture_trig_stage1;
    reg [WIDTH-1:0] compare_val_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 - Comparison and capture operation
    reg [WIDTH-1:0] counter_stage2;
    reg capture_edge_detected_stage2;
    reg [WIDTH-1:0] compare_val_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1 logic - optimized for better timing
    always @(posedge clk) begin
        if (rst) begin
            counter_stage1 <= {WIDTH{1'b0}};
            capture_trig_prev_stage1 <= 1'b0;
            capture_trig_stage1 <= 1'b0;
            compare_val_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            counter_stage1 <= counter_stage1 + 1'b1;
            {capture_trig_stage1, capture_trig_prev_stage1} <= {capture_trig, capture_trig_stage1}; // Shift register approach
            compare_val_stage1 <= compare_val;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2 logic - optimized data flow
    always @(posedge clk) begin
        if (rst) begin
            counter_stage2 <= {WIDTH{1'b0}};
            capture_edge_detected_stage2 <= 1'b0;
            compare_val_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            counter_stage2 <= counter_stage1;
            capture_edge_detected_stage2 <= capture_trig_stage1 & ~capture_trig_prev_stage1; // Use bit-wise operators for better synthesis
            compare_val_stage2 <= compare_val_stage1;
            valid_stage2 <= 1'b1; // Simplified valid logic
        end
    end
    
    // Optimized compare logic with registered output
    always @(posedge clk) begin
        if (rst) begin
            compare_match <= 1'b0;
            capture_val <= {WIDTH{1'b0}};
        end else if (valid_stage2) begin
            // Optimized comparison for synthesis tools using XOR reduction
            compare_match <= ~|(counter_stage2 ^ compare_val_stage2);
            
            // Conditional update with enable logic for better power efficiency
            if (capture_edge_detected_stage2) begin
                capture_val <= counter_stage2;
            end
        end
    end
endmodule