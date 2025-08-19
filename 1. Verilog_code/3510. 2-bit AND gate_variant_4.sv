//SystemVerilog
// SystemVerilog (IEEE 1364-2005)
// 2-bit AND gate with enhanced pipelined architecture using case structure
module and_gate_2bit (
    input wire clk,               // System clock
    input wire rst_n,             // Active low reset
    input wire valid_in,          // Input valid signal
    output wire ready_in,         // Ready to accept input
    input wire [1:0] a,           // 2-bit input A
    input wire [1:0] b,           // 2-bit input B
    output reg [1:0] y,           // 2-bit output Y (registered)
    output reg valid_out,         // Output valid signal
    input wire ready_out          // Downstream ready signal
);
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    reg [1:0] a_stage1, b_stage1;    // First pipeline stage registers
    reg [1:0] and_result;            // Intermediate result
    
    // Pipeline flow control
    wire stall_pipeline = valid_out && !ready_out;
    assign ready_in = !stall_pipeline;
    
    // Control signal for case statements
    reg [1:0] pipe_ctrl;
    
    // Define control signals for case statement
    always @(*) begin
        pipe_ctrl[0] = rst_n;
        pipe_ctrl[1] = stall_pipeline;
    end
    
    // Stage 1: Input registration and validation
    always @(posedge clk) begin
        case(pipe_ctrl)
            2'b00: begin  // !rst_n
                a_stage1 <= 2'b00;
                b_stage1 <= 2'b00;
                valid_stage1 <= 1'b0;
            end
            2'b01: begin  // !rst_n && stall_pipeline (shouldn't occur but included for completeness)
                a_stage1 <= 2'b00;
                b_stage1 <= 2'b00;
                valid_stage1 <= 1'b0;
            end
            2'b10: begin  // rst_n && !stall_pipeline
                a_stage1 <= a;
                b_stage1 <= b;
                valid_stage1 <= valid_in;
            end
            2'b11: begin  // rst_n && stall_pipeline
                a_stage1 <= a_stage1;
                b_stage1 <= b_stage1;
                valid_stage1 <= valid_stage1;
            end
        endcase
    end
    
    // Stage 2: Operation execution (perform bitwise AND)
    always @(posedge clk) begin
        case(pipe_ctrl)
            2'b00: begin  // !rst_n
                and_result <= 2'b00;
                valid_stage2 <= 1'b0;
            end
            2'b01: begin  // !rst_n && stall_pipeline (shouldn't occur but included for completeness)
                and_result <= 2'b00;
                valid_stage2 <= 1'b0;
            end
            2'b10: begin  // rst_n && !stall_pipeline
                and_result <= a_stage1 & b_stage1;
                valid_stage2 <= valid_stage1;
            end
            2'b11: begin  // rst_n && stall_pipeline
                and_result <= and_result;
                valid_stage2 <= valid_stage2;
            end
        endcase
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        case(pipe_ctrl)
            2'b00: begin  // !rst_n
                y <= 2'b00;
                valid_out <= 1'b0;
            end
            2'b01: begin  // !rst_n && stall_pipeline (shouldn't occur but included for completeness)
                y <= 2'b00;
                valid_out <= 1'b0;
            end
            2'b10: begin  // rst_n && !stall_pipeline
                y <= and_result;
                valid_out <= valid_stage2;
            end
            2'b11: begin  // rst_n && stall_pipeline
                y <= y;
                valid_out <= valid_out;
            end
        endcase
    end
    
endmodule