//SystemVerilog
module seq_generator(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [3:0] pattern,
    input wire load_pattern,
    output reg seq_out
);

    // Stage 1 registers
    reg [3:0] state_reg_stage1;
    reg [3:0] pattern_reg_stage1;
    reg enable_stage1;
    reg load_pattern_stage1;
    reg [3:0] pattern_stage1;
    
    // Stage 2 registers
    reg [3:0] state_reg_stage2;
    reg [3:0] pattern_reg_stage2;
    reg enable_stage2;
    reg [3:0] state_decode_stage2;
    
    // Stage 3 registers
    reg [3:0] state_reg_stage3;
    reg [3:0] pattern_reg_stage3;
    reg pattern_bit_stage3;
    
    // Stage 1 logic
    wire [3:0] next_state_stage1;
    wire [3:0] next_pattern_stage1;
    
    assign next_state_stage1 = (state_reg_stage1 == 4'd3) ? 4'd0 : state_reg_stage1 + 4'd1;
    assign next_pattern_stage1 = load_pattern_stage1 ? pattern_stage1 : pattern_reg_stage1;
    
    // Stage 2 logic
    wire [3:0] state_decode_stage2_wire;
    assign state_decode_stage2_wire = 4'b0001 << state_reg_stage2;
    
    // Stage 3 logic
    wire pattern_bit_stage3_wire;
    assign pattern_bit_stage3_wire = |(state_decode_stage2 & pattern_reg_stage3);
    
    // Stage 1 pipeline register
    always @(posedge clk) begin
        if (rst) begin
            state_reg_stage1 <= 4'd0;
            pattern_reg_stage1 <= 4'b0101;
            enable_stage1 <= 1'b0;
            load_pattern_stage1 <= 1'b0;
            pattern_stage1 <= 4'b0;
        end else begin
            state_reg_stage1 <= next_state_stage1;
            pattern_reg_stage1 <= next_pattern_stage1;
            enable_stage1 <= enable;
            load_pattern_stage1 <= load_pattern;
            pattern_stage1 <= pattern;
        end
    end
    
    // Stage 2 pipeline register
    always @(posedge clk) begin
        if (rst) begin
            state_reg_stage2 <= 4'd0;
            pattern_reg_stage2 <= 4'b0101;
            enable_stage2 <= 1'b0;
            state_decode_stage2 <= 4'b0;
        end else begin
            state_reg_stage2 <= state_reg_stage1;
            pattern_reg_stage2 <= pattern_reg_stage1;
            enable_stage2 <= enable_stage1;
            state_decode_stage2 <= state_decode_stage2_wire;
        end
    end
    
    // Stage 3 pipeline register
    always @(posedge clk) begin
        if (rst) begin
            state_reg_stage3 <= 4'd0;
            pattern_reg_stage3 <= 4'b0101;
            pattern_bit_stage3 <= 1'b0;
        end else begin
            state_reg_stage3 <= state_reg_stage2;
            pattern_reg_stage3 <= pattern_reg_stage2;
            pattern_bit_stage3 <= pattern_bit_stage3_wire;
        end
    end
    
    // Output register
    always @(posedge clk) begin
        if (rst) begin
            seq_out <= 1'b0;
        end else begin
            seq_out <= pattern_bit_stage3;
        end
    end

endmodule