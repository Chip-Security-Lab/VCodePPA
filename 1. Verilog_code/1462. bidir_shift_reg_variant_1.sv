//SystemVerilog
module bidir_shift_reg (
    input  wire       clock,
    input  wire       clear,
    input  wire [7:0] p_data,
    input  wire       load,
    input  wire       shift,
    input  wire       dir,
    input  wire       s_in,
    output reg  [7:0] q
);
    // 控制逻辑阶段 - 解码控制信号
    reg [1:0] operation_type;
    reg       perform_shift_right;
    reg       perform_shift_left;
    
    // 数据准备阶段 - 生成各操作所需的数据
    reg [7:0] shift_right_data;
    reg [7:0] shift_left_data;
    reg [7:0] data_mux_out;
    
    // 第一阶段：控制信号解码
    always @(*) begin
        // 默认操作：保持当前值
        operation_type = 2'b00;  // 00: 保持, 01: 清零, 10: 加载, 11: 移位
        
        if (clear)
            operation_type = 2'b01;
        else if (load)
            operation_type = 2'b10;
        else if (shift)
            operation_type = 2'b11;
            
        // 移位方向控制
        perform_shift_right = (operation_type == 2'b11) && dir;
        perform_shift_left = (operation_type == 2'b11) && !dir;
    end
    
    // 第二阶段：数据路径准备
    always @(*) begin
        // 右移操作数据准备
        shift_right_data = {s_in, q[7:1]};
        
        // 左移操作数据准备
        shift_left_data = {q[6:0], s_in};
    end
    
    // 第三阶段：数据选择逻辑
    always @(*) begin
        case (operation_type)
            2'b01:   data_mux_out = 8'b0;            // 清零操作
            2'b10:   data_mux_out = p_data;          // 加载数据
            2'b11:   data_mux_out = perform_shift_right ? shift_right_data : shift_left_data; // 移位操作
            default: data_mux_out = q;               // 保持当前值
        endcase
    end
    
    // 最终阶段：时序寄存器更新
    always @(posedge clock) begin
        q <= data_mux_out;
    end
    
endmodule