//SystemVerilog
// Priority Encoder Module
module PriorityEncoder #(parameter N=4) (
    input [N-1:0] req,
    output [N-1:0] encoded
);
    wire [N-1:0] req_neg;
    wire [N-1:0] encoded_pre;
    
    assign req_neg = ~req;
    assign encoded_pre = req_neg + 1;
    assign encoded = req & encoded_pre;
endmodule

// Priority Latch Module
module PriorityLatch #(parameter N=4) (
    input clk, en,
    input [N-1:0] req,
    output reg [N-1:0] grant
);
    wire [N-1:0] encoded;
    reg [N-1:0] req_reg;
    
    PriorityEncoder #(N) pe (
        .req(req_reg),
        .encoded(encoded)
    );
    
    always @(posedge clk) begin
        if(en) begin
            req_reg <= req;
            grant <= encoded;
        end
    end
endmodule