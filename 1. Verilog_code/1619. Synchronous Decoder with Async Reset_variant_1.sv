//SystemVerilog
module sync_decoder_async_reset_pipelined (
    input clk,
    input arst_n,
    input [2:0] address,
    output reg [7:0] cs_n
);

    // Pipeline registers
    reg [2:0] address_stage1;
    reg [7:0] decode_stage1;
    reg [7:0] decode_stage2;
    reg valid_stage1;
    reg valid_stage2;

    // Address register
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            address_stage1 <= 3'b000;
        else
            address_stage1 <= address;
    end

    // Initial decode
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            decode_stage1 <= 8'h00;
        else
            decode_stage1 <= 8'h01 << address_stage1;
    end

    // Valid signal for stage 1
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            valid_stage1 <= 1'b0;
        else
            valid_stage1 <= 1'b1;
    end

    // Inversion stage
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            decode_stage2 <= 8'hFF;
        else
            decode_stage2 <= ~decode_stage1;
    end

    // Valid signal for stage 2
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            valid_stage2 <= 1'b0;
        else
            valid_stage2 <= valid_stage1;
    end

    // Output register
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            cs_n <= 8'hFF;
        else
            cs_n <= decode_stage2;
    end

endmodule