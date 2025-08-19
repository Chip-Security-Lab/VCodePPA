//SystemVerilog
module sync_rotate_right_shifter (
    input              clk_i,
    input              arst_n,  // Active low async reset
    input              valid_i,  // Input data valid signal
    output             ready_o,  // Ready to accept new input
    input      [31:0]  data_i,
    input      [4:0]   shift_i,
    output reg [31:0]  data_o,
    output reg         valid_o   // Output data valid signal
);
    // Pipeline stage registers
    reg [31:0] data_stage1;
    reg [4:0]  shift_stage1;
    reg        valid_stage1;
    
    reg [31:0] data_stage2;
    reg [4:0]  shift_stage2;
    reg        valid_stage2;
    
    // Intermediate calculation results
    wire [31:0] rotated_stage1;
    wire [31:0] rotated_stage2;
    wire [63:0] concat_data;
    
    // Pipeline always ready in this implementation
    assign ready_o = 1'b1;
    
    // Stage 1: Store input data and concatenate for rotation
    assign concat_data = {data_stage1, data_stage1};
    
    // Stage 2: Perform first half of shift operation
    assign rotated_stage1 = concat_data[31:0] >> (shift_stage1 < 5'd16 ? shift_stage1 : 5'd0);
    
    // Stage 3: Perform second half of shift operation
    assign rotated_stage2 = concat_data[63:32] >> (shift_stage2 >= 5'd16 ? shift_stage2 - 5'd16 : 5'd0);
    
    // Pipeline Stage 1: Register inputs
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_stage1 <= 32'h0;
            shift_stage1 <= 5'h0;
            valid_stage1 <= 1'b0;
        end
        else begin
            data_stage1 <= data_i;
            shift_stage1 <= shift_i;
            valid_stage1 <= valid_i;
        end
    end
    
    // Pipeline Stage 2: Register intermediate results
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_stage2 <= 32'h0;
            shift_stage2 <= 5'h0;
            valid_stage2 <= 1'b0;
        end
        else begin
            data_stage2 <= data_stage1;
            shift_stage2 <= shift_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Pipeline Stage 3: Final output
    always @(posedge clk_i or negedge arst_n) begin
        if (!arst_n) begin
            data_o <= 32'h0;
            valid_o <= 1'b0;
        end
        else begin
            if (shift_stage2 < 5'd16) begin
                data_o <= rotated_stage1;
            end
            else begin
                data_o <= rotated_stage2;
            end
            valid_o <= valid_stage2;
        end
    end
endmodule