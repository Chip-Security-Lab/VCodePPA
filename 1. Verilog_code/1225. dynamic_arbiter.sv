module dynamic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] pri_map,  // External priority
    output reg [WIDTH-1:0] grant_o
);
wire [WIDTH-1:0] masked_req = req_i & pri_map;
integer i;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        grant_o <= 0;
    end else begin
        grant_o <= 0;
        for(i=WIDTH-1; i>=0; i=i-1) begin
            if(masked_req[i]) 
                grant_o <= 1 << i;
        end
    end
end
endmodule