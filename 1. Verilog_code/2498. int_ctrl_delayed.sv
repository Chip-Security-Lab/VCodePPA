module int_ctrl_delayed #(
    parameter CYCLE = 2
)(
    input clk, rst,
    input [7:0] req_in,
    output reg [2:0] delayed_grant
);
    // 使用寄存器数组替代多维数组
    reg [7:0] req_pipe_0;
    reg [7:0] req_pipe_1;
    
    // 修改为简单的时序逻辑
    always @(posedge clk) begin
        if(rst) begin
            req_pipe_0 <= 8'b0;
            req_pipe_1 <= 8'b0;
            delayed_grant <= 3'b0;
        end else begin
            req_pipe_0 <= req_in;
            req_pipe_1 <= req_pipe_0;
            
            // 使用组合逻辑找到最高位
            delayed_grant <= encoder(req_pipe_1);
        end
    end
    
    // 添加编码器函数
    function [2:0] encoder;
        input [7:0] value;
        begin
            casez(value)
                8'b1???????: encoder = 3'd7;
                8'b01??????: encoder = 3'd6;
                8'b001?????: encoder = 3'd5;
                8'b0001????: encoder = 3'd4;
                8'b00001???: encoder = 3'd3;
                8'b000001??: encoder = 3'd2;
                8'b0000001?: encoder = 3'd1;
                8'b00000001: encoder = 3'd0;
                default: encoder = 3'd0;
            endcase
        end
    endfunction
endmodule