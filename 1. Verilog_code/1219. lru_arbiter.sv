module lru_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [WIDTH-1:0] usage [0:WIDTH-1];
integer i;
integer lru;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        grant_o <= 0;
        for(i=0; i<WIDTH; i=i+1) begin
            usage[i] <= 4'b0001 << i;
        end
    end else begin
        lru = 0;
        for(i=1; i<WIDTH; i=i+1) begin
            if(usage[i] < usage[lru] && req_i[i]) 
                lru = i;
        end
        grant_o <= (1 << lru);
        usage[lru] <= {1'b1, usage[lru][WIDTH-1:1]};
    end
end
endmodule