module parity_reg(
    input clk, reset,
    input [7:0] data,
    input load,
    output reg [8:0] data_with_parity
);
    always @(posedge clk) begin
        if (reset)
            data_with_parity <= 9'b0;
        else if (load) begin
            data_with_parity[7:0] <= data;
            data_with_parity[8] <= ^data;  // Parity bit
        end
    end
endmodule