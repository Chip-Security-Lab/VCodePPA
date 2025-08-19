module majority_vote_recovery (
    input wire clk,
    input wire enable,
    input wire [2:0] signals,
    output reg recovered_bit,
    output reg valid
);
    wire [1:0] ones_count;
    
    assign ones_count = signals[0] + signals[1] + signals[2];
    
    always @(posedge clk) begin
        if (enable) begin
            recovered_bit <= (ones_count >= 2'd2);
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
endmodule