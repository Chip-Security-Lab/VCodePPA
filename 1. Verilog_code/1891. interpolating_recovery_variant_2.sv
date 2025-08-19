//SystemVerilog
module interpolating_recovery #(
    parameter WIDTH = 12
)(
    input wire clk,
    input wire valid_in,
    input wire [WIDTH-1:0] sample_a,
    input wire [WIDTH-1:0] sample_b,
    output reg [WIDTH-1:0] interpolated,
    output reg valid_out
);
    // 定义中间信号
    reg [WIDTH:0] sub_result;
    reg [WIDTH:0] complemented_b;
    wire [WIDTH:0] extended_a, extended_b;
    
    // 扩展输入信号为WIDTH+1位
    assign extended_a = {1'b0, sample_a};
    assign extended_b = {1'b0, sample_b};
    
    always @(posedge clk) begin
        if (valid_in) begin
            // 使用二进制补码算法:
            // 1. 对sample_b取反
            // 2. 加1得到补码
            // 3. sample_a加上sample_b的补码，实际等同于sample_a + sample_b
            complemented_b <= ~extended_b + 1'b1;
            sub_result <= extended_a + (~extended_b + 1'b1);
            
            // 右移一位等效于除以2
            interpolated <= sub_result[WIDTH:1];
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
endmodule