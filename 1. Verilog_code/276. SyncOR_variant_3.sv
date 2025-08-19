//SystemVerilog
module SyncOR(
    input wire clk,
    input wire [7:0] data1,
    input wire [7:0] data2,
    output reg [7:0] q
);

    // Stage 1: Input latching for data1 and data2
    reg [7:0] data1_stage1;
    reg [7:0] data2_stage1;

    always @(posedge clk) begin
        data1_stage1 <= data1;
        data2_stage1 <= data2;
    end

    // Stage 2: Bitwise OR operation
    reg [7:0] or_result_stage2;

    always @(posedge clk) begin
        or_result_stage2 <= data1_stage1 | data2_stage1;
    end

    // Stage 3: Output register for final result
    always @(posedge clk) begin
        q <= or_result_stage2;
    end

endmodule