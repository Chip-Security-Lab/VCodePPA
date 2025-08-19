//SystemVerilog
module bcd_counter (
    input clock, clear_n,
    output reg [3:0] bcd,
    output reg carry
);
    // Stage 1: Comparison logic
    reg is_nine_stage1;
    reg [3:0] bcd_stage1;
    
    // Stage 2: Intermediate computation
    reg is_nine_stage2;
    reg [3:0] next_bcd_stage2;
    
    // Stage 3: Final output preparation
    reg [3:0] next_bcd_stage3;
    reg carry_stage3;
    
    // Stage 1: Detect if current value is 9 or 8
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            is_nine_stage1 <= 1'b0;
            bcd_stage1 <= 4'd0;
        end else begin
            is_nine_stage1 <= (bcd == 4'd9);
            bcd_stage1 <= bcd;
        end
    end
    
    // Stage 2: Compute next BCD value
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            is_nine_stage2 <= 1'b0;
            next_bcd_stage2 <= 4'd0;
        end else begin
            is_nine_stage2 <= is_nine_stage1;
            next_bcd_stage2 <= is_nine_stage1 ? 4'd0 : bcd_stage1 + 1'b1;
        end
    end
    
    // Stage 3: Prepare final outputs
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            next_bcd_stage3 <= 4'd0;
            carry_stage3 <= 1'b0;
        end else begin
            next_bcd_stage3 <= next_bcd_stage2;
            carry_stage3 <= is_nine_stage2;
        end
    end
    
    // Final output registers
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            bcd <= 4'd0;
            carry <= 1'b0;
        end else begin
            bcd <= next_bcd_stage3;
            carry <= carry_stage3;
        end
    end
endmodule