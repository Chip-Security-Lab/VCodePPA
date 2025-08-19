//SystemVerilog
module asr_shift_pipeline #(
    parameter DATA_W = 32
)(
    input                    clk_i,
    input                    rst_i,
    input  [DATA_W-1:0]      data_i,
    input  [$clog2(DATA_W)-1:0] shift_i,
    input                    valid_i,
    output                   ready_o,
    output reg [DATA_W-1:0]  data_o,
    output reg               valid_o,
    input                    ready_i,
    input                    flush_i
);

    // Stage 1: Input latch + shift + sign extension
    reg [DATA_W-1:0]             asr_stage1;
    reg                          valid_stage1;

    // Ready/valid handshake for single pipeline stage
    assign ready_o = !valid_stage1 || (valid_stage1 && ready_i);

    // Stage 1: Capture input, perform shift and sign extension in one stage
    always @(posedge clk_i) begin
        if (rst_i || flush_i) begin
            asr_stage1   <= {DATA_W{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (ready_o && valid_i) begin
            if (data_i[DATA_W-1]) begin
                asr_stage1 <= (data_i >>> shift_i); // Arithmetic shift right, sign-extended
            end else begin
                asr_stage1 <= data_i >> shift_i;
            end
            valid_stage1 <= 1'b1;
        end else if (ready_o && !valid_i) begin
            valid_stage1 <= 1'b0;
        end
    end

    // Output logic with ready/valid handshake
    always @(posedge clk_i) begin
        if (rst_i || flush_i) begin
            data_o  <= {DATA_W{1'b0}};
            valid_o <= 1'b0;
        end else if (valid_stage1 && ready_i) begin
            data_o  <= asr_stage1;
            valid_o <= 1'b1;
        end else if (ready_i) begin
            valid_o <= 1'b0;
        end
    end

endmodule