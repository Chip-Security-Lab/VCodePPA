module HysteresisFilter #(parameter W=8, HYST=4) (
    input clk, 
    input [W-1:0] din,
    output reg out
);
    reg [W-1:0] prev;
    always @(posedge clk) begin
        if(din > prev + HYST) out <= 1;
        else if(din < prev - HYST) out <= 0;
        prev <= din;
    end
endmodule