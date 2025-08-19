//SystemVerilog
module nor2_reversed (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    output wire Y
);

    // Stage 1: Register input signals
    reg A_stage1, B_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_stage1 <= 1'b0;
            B_stage1 <= 1'b0;
        end else begin
            A_stage1 <= A;
            B_stage1 <= B;
        end
    end

    // Stage 2: Invert registered inputs
    reg nA_stage2, nB_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nA_stage2 <= 1'b1;
            nB_stage2 <= 1'b1;
        end else begin
            nA_stage2 <= ~A_stage1;
            nB_stage2 <= ~B_stage1;
        end
    end

    // Stage 3: NOR operation using inverted registered inputs
    reg Y_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_stage3 <= 1'b0;
        end else begin
            Y_stage3 <= nA_stage2 & nB_stage2; // NOR: ~(A | B) = ~A & ~B
        end
    end

    assign Y = Y_stage3;

endmodule