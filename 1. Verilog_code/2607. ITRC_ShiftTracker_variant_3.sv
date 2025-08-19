//SystemVerilog
module ITRC_ShiftTracker #(
    parameter WIDTH = 4,
    parameter DEPTH = 8
)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] int_in,
    output reg [WIDTH*DEPTH-1:0] history
);

    // Pipeline registers
    reg [WIDTH-1:0] stage1_data;
    reg [WIDTH*(DEPTH-1)-1:0] stage1_history;
    reg [WIDTH-1:0] stage2_data;
    reg [WIDTH*(DEPTH-1)-1:0] stage2_history;
    reg [WIDTH-1:0] stage3_data;
    reg [WIDTH*(DEPTH-1)-1:0] stage3_history;

    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    reg valid_stage3;

    // Stage 1: Input capture and first shift
    always @(posedge clk) begin
        if (!rst_n) begin
            stage1_data <= 0;
            stage1_history <= 0;
            valid_stage1 <= 0;
        end else begin
            stage1_data <= int_in;
            stage1_history <= history[WIDTH*(DEPTH-1)-1:0];
            valid_stage1 <= 1;
        end
    end

    // Stage 2: Second shift
    always @(posedge clk) begin
        if (!rst_n) begin
            stage2_data <= 0;
            stage2_history <= 0;
            valid_stage2 <= 0;
        end else begin
            stage2_data <= stage1_data;
            stage2_history <= stage1_history[WIDTH*(DEPTH-2)-1:0];
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Final shift and output
    always @(posedge clk) begin
        if (!rst_n) begin
            stage3_data <= 0;
            stage3_history <= 0;
            valid_stage3 <= 0;
            history <= 0;
        end else begin
            stage3_data <= stage2_data;
            stage3_history <= stage2_history[WIDTH*(DEPTH-3)-1:0];
            valid_stage3 <= valid_stage2;
            if (valid_stage3) begin
                history <= {stage3_history, stage3_data};
            end
        end
    end

endmodule