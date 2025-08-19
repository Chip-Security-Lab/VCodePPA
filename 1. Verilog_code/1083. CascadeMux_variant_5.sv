//SystemVerilog
module CascadeMux #(parameter DW=8) (
    input  [1:0] sel1,
    input  [1:0] sel2,
    input  [DW-1:0] stage1 [3:0],
    input  [DW-1:0] stage2 [3:0],
    output reg [DW-1:0] out
);

    reg [DW-1:0] selected_stage1;
    reg [DW-1:0] selected_stage2;
    reg [3:0]    subtrahend_comp4;
    reg [3:0]    sub_result4;

    always @(*) begin
        // Optimized 4:1 multiplexer for stage1
        selected_stage1 = stage1[sel1];

        // Optimized 4:1 multiplexer for stage2
        selected_stage2 = stage2[sel2];

        // Compute two's complement of lower 4 bits of selected_stage2
        subtrahend_comp4 = (~selected_stage2[3:0]) + 4'b0001;

        // Add lower 4 bits of selected_stage1 and subtrahend_comp4
        sub_result4 = selected_stage1[3:0] + subtrahend_comp4;

        // Output selection based on sel1[0]
        out = (sel1[0]) ? { {(DW-4){1'b0}}, sub_result4 } : selected_stage1;
    end

endmodule