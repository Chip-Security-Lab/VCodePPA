//SystemVerilog
module clk_gate_dff (
    input      clk,    // Main clock input
    input      rst,    // Reset signal (added)
    input      en,     // Clock enable signal
    input      d,      // Data input
    output reg q,      // Data output
    input      valid_in,   // Input data valid signal
    output     valid_out,  // Output data valid signal
    input      ready_in,   // Downstream ready signal
    output     ready_out   // Upstream ready signal
);

    // Pipeline stage registers
    reg en_latch;            // Latched enable signal to prevent glitches
    reg d_stage1, d_stage2;  // Pipeline stage data registers
    reg valid_stage1, valid_stage2; // Valid signals for pipeline stages
    
    wire gated_clk;          // Generated glitch-free gated clock
    
    // Pipeline flow control
    assign ready_out = ready_in;  // Ready signal propagation
    assign valid_out = valid_stage2; // Final stage valid signal

    // Latch enable signal on negative edge to prevent glitches - Stage 1
    always @(negedge clk or posedge rst) begin
        if (rst) 
            en_latch <= 1'b0;
        else if (en)
            en_latch <= 1'b1;
        else
            en_latch <= en;
    end

    // Generate glitch-free gated clock using AND operation
    assign gated_clk = clk & en_latch;

    // Pipeline stage 1: Input capture and initial processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            d_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end
        else if (ready_in) begin
            d_stage1 <= d;
            valid_stage1 <= valid_in;
        end
    end

    // Pipeline stage 2: Middle processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            d_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end
        else if (ready_in) begin
            d_stage2 <= d_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3: Output register with gated clock
    always @(posedge gated_clk or posedge rst) begin
        if (rst)
            q <= 1'b0;
        else if (ready_in && valid_stage2)
            q <= d_stage2;
    end

endmodule