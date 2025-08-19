//SystemVerilog
module BurstArbiter #(parameter BURST_LEN=4) (
    input clk, rst, en,
    input [3:0] req,
    output reg [3:0] grant
);
    reg [1:0] burst_cnt;
    wire [3:0] req_neg = ~req + 1'b1;  // 合并补码转换步骤
    wire burst_complete = (burst_cnt == BURST_LEN-1);
    wire [3:0] next_grant = req & req_neg;

    always @(posedge clk) begin
        if(rst) begin
            grant <= 4'b0;
            burst_cnt <= 2'b0;
        end
        else if(en) begin
            if(|grant) begin
                burst_cnt <= burst_complete ? 2'b0 : burst_cnt + 1'b1;
                grant <= burst_complete ? next_grant : grant;
            end
            else begin
                grant <= next_grant;
                burst_cnt <= 2'b0;
            end
        end
    end
endmodule