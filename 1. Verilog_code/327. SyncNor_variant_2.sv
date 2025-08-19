//SystemVerilog
module SyncNor_Pipelined (
    input  wire clk,
    input  wire rst,
    input  wire a,
    input  wire b,
    input  wire in_valid,
    output wire out_valid,
    output reg  y
);

    // Stage 1: Input capture
    reg a_stage1;
    reg b_stage1;
    reg valid_stage1;

    always @(posedge clk) begin
        if (rst) begin
            a_stage1     <= 1'b0;
            b_stage1     <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_stage1     <= a;
            b_stage1     <= b;
            valid_stage1 <= in_valid;
        end
    end

    // Stage 1: OR operation
    reg or_stage1;
    always @(posedge clk) begin
        if (rst) begin
            or_stage1 <= 1'b0;
        end else begin
            or_stage1 <= a | b;
        end
    end

    // Stage 2: NOR operation
    reg nor_stage2;
    always @(posedge clk) begin
        if (rst) begin
            nor_stage2 <= 1'b0;
        end else begin
            nor_stage2 <= ~or_stage1;
        end
    end

    // Stage 2: Output register
    always @(posedge clk) begin
        if (rst) begin
            y <= 1'b0;
        end else begin
            y <= nor_stage2;
        end
    end

    // Stage 2: Valid signal pipeline
    reg valid_stage2;
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end

    assign out_valid = valid_stage2;

endmodule