//SystemVerilog
module universal_shifter (
    input wire clk, rst,
    input wire [1:0] mode, // 00:hold, 01:shift right, 10:shift left, 11:load
    input wire [3:0] parallel_in,
    input wire left_in, right_in,
    output wire [3:0] q,
    // Pipeline control signals
    input wire valid_in,
    output wire ready_in,
    output wire valid_out,
    input wire ready_out
);
    // Pipeline stage registers
    reg [3:0] q_stage1, q_stage2, q_stage3;
    reg [1:0] mode_stage1, mode_stage2;
    reg right_in_stage1, left_in_stage1;
    reg [3:0] parallel_in_stage1;
    
    // Pipeline control registers
    reg valid_stage1, valid_stage2, valid_stage3;
    wire stall;
    
    // Backpressure logic
    assign stall = valid_out && !ready_out;
    assign ready_in = !stall;
    assign valid_out = valid_stage3;
    
    // Stage 1: Input registration and mode decoding
    always @(posedge clk) begin
        if (rst) begin
            mode_stage1 <= 2'b00;
            q_stage1 <= 4'b0000;
            right_in_stage1 <= 1'b0;
            left_in_stage1 <= 1'b0;
            parallel_in_stage1 <= 4'b0000;
            valid_stage1 <= 1'b0;
        end
        else if (!stall) begin
            mode_stage1 <= mode;
            q_stage1 <= q_stage3; // Feedback for hold operation
            right_in_stage1 <= right_in;
            left_in_stage1 <= left_in;
            parallel_in_stage1 <= parallel_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Operation execution
    always @(posedge clk) begin
        if (rst) begin
            q_stage2 <= 4'b0000;
            mode_stage2 <= 2'b00;
            valid_stage2 <= 1'b0;
        end
        else if (!stall) begin
            mode_stage2 <= mode_stage1;
            valid_stage2 <= valid_stage1;
            
            case (mode_stage1)
                2'b00: q_stage2 <= q_stage1;                      // Hold
                2'b01: q_stage2 <= {right_in_stage1, q_stage1[3:1]}; // Shift right
                2'b10: q_stage2 <= {q_stage1[2:0], left_in_stage1};  // Shift left
                2'b11: q_stage2 <= parallel_in_stage1;            // Parallel load
            endcase
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (rst) begin
            q_stage3 <= 4'b0000;
            valid_stage3 <= 1'b0;
        end
        else if (!stall) begin
            q_stage3 <= q_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign q = q_stage3;
    
endmodule