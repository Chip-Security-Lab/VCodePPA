module differential_recovery (
    input wire clk,
    input wire [7:0] pos_signal,
    input wire [7:0] neg_signal,
    output reg [8:0] recovered_signal
);
    always @(posedge clk) begin
        // Convert differential to single-ended with sign bit
        if (pos_signal >= neg_signal) begin
            recovered_signal <= {1'b0, pos_signal - neg_signal};
        end else begin
            recovered_signal <= {1'b1, neg_signal - pos_signal};
        end
    end
endmodule