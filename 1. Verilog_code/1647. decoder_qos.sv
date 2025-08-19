module decoder_qos #(BURST_SIZE=4) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
reg [1:0] counter;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        counter <= 0;
        grant <= 0;
    end else begin
        counter <= (counter == BURST_SIZE-1) ? 0 : counter + 1;
        grant <= req & (1 << counter);
    end
end
endmodule