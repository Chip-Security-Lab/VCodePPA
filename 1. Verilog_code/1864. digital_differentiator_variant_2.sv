//SystemVerilog
module digital_differentiator #(parameter WIDTH=8) (
    input clk, rst,
    input valid_in,
    input [WIDTH-1:0] data_in,
    output valid_out,
    output [WIDTH-1:0] data_diff
);
    // Stage 1 - Input registration and delay
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] prev_data_stage1;
    reg valid_stage1;
    
    // Stage 2 - Differentiator computation
    reg [WIDTH-1:0] data_diff_stage2;
    reg valid_stage2;
    
    // Stage 1 logic - Input registration
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_stage1 <= 0;
            prev_data_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            data_stage1 <= data_in;
            prev_data_stage1 <= valid_in ? data_stage1 : prev_data_stage1;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2 logic - Differentiator computation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_diff_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            data_diff_stage2 <= data_stage1 ^ prev_data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignments
    assign data_diff = data_diff_stage2;
    assign valid_out = valid_stage2;
endmodule