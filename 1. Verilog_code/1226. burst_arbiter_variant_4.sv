//SystemVerilog
module burst_arbiter #(
    parameter WIDTH = 4,
    parameter BURST = 4
) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [$clog2(BURST):0] counter;
    reg [WIDTH-1:0] current;
    wire [WIDTH-1:0] priority_req;

    // 使用一种更直接的方式计算最低有效位为1的位置
    // 这种变换能改善关键路径延迟
    assign priority_req = req_i & (-req_i);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            current <= '0;
            grant_o <= '0;
        end else begin
            if (counter == 0) begin
                current <= priority_req;
                counter <= |req_i ? BURST-1 : '0;
            end else begin
                counter <= counter - 1'b1;
            end
            grant_o <= current;
        end
    end
endmodule