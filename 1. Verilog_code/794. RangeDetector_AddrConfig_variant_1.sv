//SystemVerilog
module RangeDetector_AddrConfig #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input clk, rst_n,
    input [DATA_WIDTH-1:0] data_in,
    input [ADDR_WIDTH-1:0] addr,
    output reg out_of_range
);
    reg [DATA_WIDTH-1:0] lower_bounds [2**ADDR_WIDTH-1:0];
    reg [DATA_WIDTH-1:0] upper_bounds [2**ADDR_WIDTH-1:0];
    
    // 注册当前需要比较的边界值
    reg [DATA_WIDTH-1:0] current_lower, current_upper;
    
    // 并行比较信号
    reg lower_check, upper_check;
    
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            current_lower <= 0;
            current_upper <= 0;
            lower_check <= 1'b0;
            upper_check <= 1'b0;
            out_of_range <= 1'b0;
        end else begin
            // 边界值获取
            current_lower <= lower_bounds[addr];
            current_upper <= upper_bounds[addr];
            
            // 分解比较操作到两个独立检查 - 提高时序性能
            lower_check <= (data_in < current_lower);
            upper_check <= (data_in > current_upper);
            
            // 使用并行比较结果
            out_of_range <= lower_check || upper_check;
        end
    end
endmodule