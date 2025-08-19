//SystemVerilog
module param_equality_comparator #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire enable,
    input wire [DATA_WIDTH-1:0] data_in_a,
    input wire [DATA_WIDTH-1:0] data_in_b,
    output reg match_flag,
    output reg valid_out
);
    // Pipeline stage registers
    reg [DATA_WIDTH-1:0] data_a_stage1;
    reg [DATA_WIDTH-1:0] data_b_stage1;
    reg enable_stage1;
    
    // Subtractor signals
    reg [DATA_WIDTH-1:0] subtraction_result;
    reg [DATA_WIDTH-1:0] inverted_b;
    reg [DATA_WIDTH:0] sub_result_with_carry;
    reg sub_zero_flag;
    
    // Pipeline valid signals
    reg valid_stage1;
    reg valid_stage2;
    reg enable_stage2;
    
    // Stage 1: Register inputs
    always @(posedge clock) begin
        if (reset) begin
            data_a_stage1 <= {DATA_WIDTH{1'b0}};
            data_b_stage1 <= {DATA_WIDTH{1'b0}};
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_a_stage1 <= data_in_a;
            data_b_stage1 <= data_in_b;
            enable_stage1 <= enable;
            valid_stage1 <= enable;
        end
    end
    
    // Stage 2: Implement conditional inverse subtractor
    always @(posedge clock) begin
        if (reset) begin
            subtraction_result <= {DATA_WIDTH{1'b0}};
            sub_zero_flag <= 1'b0;
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // Conditional inverse subtractor implementation
            inverted_b = ~data_b_stage1;
            sub_result_with_carry = data_a_stage1 + inverted_b + 1'b1; // A - B = A + (~B) + 1
            subtraction_result <= sub_result_with_carry[DATA_WIDTH-1:0];
            
            // Check if result is zero (meaning A == B)
            sub_zero_flag <= (sub_result_with_carry[DATA_WIDTH-1:0] == {DATA_WIDTH{1'b0}});
            
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Generate final output
    always @(posedge clock) begin
        if (reset) begin
            match_flag <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            // Final output stage
            if (enable_stage2) begin
                match_flag <= sub_zero_flag;
            end
            
            valid_out <= valid_stage2;
        end
    end
endmodule