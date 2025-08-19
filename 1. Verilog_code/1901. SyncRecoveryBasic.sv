module SyncRecoveryBasic #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] noisy_in,
    output reg [WIDTH-1:0] clean_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) clean_out <= 0;
        else if (en) clean_out <= noisy_in; 
    end
endmodule