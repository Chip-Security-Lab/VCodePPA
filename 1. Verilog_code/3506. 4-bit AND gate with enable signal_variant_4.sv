//SystemVerilog
// SystemVerilog - IEEE 1364-2005 standard compliant
module and_gate_4_enable (
    input wire clk,           // Clock signal
    input wire rst_n,         // Active-low reset
    input wire [3:0] a,       // 4-bit input A
    input wire [3:0] b,       // 4-bit input B
    input wire enable,        // Enable signal
    input wire valid_in,      // Input valid signal (added)
    output wire ready_in,     // Ready to accept new input (added)
    output reg [3:0] y,       // 4-bit output Y
    output reg valid_out,     // Output valid signal (added)
    input wire ready_out      // Downstream ready signal (added)
);
    // Pipeline stage signals
    reg [3:0] a_stage1, b_stage1;
    reg enable_stage1;
    reg valid_stage1;
    
    reg [3:0] and_result_stage2;
    reg enable_stage2;
    reg valid_stage2;
    
    // Pipeline control signals
    wire stall_stage2;
    wire stall_stage1;
    
    // Backpressure logic
    assign stall_stage2 = valid_stage2 && !ready_out;
    assign stall_stage1 = valid_stage1 && stall_stage2;
    assign ready_in = !stall_stage1;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 4'b0000;
            b_stage1 <= 4'b0000;
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (!stall_stage1) begin
            a_stage1 <= a;
            b_stage1 <= b;
            enable_stage1 <= enable;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Compute AND operation and register results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_stage2 <= 4'b0000;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (!stall_stage2) begin
            and_result_stage2 <= a_stage1 & b_stage1;
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Apply enable and register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 4'b0000;
            valid_out <= 1'b0;
        end else if (ready_out) begin
            y <= enable_stage2 ? and_result_stage2 : 4'b0000;
            valid_out <= valid_stage2;
        end
    end
    
endmodule