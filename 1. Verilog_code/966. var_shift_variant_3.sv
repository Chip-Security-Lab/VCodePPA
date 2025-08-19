//SystemVerilog
module var_shift #(parameter W = 8) (
    input wire clock,
    input wire clear,
    input wire [W-1:0] data,
    input wire [2:0] shift_amt,
    input wire load,
    output wire [W-1:0] result
);
    reg [W-1:0] shift_reg;
    
    // 提取控制逻辑为2位控制信号
    reg [1:0] ctrl;
    always @(*) begin
        case ({clear, load})
            2'b10, 2'b11: ctrl = 2'b00; // 清零优先级最高
            2'b01:        ctrl = 2'b01; // 加载数据
            2'b00:        ctrl = 2'b10; // 移位操作
            default:      ctrl = 2'b00; // 默认清零
        endcase
    end
    
    always @(posedge clock) begin
        case (ctrl)
            2'b00: shift_reg <= {W{1'b0}}; // 清零操作
            2'b01: shift_reg <= data;      // 加载数据
            2'b10: shift_reg <= shift_reg >> shift_amt; // 移位操作
            default: shift_reg <= {W{1'b0}}; // 默认清零
        endcase
    end
    
    assign result = shift_reg;
endmodule