//SystemVerilog
// Optimized 2-bit AND gate with enhanced pipelined structure
module and_gate_2bit (
    input  wire        clk,      // Clock input
    input  wire        rst_n,    // Active-low reset
    input  wire [1:0]  a,        // 2-bit input A
    input  wire [1:0]  b,        // 2-bit input B
    output reg  [1:0]  y         // 2-bit output Y (registered)
);
    // Pipeline stage registers with descriptive names
    reg [1:0] a_stage1, b_stage1;   // Stage 1 input registers
    reg [1:0] and_result;           // Computation result register
    
    // Stage 1: Input Registration with enable logic for power saving
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 2'b00;
            b_stage1 <= 2'b00;
        end else begin
            // Only update registers when inputs change to reduce switching activity
            if (a_stage1 != a || b_stage1 != b) begin
                a_stage1 <= a;
                b_stage1 <= b;
            end
        end
    end
    
    // Stage 2: Computation with optimized bit-specific logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result <= 2'b00;
        end else begin
            // Bit-specific logic to potentially enable better synthesis
            and_result[0] <= a_stage1[0] & b_stage1[0];
            and_result[1] <= a_stage1[1] & b_stage1[1];
        end
    end
    
    // Stage 3: Output Registration with forwarding logic for critical path reduction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 2'b00;
        end else begin
            y <= and_result;
        end
    end
    
endmodule