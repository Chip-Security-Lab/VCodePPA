//SystemVerilog
module sync_reset_multi_enable #(
    parameter CHANNELS = 4
)(
    input wire clk,
    input wire reset_in,
    input wire [CHANNELS-1:0] enable_conditions,
    output reg [CHANNELS-1:0] reset_out
);

    // Generate multiple reset channel instances
    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin : reset_channel_gen
            always @(posedge clk) begin
                // 使用{reset_in, enable_conditions[i]}作为case语句的选择信号
                case({reset_in, enable_conditions[i]})
                    2'b10, 2'b11: reset_out[i] <= 1'b1; // reset_in为1，不管enable_conditions的值
                    2'b01:        reset_out[i] <= 1'b0; // reset_in为0，enable_conditions为1
                    2'b00:        reset_out[i] <= reset_out[i]; // 保持当前值
                endcase
            end
        end
    endgenerate
    
endmodule