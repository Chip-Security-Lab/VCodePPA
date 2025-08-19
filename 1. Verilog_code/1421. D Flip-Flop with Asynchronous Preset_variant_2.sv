//SystemVerilog
module d_ff_async_preset (
    input wire clk,
    input wire rst_n,
    input wire preset_n,
    input wire d,
    output reg q
);
    // 合并的always块，处理所有异步和同步事件
    always @(posedge clk or negedge rst_n or negedge preset_n) begin
        if (!rst_n)
            q <= 1'b0;  // 异步复位优先 - 将输出置为0
        else if (!preset_n)
            q <= 1'b1;  // 异步预置次优先 - 将输出置为1
        else
            q <= d;     // 正常时钟操作 - 将输入d传输到输出q
    end
endmodule