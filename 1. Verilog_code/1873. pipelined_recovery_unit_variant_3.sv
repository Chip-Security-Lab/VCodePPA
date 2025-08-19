//SystemVerilog
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
            stage1 <= {DATA_WIDTH{1'b0}};
            stage2 <= {DATA_WIDTH{1'b0}};
            data_out <= {DATA_WIDTH{1'b0}};
            stage1_valid <= 1'b0;
            stage2_valid <= 1'b0;
            out_valid <= 1'b0;
        end else begin
            if (in_valid) begin
                stage1 <= data_in;
                stage1_valid <= 1'b1;
            end
            
            if (stage1_valid) begin
                stage2 <= stage1;
                stage2_valid <= 1'b1;
            end
            
            if (stage2_valid) begin
                data_out <= stage2;
                out_valid <= 1'b1;
            end
        end
    end
endmodule