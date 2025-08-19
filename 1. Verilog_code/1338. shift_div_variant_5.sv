//SystemVerilog
module shift_div #(
    parameter PATTERN = 8'b1010_1100
) (
    input  wire       clk,
    input  wire       rst,
    output wire       clk_out
);
    // Main shift register stages - split into smaller stages for better timing
    reg [1:0] shift_stage1;    // First stage (bits 0-1)
    reg [1:0] shift_stage2;    // Second stage (bits 2-3)
    reg [1:0] shift_stage3;    // Third stage (bits 4-5)
    reg [1:0] shift_stage4;    // Fourth stage (bits 6-7)
    
    // Inter-stage pipeline registers
    reg       stage1_to_stage2_reg;  // Pipeline between stage 1 and 2
    reg       stage2_to_stage3_reg;  // Pipeline between stage 2 and 3
    reg       stage3_to_stage4_reg;  // Pipeline between stage 3 and 4
    reg       feedback_stage4_to_stage1_reg; // Feedback from stage 4 to stage 1
    
    // Output pipeline registers (multiple stages for better timing)
    reg       output_stage1_reg;
    reg       output_final_reg;
    
    // Output assignment through deeply pipelined path
    assign clk_out = output_final_reg;
    
    // Stage 1 shift register logic (bits 0-1)
    always @(posedge clk) begin
        if (rst) begin
            shift_stage1 <= PATTERN[1:0];
        end else begin
            shift_stage1 <= {shift_stage1[0], feedback_stage4_to_stage1_reg};
        end
    end
    
    // Pipeline register between stage 1 and 2
    always @(posedge clk) begin
        if (rst) begin
            stage1_to_stage2_reg <= PATTERN[2];
        end else begin
            stage1_to_stage2_reg <= shift_stage1[1];
        end
    end
    
    // Stage 2 shift register logic (bits 2-3)
    always @(posedge clk) begin
        if (rst) begin
            shift_stage2 <= PATTERN[3:2];
        end else begin
            shift_stage2 <= {shift_stage2[0], stage1_to_stage2_reg};
        end
    end
    
    // Pipeline register between stage 2 and 3
    always @(posedge clk) begin
        if (rst) begin
            stage2_to_stage3_reg <= PATTERN[4];
        end else begin
            stage2_to_stage3_reg <= shift_stage2[1];
        end
    end
    
    // Stage 3 shift register logic (bits 4-5)
    always @(posedge clk) begin
        if (rst) begin
            shift_stage3 <= PATTERN[5:4];
        end else begin
            shift_stage3 <= {shift_stage3[0], stage2_to_stage3_reg};
        end
    end
    
    // Pipeline register between stage 3 and 4
    always @(posedge clk) begin
        if (rst) begin
            stage3_to_stage4_reg <= PATTERN[6];
        end else begin
            stage3_to_stage4_reg <= shift_stage3[1];
        end
    end
    
    // Stage 4 shift register logic (bits 6-7)
    always @(posedge clk) begin
        if (rst) begin
            shift_stage4 <= PATTERN[7:6];
        end else begin
            shift_stage4 <= {shift_stage4[0], stage3_to_stage4_reg};
        end
    end
    
    // Feedback path from stage 4 to stage 1 with pipeline register
    always @(posedge clk) begin
        if (rst) begin
            feedback_stage4_to_stage1_reg <= PATTERN[0];
        end else begin
            feedback_stage4_to_stage1_reg <= shift_stage4[1];
        end
    end
    
    // First stage of output registration
    always @(posedge clk) begin
        if (rst) begin
            output_stage1_reg <= PATTERN[7];
        end else begin
            output_stage1_reg <= shift_stage4[1];
        end
    end
    
    // Final stage of output registration
    always @(posedge clk) begin
        if (rst) begin
            output_final_reg <= PATTERN[7];
        end else begin
            output_final_reg <= output_stage1_reg;
        end
    end
endmodule