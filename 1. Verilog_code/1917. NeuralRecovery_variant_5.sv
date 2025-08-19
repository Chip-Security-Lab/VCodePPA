//SystemVerilog
module NeuralRecovery_Pipelined #(parameter W1=8'h2A, W2=8'hD3) (
    input clk,
    input rst_n,
    input start,
    input [7:0] noisy,
    output reg [7:0] clean,
    output reg valid_out
);
    // Stage 1: Multiply noisy by W1
    reg [7:0] noisy_stage1;
    reg valid_stage1;
    wire [15:0] hidden_product_stage1;

    assign hidden_product_stage1 = noisy_stage1 * W1;

    // Stage 2: Multiply hidden_product by W2
    reg [15:0] hidden_product_stage2;
    reg valid_stage2;
    wire [15:0] output_layer_product_stage2;

    assign output_layer_product_stage2 = hidden_product_stage2 * W2;

    // Stage 3: Output threshold and result
    reg [15:0] output_layer_product_stage3;
    reg valid_stage3;

    // Pipeline registers and control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            noisy_stage1 <= 8'b0;
            valid_stage1 <= 1'b0;
        end else begin
            noisy_stage1 <= noisy;
            valid_stage1 <= start;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hidden_product_stage2 <= 16'b0;
            valid_stage2 <= 1'b0;
        end else begin
            hidden_product_stage2 <= hidden_product_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_layer_product_stage3 <= 16'b0;
            valid_stage3 <= 1'b0;
        end else begin
            output_layer_product_stage3 <= output_layer_product_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean <= 8'b0;
            valid_out <= 1'b0;
        end else begin
            if (valid_stage3) begin
                if (output_layer_product_stage3[15:8] > 8'h80) begin
                    clean <= 8'hFF;
                end else begin
                    clean <= 8'h00;
                end
                valid_out <= 1'b1;
            end else begin
                clean <= clean;
                valid_out <= 1'b0;
            end
        end
    end

endmodule