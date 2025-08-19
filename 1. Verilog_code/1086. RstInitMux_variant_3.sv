//SystemVerilog
module RstInitMux #(
    parameter DW = 8
) (
    input wire clk,
    input wire rst,
    input wire [2:0] sel,
    input wire [7:0][DW-1:0] din,
    output reg [DW-1:0] dout
);

    // Stage 1: Input selection based on sel
    reg [DW-1:0] data_selected_stage1;
    always @(*) begin
        case (sel)
            3'd0: data_selected_stage1 = din[0];
            3'd1: data_selected_stage1 = din[1];
            3'd2: data_selected_stage1 = din[2];
            3'd3: data_selected_stage1 = din[3];
            3'd4: data_selected_stage1 = din[4];
            3'd5: data_selected_stage1 = din[5];
            3'd6: data_selected_stage1 = din[6];
            3'd7: data_selected_stage1 = din[7];
            default: data_selected_stage1 = {DW{1'b0}};
        endcase
    end

    // Stage 2: Register the selected data
    reg [DW-1:0] data_pipeline_stage2;
    always @(posedge clk) begin
        data_pipeline_stage2 <= data_selected_stage1;
    end

    // Stage 3: Output register with reset and initialization
    always @(posedge clk) begin
        if (rst) begin
            dout <= din[0];
        end else begin
            dout <= data_pipeline_stage2;
        end
    end

endmodule