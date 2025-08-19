//SystemVerilog
module dff_dual_edge (
    input  wire clk,      // System clock
    input  wire rstn,     // Active low reset
    input  wire d,        // Data input
    input  wire valid_in, // Input valid signal
    output wire q,        // Data output
    output wire valid_out // Output valid signal
);

    // ===== Input Capture Stage =====
    reg d_captured;       // Captured input data
    reg valid_captured;   // Captured valid signal

    // ===== Positive Edge Pipeline Registers =====
    reg d_pos_pipe1;      // Positive edge pipeline stage 1
    reg d_pos_pipe2;      // Positive edge pipeline stage 2
    reg valid_pos_pipe1;  // Valid signal for positive edge pipeline

    // ===== Negative Edge Pipeline Registers =====
    reg d_neg_pipe1;      // Negative edge pipeline stage 1
    reg d_neg_pipe2;      // Negative edge pipeline stage 2
    reg valid_neg_pipe;   // Valid signal for negative edge pipeline

    // ===== DATA FLOW PATH 1: Input Capture =====
    // Synchronize input data to posedge clock
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            d_captured     <= 1'b0;
            valid_captured <= 1'b0;
        end else begin
            d_captured     <= d;
            valid_captured <= valid_in;
        end
    end

    // ===== DATA FLOW PATH 2: Positive Edge Pipeline =====
    // Process data on positive clock edge
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            d_pos_pipe1    <= 1'b0;
            d_pos_pipe2    <= 1'b0;
            valid_pos_pipe1 <= 1'b0;
        end else begin
            // First stage
            d_pos_pipe1    <= d_captured;
            // Second stage
            d_pos_pipe2    <= d_pos_pipe1;
            // Valid signal propagation
            valid_pos_pipe1 <= valid_captured;
        end
    end

    // ===== DATA FLOW PATH 3: Negative Edge Pipeline =====
    // Process data on negative clock edge
    always @(negedge clk or negedge rstn) begin
        if (!rstn) begin
            d_neg_pipe1   <= 1'b0;
            d_neg_pipe2   <= 1'b0;
            valid_neg_pipe <= 1'b0;
        end else begin
            // First stage
            d_neg_pipe1   <= d_captured;
            // Second stage
            d_neg_pipe2   <= d_neg_pipe1;
            // Valid signal propagation
            valid_neg_pipe <= valid_pos_pipe1;
        end
    end

    // ===== OUTPUT STAGE: Path Selection =====
    // Multiplex between positive and negative edge paths based on clock state
    assign q = clk ? d_pos_pipe2 : d_neg_pipe2;
    
    // Output valid signal (from negative edge pipeline)
    assign valid_out = valid_neg_pipe;

endmodule