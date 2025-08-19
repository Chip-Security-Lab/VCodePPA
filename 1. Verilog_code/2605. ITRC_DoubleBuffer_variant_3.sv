//SystemVerilog
module ITRC_DoubleBuffer #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] raw_status,
    output [WIDTH-1:0] stable_status
);
    // Pipeline stage registers
    reg [WIDTH-1:0] buf1_stage1, buf2_stage1;
    reg [WIDTH-1:0] buf1_stage2, buf2_stage2;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    
    // LUT-based subtraction logic
    reg [WIDTH-1:0] sub_result;
    reg [WIDTH-1:0] lut [0:255];
    
    // Initialize LUT
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            lut[i] = i;
        end
    end
    
    // Stage 1: First buffer update with LUT-based subtraction
    always @(posedge clk) begin
        if (!rst_n) begin
            buf1_stage1 <= 0;
            valid_stage1 <= 0;
            sub_result <= 0;
        end else begin
            sub_result <= lut[raw_status[7:0]];
            buf1_stage1 <= {raw_status[WIDTH-1:8], sub_result[7:0]};
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Second buffer update
    always @(posedge clk) begin
        if (!rst_n) begin
            buf2_stage1 <= 0;
            valid_stage2 <= 0;
        end else if (valid_stage1) begin
            buf2_stage1 <= buf1_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Final output
    always @(posedge clk) begin
        if (!rst_n) begin
            buf2_stage2 <= 0;
        end else if (valid_stage2) begin
            buf2_stage2 <= buf2_stage1;
        end
    end
    
    assign stable_status = buf2_stage2;
endmodule