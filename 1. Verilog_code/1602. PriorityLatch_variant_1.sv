//SystemVerilog
module PriorityLatch #(parameter N=4) (
    input clk, en,
    input [N-1:0] req,
    output reg [N-1:0] grant
);

reg [N-1:0] grant_next;
reg [N-1:0] req_inv;
reg [N-1:0] temp_result;
reg carry;

always @(posedge clk) begin
    if (en) begin
        req_inv = ~req;
        {carry, temp_result} = req_inv + 1;
        grant <= (req[0]) ? 4'b0001 :
                (req[1]) ? 4'b0010 :
                (req[2]) ? 4'b0100 :
                (req[3]) ? 4'b1000 : 4'b0000;
    end
end

endmodule