//SystemVerilog
module ResetMultiplier(
    input clk, rst,
    input [3:0] x, y,
    output reg [7:0] out
);
    // Pipeline registers
    reg [3:0] x_stage1, y_stage1;
    reg [7:0] partial_prod_stage2;
    reg valid_stage1, valid_stage2;
    
    // Shift-and-add multiplier signals
    reg [7:0] acc_stage2;
    reg [3:0] multiplier_stage2;
    reg [2:0] bit_counter_stage2;
    reg mult_done_stage2;
    
    // Stage 1: Input register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_stage1 <= 4'b0;
            y_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            x_stage1 <= x;
            y_stage1 <= y;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Shift-and-add multiplication
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc_stage2 <= 8'b0;
            multiplier_stage2 <= 4'b0;
            bit_counter_stage2 <= 3'b0;
            mult_done_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // Initialize shift-and-add multiplication
                acc_stage2 <= 8'b0;
                multiplier_stage2 <= y_stage1;
                bit_counter_stage2 <= 3'b0;
                mult_done_stage2 <= 1'b0;
                valid_stage2 <= 1'b1;
            end else if (valid_stage2 && !mult_done_stage2) begin
                // Shift-and-add algorithm
                if (multiplier_stage2[0]) begin
                    acc_stage2 <= acc_stage2 + (x_stage1 << bit_counter_stage2);
                end
                multiplier_stage2 <= multiplier_stage2 >> 1;
                bit_counter_stage2 <= bit_counter_stage2 + 1;
                
                // Check if multiplication is complete
                if (bit_counter_stage2 == 3'b100) begin
                    mult_done_stage2 <= 1'b1;
                end
            end
        end
    end
    
    // Stage 3: Output register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            out <= 8'b0;
        end else if (valid_stage2 && mult_done_stage2) begin
            out <= acc_stage2;
        end
    end
endmodule