//SystemVerilog
module GrayLatch #(parameter DW=4) (
    input clk,
    input rst_n,
    input en,
    input [DW-1:0] bin_in,
    output [DW-1:0] gray_out
);

    // Stage 1: Binary to Gray conversion
    wire [DW-1:0] gray_next;
    reg [DW-1:0] bin_stage1;
    reg valid_stage1;
    
    assign gray_next = bin_stage1 ^ (bin_stage1 >> 1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_stage1 <= {DW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            bin_stage1 <= bin_in;
            valid_stage1 <= en;
        end
    end

    // Stage 2: Output register
    reg [DW-1:0] gray_stage2;
    reg valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_stage2 <= {DW{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            gray_stage2 <= gray_next;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    assign gray_out = gray_stage2;

endmodule