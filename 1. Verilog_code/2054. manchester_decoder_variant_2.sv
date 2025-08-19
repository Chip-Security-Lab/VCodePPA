//SystemVerilog
module manchester_decoder (
    input wire clk,
    input wire rst_n,
    input wire sample_en,
    input wire manchester_in,
    output reg data_out,
    output reg valid_out
);

    // Stage 1: Sample and store previous bit
    reg prev_sample_stage1;
    reg manchester_in_stage1;
    reg valid_stage1;

    // Stage 2: Decode Manchester, output data and valid
    reg data_decoded_stage2;
    reg valid_stage2;

    // Pipeline Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_sample_stage1 <= 1'b0;
            manchester_in_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else if (sample_en) begin
            prev_sample_stage1 <= manchester_in;
            manchester_in_stage1 <= manchester_in;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // Pipeline Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_decoded_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            data_decoded_stage2 <= (prev_sample_stage1 == 1'b0 && manchester_in_stage1 == 1'b1);
            valid_stage2 <= 1'b1;
        end else begin
            valid_stage2 <= 1'b0;
        end
    end

    // Output Register Stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            data_out <= data_decoded_stage2;
            valid_out <= valid_stage2;
        end
    end

endmodule