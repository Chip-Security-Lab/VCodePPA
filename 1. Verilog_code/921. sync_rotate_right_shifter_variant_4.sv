//SystemVerilog
module sync_rotate_right_shifter (
    input             clk_i,
    input             arst_n,  // Active low async reset
    input      [31:0] data_i,
    input      [4:0]  shift_i,
    output reg [31:0] data_o
);
    // Pipeline stage registers
    reg [31:0] data_stage1;
    reg [4:0]  shift_stage1;
    reg [31:0] data_stage2;
    reg [4:0]  shift_stage2;
    reg [31:0] rotated_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_stage1  <= 32'h0;
            shift_stage1 <= 5'h0;
        end else begin
            data_stage1  <= data_i;
            shift_stage1 <= shift_i;
        end
    end
    
    // Stage 2: Prepare data for rotation
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_stage2  <= 32'h0;
            shift_stage2 <= 5'h0;
        end else begin
            data_stage2  <= data_stage1;
            shift_stage2 <= shift_stage1;
        end
    end
    
    // Stage 3: Perform rotation calculation
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            rotated_stage3 <= 32'h0;
        end else begin
            rotated_stage3 <= {data_stage2, data_stage2} >> shift_stage2;
        end
    end
    
    // Stage 4: Final output
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_o <= 32'h0;
        end else begin
            data_o <= rotated_stage3;
        end
    end
endmodule