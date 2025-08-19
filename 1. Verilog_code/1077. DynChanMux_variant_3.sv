//SystemVerilog
module DynChanMux #(parameter DW=16, MAX_CH=8) (
    input clk,
    input [$clog2(MAX_CH)-1:0] channel_select,
    input [(MAX_CH*DW)-1:0] data_in,
    output reg [DW-1:0] mux_out
);
    reg [DW-1:0] selected_data;
    wire [7:0] minuend;
    wire [7:0] diff_result;

    // 优化的数据选择逻辑，避免条件判断链
    always @(*) begin
        if (channel_select[$clog2(MAX_CH)-1:0] < MAX_CH)
            selected_data = data_in[(channel_select*DW) +: DW];
        else
            selected_data = {DW{1'b0}};
    end

    assign minuend = selected_data[7:0];

    // 优化的减法，直接使用减法器，无需多余信号
    assign diff_result = minuend - 8'hA5;

    always @(posedge clk) begin
        mux_out <= { {(DW-8){1'b0}}, diff_result };
    end
endmodule