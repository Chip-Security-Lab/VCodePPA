//SystemVerilog
// Top-level Biphase Mark Encoder with Pipelined Architecture
module biphase_mark_enc (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    input  wire valid_in,
    output wire encoded,
    output wire valid_out
);

    // Stage 1: Input Latch
    reg data_in_stage1;
    reg valid_stage1;

    // Stage 2: Phase Toggle
    reg phase_stage2;
    reg valid_stage2;
    reg data_in_stage2;

    // Stage 3: Encoding
    reg encoded_stage3;
    reg valid_stage3;

    // Stage 1: Latch input data and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 1'b0;
            valid_stage1   <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
            valid_stage1   <= valid_in;
        end
    end

    // Stage 2: Phase toggle and data pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_stage2    <= 1'b0;
            valid_stage2    <= 1'b0;
            data_in_stage2  <= 1'b0;
        end else begin
            if (valid_stage1) begin
                phase_stage2   <= ~phase_stage2;
            end
            data_in_stage2  <= data_in_stage1;
            valid_stage2    <= valid_stage1;
        end
    end

    // Stage 3: Biphase Mark Encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_stage3 <= 1'b0;
            valid_stage3   <= 1'b0;
        end else begin
            if (valid_stage2) begin
                encoded_stage3 <= data_in_stage2 ? phase_stage2 : ~phase_stage2;
            end
            valid_stage3   <= valid_stage2;
        end
    end

    assign encoded   = encoded_stage3;
    assign valid_out = valid_stage3;

endmodule