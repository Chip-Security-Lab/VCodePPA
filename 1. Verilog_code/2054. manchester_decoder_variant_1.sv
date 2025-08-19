//SystemVerilog
module manchester_decoder (
    input  wire clk,
    input  wire rst_n,
    input  wire sample_en,
    input  wire manchester_in,
    output reg  data_out,
    output reg  valid_out
);

    // Pipeline Stage 1: Sample the input and capture previous state
    reg sample_stage_valid;
    reg manchester_sampled;
    reg prev_sampled;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_stage_valid <= 1'b0;
            manchester_sampled <= 1'b0;
            prev_sampled <= 1'b0;
        end else if (sample_en) begin
            prev_sampled <= manchester_sampled;
            manchester_sampled <= manchester_in;
            sample_stage_valid <= 1'b1;
        end else begin
            sample_stage_valid <= 1'b0;
        end
    end

    // Pipeline Stage 2: Decode Manchester and generate output
    reg decode_stage_valid;
    reg decoded_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_stage_valid <= 1'b0;
            decoded_data <= 1'b0;
        end else begin
            if (sample_stage_valid) begin
                // Optimized comparison: use direct bitwise operation for (prev_sampled == 1'b0 && manchester_sampled == 1'b1)
                decoded_data <= (~prev_sampled) & manchester_sampled;
                decode_stage_valid <= 1'b1;
            end else begin
                decode_stage_valid <= 1'b0;
            end
        end
    end

    // Output register stage for data_out and valid_out
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            data_out  <= decoded_data;
            valid_out <= decode_stage_valid;
        end
    end

endmodule