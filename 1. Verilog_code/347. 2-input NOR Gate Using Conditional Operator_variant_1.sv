//SystemVerilog
module nor2_conditional (
    input  wire clk,
    input  wire rst_n,
    input  wire A,
    input  wire B,
    output wire Y
);

    // Pipeline Stage 1: OR Operation (Combinational)
    wire or_result;
    assign or_result = A | B;

    // Pipeline Stage 2: Register OR Result
    reg stage2_or_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_or_result <= 1'b0;
        else
            stage2_or_result <= or_result;
    end

    // Pipeline Stage 3: Register NOR Output
    reg stage3_nor_result;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_nor_result <= 1'b0;
        else
            stage3_nor_result <= ~stage2_or_result;
    end

    assign Y = stage3_nor_result;

endmodule