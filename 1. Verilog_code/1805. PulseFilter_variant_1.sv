//SystemVerilog
module PulseFilter #(parameter TIMEOUT=8) (
    input clk, rst,
    input in_pulse,
    output reg out_pulse
);
    reg [3:0] cnt;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            out_pulse <= 0;
        end
        else begin
            case ({in_pulse, |cnt})  // 使用连接操作符组合条件，|cnt检查计数器是否为非零
                2'b10: begin  // in_pulse=1, cnt=0
                    cnt <= TIMEOUT;
                    out_pulse <= 1'b1;
                end
                2'b11: begin  // in_pulse=1, cnt!=0
                    cnt <= TIMEOUT;
                    out_pulse <= 1'b1;
                end
                2'b01: begin  // in_pulse=0, cnt!=0
                    cnt <= cnt - 1'b1;
                    out_pulse <= 1'b1;
                end
                2'b00: begin  // in_pulse=0, cnt=0
                    cnt <= 0;
                    out_pulse <= 1'b0;
                end
                default: begin  // 冗余状态，确保完整性
                    cnt <= cnt;
                    out_pulse <= out_pulse;
                end
            endcase
        end
    end
endmodule