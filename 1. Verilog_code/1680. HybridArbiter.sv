module HybridArbiter #(parameter HP_GROUP=2) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
wire [3:0] hp_req = req & {4{1'b1}}; // 高2位为优先组
wire [3:0] lp_req = req & {4{1'b0}};

always @(posedge clk) begin
    if(|hp_req)
        grant <= hp_req & -hp_req; // 优先组固定仲裁
    else 
        grant <= lp_req << $urandom%2; // 非优先组随机轮询
end
endmodule
