//SystemVerilog
module manchester_encoder (
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire data_in,
    output wire manchester_out
);

    // Stage 1: Half-bit toggle pipeline register
    reg half_bit_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            half_bit_stage1 <= 1'b0;
        end else if (enable) begin
            half_bit_stage1 <= ~half_bit_stage1;
        end
    end

    // Stage 2: Data register pipeline
    reg data_in_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage2 <= 1'b0;
        end else if (enable) begin
            data_in_stage2 <= data_in;
        end
    end

    // Stage 3: Manchester output pipeline register
    reg manchester_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            manchester_stage3 <= 1'b0;
        end else if (enable) begin
            manchester_stage3 <= half_bit_stage1 ^ data_in_stage2;
        end
    end

    assign manchester_out = manchester_stage3;

endmodule