//SystemVerilog
module sync_mux_with_reset(
    input clk, rst_n,
    input [31:0] data_a, data_b,
    input req, // 原sel信号
    output reg ack, // 新增应答信号
    output reg [31:0] result
);

    reg req_dly; // 用于检测req上升沿
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'h0;
            ack <= 1'b0;
            req_dly <= 1'b0;
        end
        else begin
            req_dly <= req;
            
            if (req && !req_dly) begin // 检测req上升沿
                case (req)
                    1'b0: result <= data_a;
                    1'b1: result <= data_b;
                endcase
                ack <= 1'b1;
            end
            else if (!req) begin
                ack <= 1'b0;
            end
        end
    end
endmodule