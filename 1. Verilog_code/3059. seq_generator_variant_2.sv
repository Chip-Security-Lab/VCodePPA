//SystemVerilog
module seq_generator(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [3:0] pattern,
    input wire load_pattern,
    output reg seq_out
);

    // Pipeline stage registers
    reg [3:0] pattern_reg_stage1;
    reg [3:0] current_state_stage1;
    reg enable_stage1;
    reg load_pattern_stage1;
    
    reg [3:0] pattern_reg_stage2;
    reg [3:0] current_state_stage2;
    reg enable_stage2;
    
    reg [3:0] pattern_reg_stage3;
    reg [3:0] current_state_stage3;
    reg enable_stage3;
    
    reg [3:0] pattern_reg_stage4;
    reg [3:0] current_state_stage4;
    reg enable_stage4;
    
    // Next state calculation for each stage
    reg [3:0] next_state_stage1;
    reg [3:0] next_state_stage2;
    reg [3:0] next_state_stage3;
    reg [3:0] next_state_stage4;
    
    // Pipeline stage 1: Input and state transition
    always @(posedge clk) begin
        if (rst) begin
            pattern_reg_stage1 <= 4'b0101;
            current_state_stage1 <= 4'd0;
            enable_stage1 <= 1'b0;
            load_pattern_stage1 <= 1'b0;
        end else begin
            pattern_reg_stage1 <= load_pattern ? pattern : pattern_reg_stage1;
            current_state_stage1 <= next_state_stage1;
            enable_stage1 <= enable;
            load_pattern_stage1 <= load_pattern;
        end
    end
    
    always @(*) begin
        if (enable) begin
            next_state_stage1 = (current_state_stage1 == 4'd3) ? 4'd0 : (current_state_stage1 + 4'd1);
        end else begin
            next_state_stage1 = current_state_stage1;
        end
    end
    
    // Pipeline stage 2: Forward state and pattern
    always @(posedge clk) begin
        if (rst) begin
            pattern_reg_stage2 <= 4'b0101;
            current_state_stage2 <= 4'd0;
            enable_stage2 <= 1'b0;
        end else begin
            pattern_reg_stage2 <= pattern_reg_stage1;
            current_state_stage2 <= current_state_stage1;
            enable_stage2 <= enable_stage1;
        end
    end
    
    // Pipeline stage 3: Forward state and pattern
    always @(posedge clk) begin
        if (rst) begin
            pattern_reg_stage3 <= 4'b0101;
            current_state_stage3 <= 4'd0;
            enable_stage3 <= 1'b0;
        end else begin
            pattern_reg_stage3 <= pattern_reg_stage2;
            current_state_stage3 <= current_state_stage2;
            enable_stage3 <= enable_stage2;
        end
    end
    
    // Pipeline stage 4: Output generation
    always @(posedge clk) begin
        if (rst) begin
            pattern_reg_stage4 <= 4'b0101;
            current_state_stage4 <= 4'd0;
            enable_stage4 <= 1'b0;
            seq_out <= 1'b0;
        end else begin
            pattern_reg_stage4 <= pattern_reg_stage3;
            current_state_stage4 <= current_state_stage3;
            enable_stage4 <= enable_stage3;
            
            // Output generation logic
            case (current_state_stage4)
                4'd0: seq_out <= pattern_reg_stage4[0];
                4'd1: seq_out <= pattern_reg_stage4[1];
                4'd2: seq_out <= pattern_reg_stage4[2];
                4'd3: seq_out <= pattern_reg_stage4[3];
                default: seq_out <= 1'b0;
            endcase
        end
    end

endmodule