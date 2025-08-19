//SystemVerilog
module latch_dff (
    input  logic clk,
    input  logic rst_n,  // Added reset for proper pipeline control
    input  logic en,
    input  logic d,
    input  logic valid_in,  // Input valid signal
    output logic ready_in,  // Ready to accept new input
    output logic valid_out, // Output valid signal
    output logic q
);
    // Pipeline stage signals
    logic latch_out_stage1;
    logic valid_stage1;
    
    // Stage 1: Latch stage with valid signal
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latch_out_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            if (en && ready_in) begin
                latch_out_stage1 <= d;
                valid_stage1 <= valid_in;
            end
        end
    end
    
    // Stage 2: Flip-flop stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            q <= latch_out_stage1;
            valid_out <= valid_stage1;
        end
    end
    
    // Backpressure mechanism
    assign ready_in = 1'b1; // Always ready in this simple pipeline
    
endmodule