module pipelined_recovery_unit #(
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire in_valid,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg out_valid
);
    reg [DATA_WIDTH-1:0] stage1, stage2;
    reg stage1_valid, stage2_valid;
    
    always @(posedge clock) begin
        if (reset) begin
            {stage1, stage2, data_out} <= 0;
            {stage1_valid, stage2_valid, out_valid} <= 0;
        end else begin
            stage1 <= in_valid ? data_in : stage1;
            stage1_valid <= in_valid;
            
            stage2 <= stage1_valid ? stage1 : stage2;
            stage2_valid <= stage1_valid;
            
            data_out <= stage2_valid ? stage2 : data_out;
            out_valid <= stage2_valid;
        end
    end
endmodule