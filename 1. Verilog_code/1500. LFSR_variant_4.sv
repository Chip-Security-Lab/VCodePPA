//SystemVerilog
//============================================================================
// Module: lfsr
// Description: Pipelined Linear Feedback Shift Register implementation
// Standard: IEEE 1364-2005
//============================================================================
module lfsr #(parameter [15:0] POLY = 16'h8016) (
    input wire clock,
    input wire reset,
    input wire enable,
    output wire [15:0] lfsr_out,
    output wire sequence_bit,
    output wire valid_out
);
    // Pipeline stage registers
    reg [15:0] lfsr_stage1;
    reg [15:0] lfsr_stage2;
    reg [15:0] lfsr_stage3;
    
    // Valid signals for pipeline control
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;
    
    // Intermediate combinational signals
    wire [15:0] next_lfsr_stage1;
    wire [15:0] next_lfsr_stage2;
    wire [15:0] next_lfsr_stage3;
    wire feedback_stage1;
    wire feedback_stage2;
    
    // Stage 1: Initial calculation
    lfsr_stage1_logic #(.POLY(POLY)) stage1_logic (
        .current_lfsr(lfsr_stage1),
        .next_lfsr(next_lfsr_stage1),
        .feedback(feedback_stage1)
    );
    
    // Stage 2: Intermediate processing
    lfsr_stage2_logic stage2_logic (
        .stage1_lfsr(lfsr_stage1),
        .stage1_feedback(feedback_stage1),
        .next_lfsr(next_lfsr_stage2),
        .feedback(feedback_stage2)
    );
    
    // Stage 3: Final processing
    lfsr_stage3_logic stage3_logic (
        .stage2_lfsr(lfsr_stage2),
        .stage2_feedback(feedback_stage2),
        .next_lfsr(next_lfsr_stage3)
    );
    
    // Pipeline control and stage 1 sequential logic
    always @(posedge clock) begin
        if (reset) begin
            lfsr_stage1 <= 16'h0001;
            valid_stage1 <= 1'b0;
        end
        else if (enable) begin
            lfsr_stage1 <= next_lfsr_stage3;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2 sequential logic
    always @(posedge clock) begin
        if (reset) begin
            lfsr_stage2 <= 16'h0000;
            valid_stage2 <= 1'b0;
        end
        else if (enable) begin
            lfsr_stage2 <= next_lfsr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3 sequential logic
    always @(posedge clock) begin
        if (reset) begin
            lfsr_stage3 <= 16'h0000;
            valid_stage3 <= 1'b0;
        end
        else if (enable) begin
            lfsr_stage3 <= next_lfsr_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignments
    assign lfsr_out = lfsr_stage3;
    assign sequence_bit = lfsr_stage3[15];
    assign valid_out = valid_stage3;
endmodule

//============================================================================
// Module: lfsr_stage1_logic
// Description: Stage 1 combinational logic for LFSR calculation
// Standard: IEEE 1364-2005
//============================================================================
module lfsr_stage1_logic #(parameter [15:0] POLY = 16'h8016) (
    input wire [15:0] current_lfsr,
    output wire [15:0] next_lfsr,
    output wire feedback
);
    // Stage 1: Calculate feedback based on polynomial
    assign feedback = ^(current_lfsr & POLY);
    
    // Prepare next state calculation
    assign next_lfsr = {current_lfsr[14:0], feedback};
endmodule

//============================================================================
// Module: lfsr_stage2_logic
// Description: Stage 2 combinational logic for LFSR calculation
// Standard: IEEE 1364-2005
//============================================================================
module lfsr_stage2_logic (
    input wire [15:0] stage1_lfsr,
    input wire stage1_feedback,
    output wire [15:0] next_lfsr,
    output wire feedback
);
    // Stage 2: Additional LFSR transformations
    // In an actual implementation, could split up operations for better timing
    assign feedback = stage1_lfsr[0] ^ stage1_feedback;
    assign next_lfsr = {stage1_lfsr[14:0], stage1_feedback};
endmodule

//============================================================================
// Module: lfsr_stage3_logic
// Description: Stage 3 combinational logic for LFSR calculation
// Standard: IEEE 1364-2005
//============================================================================
module lfsr_stage3_logic (
    input wire [15:0] stage2_lfsr,
    input wire stage2_feedback,
    output wire [15:0] next_lfsr
);
    // Stage 3: Final LFSR value calculation
    assign next_lfsr = {stage2_lfsr[14:0], stage2_feedback};
endmodule