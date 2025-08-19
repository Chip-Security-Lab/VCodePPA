//SystemVerilog
module diff_manchester_enc (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output wire encoded_out
);

    // Pipeline Stage 1: Register input data
    reg data_in_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 1'b0;
        end else begin
            data_in_stage1 <= data_in;
        end
    end

    // Pipeline Stage 2: Compute prev_bit XOR data_in (split into two stages)
    reg prev_bit_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_bit_stage2 <= 1'b0;
        end else begin
            prev_bit_stage2 <= prev_bit_stage2 ^ data_in_stage1;
        end
    end

    // Pipeline Stage 3: Register prev_bit_stage2
    reg prev_bit_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_bit_stage3 <= 1'b0;
        end else begin
            prev_bit_stage3 <= prev_bit_stage2;
        end
    end

    // Pipeline Stage 4: Compute encoded output (split XOR into two pipeline stages)
    reg xor_stage4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage4 <= 1'b0;
        end else begin
            xor_stage4 <= prev_bit_stage3 ^ data_in_stage1;
        end
    end

    // Pipeline Stage 5: Register encoded output
    reg encoded_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_stage5 <= 1'b0;
        end else begin
            encoded_stage5 <= xor_stage4;
        end
    end

    assign encoded_out = encoded_stage5;

endmodule