module time_slot_arbiter #(WIDTH=4, SLOT=8) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [7:0] counter;
reg [WIDTH-1:0] rotation;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
        rotation <= 1;
        grant_o <= 0;
    end else begin
        counter <= (counter >= SLOT-1) ? 0 : counter + 1;
        if(counter == 0) begin
            rotation <= {rotation[WIDTH-2:0], rotation[WIDTH-1]};
            grant_o <= (req_i & rotation) ? rotation : 0;
        end
    end
end
endmodule
