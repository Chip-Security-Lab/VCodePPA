//SystemVerilog
module burst_arbiter #(WIDTH=4, BURST=4) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [3:0] counter;
    reg [WIDTH-1:0] next_grant;
    wire [WIDTH-1:0] priority_req;
    
    // Move combinational logic before register
    assign priority_req = req_i & (~req_i + 1);
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <= 0;
            grant_o <= 0;
            next_grant <= 0;
        end else begin
            if(counter == 0) begin
                next_grant <= priority_req;
                grant_o <= priority_req;
                counter <= priority_req ? BURST-1 : 0;
            end else begin
                counter <= counter - 1;
            end
        end
    end
endmodule