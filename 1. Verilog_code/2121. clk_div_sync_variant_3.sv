//SystemVerilog
`timescale 1ns / 1ps
module clk_div_sync #(
    parameter DIV = 4
)(
    input wire clk_in,
    input wire rst_n,
    input wire en,
    output reg clk_out
);
    // 使用最小位宽计数器，根据DIV参数确定
    localparam CNT_WIDTH = $clog2(DIV/2);
    reg [CNT_WIDTH-1:0] counter;
    
    // 预计算比较值，避免在每个时钟周期计算
    localparam [CNT_WIDTH-1:0] COMPARE_VAL = (DIV/2) - 1;
    
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {CNT_WIDTH{1'b0}};
            clk_out <= 1'b0;
        end else begin
            case ({en, counter == COMPARE_VAL})
                2'b11: begin
                    counter <= {CNT_WIDTH{1'b0}};
                    clk_out <= ~clk_out;
                end
                2'b10: begin
                    counter <= counter + 1'b1;
                end
                default: begin
                    counter <= counter;
                end
            endcase
        end
    end
endmodule