//SystemVerilog
module manchester_encoder (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output wire encoded_out,
    output wire valid_out
);

    // Stage 1: Sample input data and generate valid signal
    reg data_sampled_stage1;
    reg valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_sampled_stage1 <= 1'b0;
            valid_stage1        <= 1'b0;
        end else begin
            data_sampled_stage1 <= data_in;
            valid_stage1        <= 1'b1;
        end
    end

    // Stage 2: Register data and valid signal for pipeline
    reg data_stage2;
    reg valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2  <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2  <= data_sampled_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Stage 3: Manchester Encoding Logic
    reg encoded_out_stage3;
    reg valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_out_stage3 <= 1'b0;
            valid_stage3       <= 1'b0;
        end else begin
            if (data_stage2)
                encoded_out_stage3 <= ~encoded_out_stage3;
            // If data_stage2 is 0, maintain current state
            valid_stage3 <= valid_stage2;
        end
    end

    // Output assignments
    assign encoded_out = encoded_out_stage3;
    assign valid_out   = valid_stage3;

endmodule