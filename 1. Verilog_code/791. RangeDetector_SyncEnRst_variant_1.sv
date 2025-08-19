//SystemVerilog
module RangeDetector_SyncEnRst #(
    parameter WIDTH = 8
)(
    input wire clk, rst_n, en,
    input wire [WIDTH-1:0] data_in,
    input wire [WIDTH-1:0] lower_bound,
    input wire [WIDTH-1:0] upper_bound,
    output reg out_flag
);

    // 预计算范围检测结果
    wire [1:0] range_state;
    assign range_state = {en, (data_in >= lower_bound) && (data_in <= upper_bound)};

    // 使用case语句优化控制流
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            out_flag <= 1'b0;
        else begin
            case (range_state)
                2'b00: out_flag <= out_flag;  // en=0, 保持原值
                2'b01: out_flag <= 1'b0;      // en=0, 范围外
                2'b10: out_flag <= out_flag;  // en=1, 保持原值
                2'b11: out_flag <= 1'b1;      // en=1, 范围内
                default: out_flag <= out_flag;
            endcase
        end
    end
endmodule