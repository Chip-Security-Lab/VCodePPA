module round_robin_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
reg [WIDTH-1:0] last_grant;
integer i;
reg found;
reg [31:0] idx; 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        grant_o <= 0;
        last_grant <= 0;
    end else begin
        found = 0;
        grant_o <= 0;
        
        for(i=0; i<WIDTH; i=i+1) begin
            idx = (last_grant + i + 1) % WIDTH;
            if(req_i[idx] && !found) begin
                grant_o <= 1 << idx;
                last_grant <= idx;
                found = 1;
            end
        end
    end
end
endmodule