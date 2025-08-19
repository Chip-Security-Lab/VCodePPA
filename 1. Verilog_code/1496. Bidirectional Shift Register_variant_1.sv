//SystemVerilog
module bidir_shift_reg #(parameter WIDTH = 8) (
    input wire clk, rst, en, dir, data_in,
    output wire [WIDTH-1:0] q_out
);
    // ============ Pipeline Stage 1: Input Registration ============
    reg data_in_stage1, dir_stage1, en_stage1;
    
    // ============ Pipeline Stage 2: Intermediate control signals ============
    reg data_in_stage2, dir_stage2, en_stage2;
    
    // ============ Pipeline Stages 3-4: Shift computation split into phases ============
    // Main shift register with more pipeline stages
    reg [WIDTH-1:0] shiftreg_stage3;    // After initial computation
    reg [WIDTH-1:0] shiftreg_stage4;    // After final computation
    
    // ============ Pipeline Stage 5: Output buffering split by quarters ============
    // Split into quarter sections for better fanout distribution
    reg [WIDTH/4-1:0] shiftreg_buf_q1;  // First quarter
    reg [WIDTH/4-1:0] shiftreg_buf_q2;  // Second quarter
    reg [WIDTH/4-1:0] shiftreg_buf_q3;  // Third quarter 
    reg [WIDTH/4-1:0] shiftreg_buf_q4;  // Fourth quarter
    
    // ============ Precomputation signals for shifting ============
    // These will be computed in separate pipeline stages
    reg [WIDTH-1:0] shift_left_result;
    reg [WIDTH-1:0] shift_right_result;
    
    // ============ Pipeline Stage 1: Input Registration ============
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage1 <= 1'b0;
            dir_stage1 <= 1'b0;
            en_stage1 <= 1'b0;
        end
        else begin
            data_in_stage1 <= data_in;
            dir_stage1 <= dir;
            en_stage1 <= en;
        end
    end
    
    // ============ Pipeline Stage 2: Control Signal Propagation ============
    always @(posedge clk) begin
        if (rst) begin
            data_in_stage2 <= 1'b0;
            dir_stage2 <= 1'b0;
            en_stage2 <= 1'b0;
            
            // Precompute both shift directions in parallel
            shift_left_result <= {WIDTH{1'b0}};
            shift_right_result <= {WIDTH{1'b0}};
        end
        else begin
            data_in_stage2 <= data_in_stage1;
            dir_stage2 <= dir_stage1;
            en_stage2 <= en_stage1;
            
            // Precompute both shift directions in parallel to save time in next stage
            shift_left_result <= {shiftreg_stage4[WIDTH-2:0], data_in_stage1};
            shift_right_result <= {data_in_stage1, shiftreg_stage4[WIDTH-1:1]};
        end
    end
    
    // ============ Pipeline Stage 3: Initial Shift Computation ============
    always @(posedge clk) begin
        if (rst)
            shiftreg_stage3 <= {WIDTH{1'b0}};
        else if (en_stage2) begin
            // Use precomputed shift results based on direction
            shiftreg_stage3 <= dir_stage2 ? shift_left_result : shift_right_result;
        end
        else
            shiftreg_stage3 <= shiftreg_stage4; // Maintain current value
    end
    
    // ============ Pipeline Stage 4: Final Shift Computation ============
    always @(posedge clk) begin
        if (rst)
            shiftreg_stage4 <= {WIDTH{1'b0}};
        else
            shiftreg_stage4 <= shiftreg_stage3;
    end
    
    // ============ Pipeline Stage 5: Output Buffering ============
    always @(posedge clk) begin
        if (rst) begin
            shiftreg_buf_q1 <= {(WIDTH/4){1'b0}};
            shiftreg_buf_q2 <= {(WIDTH/4){1'b0}};
            shiftreg_buf_q3 <= {(WIDTH/4){1'b0}};
            shiftreg_buf_q4 <= {(WIDTH/4){1'b0}};
        end
        else begin
            // Split into quarters for better fanout and timing
            shiftreg_buf_q1 <= shiftreg_stage4[WIDTH/4-1:0];
            shiftreg_buf_q2 <= shiftreg_stage4[WIDTH/2-1:WIDTH/4];
            shiftreg_buf_q3 <= shiftreg_stage4[3*WIDTH/4-1:WIDTH/2];
            shiftreg_buf_q4 <= shiftreg_stage4[WIDTH-1:3*WIDTH/4];
        end
    end
    
    // Output assignment using buffered signals with reduced fanout
    assign q_out = {shiftreg_buf_q4, shiftreg_buf_q3, shiftreg_buf_q2, shiftreg_buf_q1};
endmodule