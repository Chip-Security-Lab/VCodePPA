//SystemVerilog
module parallel_load_ring (
    input clk,
    input req,         // 替代原来的load信号，作为请求信号
    input [3:0] parallel_in,
    output reg [3:0] ring,
    output reg ack     // 新增的应答信号
);
    reg load_done;     // 指示数据加载完成
    
    always @(posedge clk) begin
        if (req && !load_done) begin
            // 收到请求且尚未完成加载，加载并置应答信号
            ring <= parallel_in;
            ack <= 1'b1;
            load_done <= 1'b1;
        end else if (!req && load_done) begin
            // 请求撤销，复位应答状态
            ack <= 1'b0;
            load_done <= 1'b0;
        end else if (!req && !load_done) begin
            // 无请求状态下，执行环形移位
            ring <= {ring[0], ring[3:1]};
        end
    end
endmodule