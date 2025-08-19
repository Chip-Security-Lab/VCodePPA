//SystemVerilog
module ITRC_DoubleBuffer #(
    parameter WIDTH = 16
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] raw_status,
    output [WIDTH-1:0] stable_status
);
    // Pipeline stage 1 registers
    reg [WIDTH-1:0] buf1_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [WIDTH-1:0] buf2_stage2;
    reg valid_stage2;
    
    // Pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf1_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            buf1_stage1 <= raw_status;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buf2_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            buf2_stage2 <= buf1_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output assignment with valid signal
    assign stable_status = valid_stage2 ? buf2_stage2 : {WIDTH{1'b0}};
endmodule