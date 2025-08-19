//SystemVerilog
module shift_reg_barrel_shifter #(
    parameter WIDTH = 16
)(
    input                           clk,
    input                           en,
    input      [WIDTH-1:0]          data_in,
    input      [$clog2(WIDTH)-1:0]  shift_amount,
    output reg [WIDTH-1:0]          data_out
);
    // 位宽相关参数
    localparam LOG2_WIDTH = $clog2(WIDTH);
    
    // 直接实现移位逻辑，避免双重循环和查找表
    reg [WIDTH-1:0] shift_result;
    integer i;
    
    // 优化的移位逻辑实现
    always @(*) begin
        shift_result = {WIDTH{1'b0}}; // 初始化为0
        
        // 单循环实现，减少逻辑深度
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (i + shift_amount < WIDTH) begin
                shift_result[i] = data_in[i + shift_amount];
            end
        end
    end
    
    // 输出寄存器逻辑
    always @(posedge clk) begin
        if (en) begin
            data_out <= shift_result;
        end
    end
endmodule