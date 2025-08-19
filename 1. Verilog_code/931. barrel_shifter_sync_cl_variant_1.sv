//SystemVerilog
module barrel_shifter_sync_cl (
    input clk, rst_n, en,
    input [7:0] data_in,
    input [2:0] shift_amount,
    output reg [7:0] data_out
);
    // Pipeline stage 1 registers
    reg [7:0] data_stage1;
    reg [2:0] shift_amount_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] left_shift_stage2;
    reg [7:0] right_shift_stage2;
    reg valid_stage2;
    
    // Stage 1: Register inputs and calculate 8-shift_amount
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 8'b0;
            shift_amount_stage1 <= 3'b0;
            valid_stage1 <= 1'b0;
        end
        else if (en) begin
            data_stage1 <= data_in;
            shift_amount_stage1 <= shift_amount;
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Perform shift operations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_shift_stage2 <= 8'b0;
            right_shift_stage2 <= 8'b0;
            valid_stage2 <= 1'b0;
        end
        else if (valid_stage1) begin
            left_shift_stage2 <= data_stage1 << shift_amount_stage1;
            right_shift_stage2 <= data_stage1 >> (8 - shift_amount_stage1);
            valid_stage2 <= 1'b1;
        end
        else begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Combine shifts and output result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end
        else if (valid_stage2) begin
            data_out <= left_shift_stage2 | right_shift_stage2;
        end
    end
endmodule