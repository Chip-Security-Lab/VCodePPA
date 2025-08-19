//SystemVerilog
module two_flop_sync #(parameter WIDTH = 8) (
    input wire clk_dst,
    input wire rst_n,
    input wire [WIDTH-1:0] data_src,
    output reg [WIDTH-1:0] data_dst
);
    reg [WIDTH-1:0] sync_stage1;

    always @(posedge clk_dst or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= {WIDTH{1'b0}};
            data_dst    <= {WIDTH{1'b0}};
        end else begin
            {sync_stage1, data_dst} <= {data_src, sync_stage1};
        end
    end
endmodule