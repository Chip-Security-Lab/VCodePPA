//SystemVerilog
// 优先级编码器子模块
module PriorityEncoder #(parameter N=4) (
    input [N-1:0] req,
    output reg [N-1:0] encoded_req
);
    always @(*) begin
        encoded_req = req & ~(req-1); // LSB优先编码
    end
endmodule

// 寄存器子模块
module PriorityRegister #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] d,
    output reg [N-1:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) q <= 0;
        else q <= d;
    end
endmodule

// 顶层仲裁器模块
module FixedPriorityArbiter #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output [N-1:0] grant
);
    wire [N-1:0] encoded_req;
    
    PriorityEncoder #(N) encoder (
        .req(req),
        .encoded_req(encoded_req)
    );
    
    PriorityRegister #(N) register (
        .clk(clk),
        .rst_n(rst_n),
        .d(encoded_req),
        .q(grant)
    );
endmodule