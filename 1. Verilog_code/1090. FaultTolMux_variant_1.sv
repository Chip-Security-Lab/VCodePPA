//SystemVerilog
module FaultTolMux #(parameter DW=8) (
    input clk,
    input [1:0] sel,
    input [3:0][DW-1:0] din,
    output reg [DW-1:0] dout,
    output error
);

wire [DW-1:0] primary_data;
wire [DW-1:0] backup_data;
wire error_signal;
reg [DW-1:0] next_data;

// 优化数据选择
assign primary_data = din[sel];
assign backup_data  = din[{~sel[1], ~sel[0]}];

// 优化错误信号生成
assign error = |(primary_data ^ backup_data);

// 优化选择逻辑
always @(posedge clk) begin
    if ((primary_data[7] ^ primary_data[6] ^ primary_data[5] ^ primary_data[4]) == primary_data[3]) begin
        next_data <= primary_data;
    end else begin
        next_data <= backup_data;
    end
    dout <= next_data;
end

endmodule