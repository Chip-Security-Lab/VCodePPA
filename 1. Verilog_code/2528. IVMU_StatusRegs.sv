module IVMU_StatusRegs #(parameter CH=8) (
    input clk, rst,
    input [CH-1:0] active,
    output reg [CH-1:0] status
);
    // 修改使用简单的时序逻辑
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            status <= {CH{1'b0}};
        end else begin
            for (i = 0; i < CH; i = i + 1) begin
                if (active[i]) status[i] <= 1'b1;
            end
        end
    end
endmodule