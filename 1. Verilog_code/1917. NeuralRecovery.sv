module NeuralRecovery #(parameter W1=8'h2A, W2=8'hD3) (
    input clk,
    input [7:0] noisy,
    output reg [7:0] clean
);
    wire [15:0] hidden = noisy * W1;
    wire [15:0] output_layer = hidden * W2;
    always @(posedge clk) begin
        clean <= (output_layer[15:8] > 8'h80) ? 8'hFF : 8'h00;
    end
endmodule
