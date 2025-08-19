//SystemVerilog
module sync_rotate_right_shifter (
    input              clk_i,
    input              arst_n,  // Active low async reset
    input              valid_i,
    input      [31:0]  data_i,
    input      [4:0]   shift_i,
    output             valid_o,
    output     [31:0]  data_o,
    input              ready_i,
    output             ready_o
);
    // Pipeline stage 1 registers
    reg [31:0] data_stage1;
    reg [4:0]  shift_stage1;
    reg        valid_stage1;
    
    // Pipeline stage 2 registers
    reg [31:0] data_o_reg;
    reg        valid_stage2;
    
    // Intermediate signals for stage 1
    wire [63:0] combined_data = {data_i, data_i};
    
    // Intermediate signals for stage 2
    wire [31:0] rotated;
    assign rotated = combined_data[shift_stage1 +: 32];
    
    // Ready signal propagation - backpressure logic
    assign ready_o = ~valid_stage1 || (valid_stage1 && ready_i);
    
    // Stage 1: Register input data and shift amount
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_stage1 <= 32'h0;
            shift_stage1 <= 5'h0;
            valid_stage1 <= 1'b0;
        end else if (ready_o) begin
            data_stage1 <= data_i;
            shift_stage1 <= shift_i;
            valid_stage1 <= valid_i;
        end
    end
    
    // Stage 2: Compute and register the shifted result
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_o_reg <= 32'h0;
            valid_stage2 <= 1'b0;
        end else if (ready_i || ~valid_stage2) begin
            data_o_reg <= rotated;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignments
    assign data_o = data_o_reg;
    assign valid_o = valid_stage2;
    
endmodule