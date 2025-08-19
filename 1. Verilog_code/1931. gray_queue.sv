module gray_queue #(parameter DW=8) (
    input clk, rst, en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error  // 修改为output reg
);
    reg [DW:0] queue [0:1];
    wire [DW:0] gray_in;
    reg parity;
    integer i;
    
    // 计算奇偶校验
    always @(*) begin
        parity = 0;
        for(i=0; i<DW; i=i+1) begin
            parity = parity ^ din[i];
        end
    end
    
    assign gray_in = {din, parity};
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            queue[0] <= 0;
            queue[1] <= 0;
            dout <= 0;
            error <= 0;
        end else if(en) begin
            queue[0] <= gray_in;
            queue[1] <= queue[0];
            dout <= queue[1][DW:1];
            error <= (^queue[1][DW:1]) ^ queue[1][0];
        end
    end
endmodule