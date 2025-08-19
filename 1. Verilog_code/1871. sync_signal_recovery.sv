module sync_signal_recovery (
    input wire clk,
    input wire rst_n,
    input wire [7:0] noisy_signal,
    input wire valid_in,
    output reg [7:0] clean_signal,
    output reg valid_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_signal <= 8'b0;
            valid_out <= 1'b0;
        end else if (valid_in) begin
            clean_signal <= noisy_signal;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule