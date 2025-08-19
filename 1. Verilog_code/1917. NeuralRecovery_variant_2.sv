//SystemVerilog
module NeuralRecovery #(parameter W1=8'h2A, W2=8'hD3) (
    input clk,
    input rst_n,
    input [7:0] noisy,
    input        valid_in,
    output reg [7:0] clean,
    output reg       valid_out
);

    // Stage 1: Multiply noisy by W1
    reg [7:0] noisy_stage1;
    reg       valid_stage1;
    reg [15:0] hidden_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            noisy_stage1   <= 8'd0;
            valid_stage1   <= 1'b0;
            hidden_stage1  <= 16'd0;
        end else begin
            noisy_stage1   <= noisy;
            valid_stage1   <= valid_in;
            hidden_stage1  <= noisy * W1;
        end
    end

    // Stage 2: Multiply hidden by W2
    reg [15:0] hidden_stage2;
    reg       valid_stage2;
    reg [15:0] output_layer_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hidden_stage2       <= 16'd0;
            valid_stage2        <= 1'b0;
            output_layer_stage2 <= 16'd0;
        end else begin
            hidden_stage2       <= hidden_stage1;
            valid_stage2        <= valid_stage1;
            output_layer_stage2 <= hidden_stage1 * W2;
        end
    end

    // Stage 3: Optimized thresholding and output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean     <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            if (valid_stage2) begin
                // Efficient threshold: output_layer_stage2[15:8] > 8'h80
                // Range check: if MSB of [15:8] is 1 and not exactly 8'h80, set to 8'hFF
                // Otherwise, set to 8'h00
                if (output_layer_stage2[15:8] >= 8'h81)
                    clean <= 8'hFF;
                else
                    clean <= 8'h00;
                valid_out <= 1'b1;
            end else begin
                clean     <= 8'd0;
                valid_out <= 1'b0;
            end
        end
    end

endmodule