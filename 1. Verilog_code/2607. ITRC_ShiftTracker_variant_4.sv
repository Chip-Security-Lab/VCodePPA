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

    // Pipeline stage 1: Input register
    reg [WIDTH-1:0] int_in_stage1;
    reg [WIDTH*(DEPTH/2)-1:0] history_upper_stage1;
    reg [WIDTH*(DEPTH/2)-1:0] history_lower_stage1;

    // Pipeline stage 2: Shift operation
    reg [WIDTH-1:0] int_in_stage2;
    reg [WIDTH*(DEPTH/2)-1:0] history_upper_stage2;
    reg [WIDTH*(DEPTH/2)-1:0] history_lower_stage2;

    // Pipeline stage 3: Output combination
    reg [WIDTH*DEPTH-1:0] history_stage3;

    // Stage 1: Input registration
    always @(posedge clk) begin
        if (!rst_n) begin
            int_in_stage1 <= 0;
            history_upper_stage1 <= 0;
            history_lower_stage1 <= 0;
        end else begin
            int_in_stage1 <= int_in;
            history_upper_stage1 <= history[WIDTH*DEPTH-1:WIDTH*(DEPTH/2)];
            history_lower_stage1 <= history[WIDTH*(DEPTH/2)-1:0];
        end
    end

    // Stage 2: Shift operation
    always @(posedge clk) begin
        if (!rst_n) begin
            int_in_stage2 <= 0;
            history_upper_stage2 <= 0;
            history_lower_stage2 <= 0;
        end else begin
            int_in_stage2 <= int_in_stage1;
            history_upper_stage2 <= {history_upper_stage1[WIDTH*(DEPTH/2-1)-1:0], history_lower_stage1[WIDTH*(DEPTH/2)-1:WIDTH*(DEPTH/2-1)]};
            history_lower_stage2 <= {history_lower_stage1[WIDTH*(DEPTH/2-1)-1:0], int_in_stage1};
        end
    end

    // Stage 3: Output combination
    always @(posedge clk) begin
        if (!rst_n) begin
            history_stage3 <= 0;
        end else begin
            history_stage3 <= {history_upper_stage2, history_lower_stage2};
        end
    end

    // Output assignment
    assign history = history_stage3;

endmodule