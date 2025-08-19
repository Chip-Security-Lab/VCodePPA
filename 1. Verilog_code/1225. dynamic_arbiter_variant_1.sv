//SystemVerilog
module dynamic_arbiter #(parameter WIDTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    input [WIDTH-1:0] pri_map,  // External priority
    output reg [WIDTH-1:0] grant_o
);
    // Pre-compute the masked requests combinationally
    wire [WIDTH-1:0] masked_req = req_i & pri_map;
    
    // Registers for storing intermediate masked_req (moved backwards)
    reg [WIDTH-1:0] masked_req_reg;
    
    // Priority encoder logic moved to combinational block
    reg [WIDTH-1:0] grant_next;
    integer i;
    
    always @(*) begin
        grant_next = 0;
        for(i=WIDTH-1; i>=0; i=i-1) begin
            if(masked_req_reg[i]) 
                grant_next = 1 << i;
        end
    end
    
    // Sequential logic with register moved backward
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            masked_req_reg <= 0;
            grant_o <= 0;
        end else begin
            masked_req_reg <= masked_req;
            grant_o <= grant_next;
        end
    end
endmodule