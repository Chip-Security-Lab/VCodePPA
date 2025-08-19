module DynChanMux #(parameter DW=16, MAX_CH=8) (
    input clk,
    input [$clog2(MAX_CH)-1:0] ch_num,
    input [(MAX_CH*DW)-1:0] data, // 改为一维数组
    output reg [DW-1:0] out
);
reg [DW-1:0] selected_data;

always @(*) begin
    if (ch_num < MAX_CH) begin
        selected_data = data[(ch_num*DW) +: DW]; // 使用位选择操作符
    end else begin
        selected_data = {DW{1'b0}}; // 明确位宽
    end
end

always @(posedge clk)
    out <= selected_data;
endmodule