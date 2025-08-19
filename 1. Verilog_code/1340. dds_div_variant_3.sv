//SystemVerilog
module dds_div #(parameter FTW=32'h1999_9999) (
    input  wire clk, rst,
    output reg  clk_out
);
    // Split phase accumulator into two pipeline stages for better timing
    reg [15:0] phase_acc_lower_stage1;
    reg [16:0] phase_acc_upper_stage1; // 17 bits to account for carry
    reg [16:0] phase_acc_upper_stage2;
    
    // Pipeline control signals
    reg carry_stage1;
    
    // Stage 1: Lower accumulator bits processing
    always @(posedge clk) begin
        if (rst) begin
            phase_acc_lower_stage1 <= 16'h0000;
            carry_stage1 <= 1'b0;
        end else begin
            // Calculate lower 16 bits and generate carry
            {carry_stage1, phase_acc_lower_stage1} <= phase_acc_lower_stage1 + FTW[15:0];
        end
    end
    
    // Stage 1: Upper accumulator first stage
    always @(posedge clk) begin
        if (rst) begin
            phase_acc_upper_stage1 <= 17'h00000;
        end else begin
            // Prepare upper bits calculation with carry from lower bits
            phase_acc_upper_stage1 <= {1'b0, phase_acc_upper_stage2[15:0]} + {16'h0000, carry_stage1};
        end
    end
    
    // Stage 2: Upper accumulator second stage
    always @(posedge clk) begin
        if (rst) begin
            phase_acc_upper_stage2 <= 17'h00000;
        end else begin
            // Complete upper bits calculation with upper bits of FTW
            phase_acc_upper_stage2 <= phase_acc_upper_stage1 + {1'b0, FTW[31:16]};
        end
    end
    
    // Output stage: Generate output clock
    always @(posedge clk) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else begin
            // Use MSB of upper accumulator as output clock
            clk_out <= phase_acc_upper_stage2[16];
        end
    end
    
endmodule