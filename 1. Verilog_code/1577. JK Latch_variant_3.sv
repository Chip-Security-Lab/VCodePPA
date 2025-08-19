//SystemVerilog
module jk_latch_pipelined (
    input wire clk,
    input wire rst_n,
    input wire j,
    input wire k,
    input wire enable,
    output reg q
);
    // Pipeline stage 1 registers
    reg [1:0] jk_state_stage1;
    reg [7:0] shift_reg_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] result_stage2;
    reg [2:0] count_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] result_stage3;
    reg valid_stage3;
    
    // Stage 1: JK state and shift register initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            jk_state_stage1 <= 2'b0;
            shift_reg_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else if (enable) begin
            jk_state_stage1 <= {j, k};
            shift_reg_stage1 <= {6'b0, j, k};
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Shift and add operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage2 <= 8'b0;
            count_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            if (shift_reg_stage1[0]) begin
                result_stage2 <= result_stage2 + (8'b1 << count_stage2);
            end
            count_stage2 <= count_stage2 + 1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Final result and JK latch update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_stage3 <= 8'b0;
            valid_stage3 <= 1'b0;
            q <= 1'b0;
        end else if (valid_stage2) begin
            result_stage3 <= result_stage2;
            valid_stage3 <= 1'b1;
            
            case (jk_state_stage1)
                2'b00: q <= q;     // Hold
                2'b01: q <= 1'b0;  // Reset
                2'b10: q <= 1'b1;  // Set
                2'b11: q <= ~q;    // Toggle
            endcase
        end else begin
            valid_stage3 <= 1'b0;
        end
    end
endmodule