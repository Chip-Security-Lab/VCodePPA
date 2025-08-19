module burst_arbiter #(WIDTH=4, BURST=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [3:0] counter;
reg [WIDTH-1:0] current;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter <= 0;
        current <= 0;
    end else begin
        if(counter == 0) begin
            current <= req_i & (~req_i + 1);
            counter <= current ? BURST-1 : 0;
        end else begin
            counter <= counter - 1;
        end
        grant_o <= current;
    end
end
endmodule
