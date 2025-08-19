//SystemVerilog
module SyncOR_Pipelined(
    input clk,
    input rst_n,
    input valid_in,
    input [7:0] data1,
    input [7:0] data2,
    output reg valid_out,
    output reg [7:0] q
);

    // Stage 1: OR operation (combinational)
    wire [7:0] or_result_stage1;
    assign or_result_stage1 = data1 | data2;

    // Stage 2: Register OR result and valid signal
    reg [7:0] or_result_stage2;
    reg valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_stage2 <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            or_result_stage2 <= or_result_stage1;
            valid_stage2 <= valid_in;
        end
    end

    // Stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            q <= or_result_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule