//SystemVerilog
module GatedDiv_Pipeline(
    input clk, en,
    input [15:0] x, y,
    output reg [15:0] q
);
    // Pipeline registers
    reg [15:0] x_stage1, y_stage1;
    reg [15:0] x_stage2, y_stage2;
    reg [15:0] x_stage3, y_stage3;
    reg [15:0] q_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;

    // Stage 1: Register inputs
    always @(posedge clk) begin
        if (en) begin
            x_stage1 <= x;
            y_stage1 <= y;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Stage 2: Prepare for division
    always @(posedge clk) begin
        if (valid_stage1) begin
            x_stage2 <= x_stage1;
            y_stage2 <= y_stage1;
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Stage 3: Further preparation
    always @(posedge clk) begin
        if (valid_stage2) begin
            x_stage3 <= x_stage2;
            y_stage3 <= y_stage2;
            valid_stage3 <= 1'b1;
        end else begin
            valid_stage3 <= 1'b0;
        end
    end

    // Stage 4: Perform division
    always @(posedge clk) begin
        if (valid_stage3) begin
            if (y_stage3 != 0) 
                q_stage4 <= x_stage3 / y_stage3; 
            else 
                q_stage4 <= 16'hFFFF;
            valid_stage4 <= 1'b1;
        end else begin
            valid_stage4 <= 1'b0;
        end
    end

    // Output stage: Register the final output
    always @(posedge clk) begin
        if (valid_stage4) begin
            q <= q_stage4;
        end
    end
endmodule