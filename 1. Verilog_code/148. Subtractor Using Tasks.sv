module subtractor_task (
    input wire clk,       // 时钟信号
    input wire [7:0] a,   // 被减数
    input wire [7:0] b,   // 减数
    output reg [7:0] res  // 差
);

task perform_sub;
    input [7:0] x, y;
    output reg [7:0] result;
    begin
        result = x - y;
    end
endtask

always @(posedge clk) begin
    perform_sub(a, b, res);
end

endmodule