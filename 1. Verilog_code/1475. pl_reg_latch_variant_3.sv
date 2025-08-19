//SystemVerilog
//IEEE 1364-2005 Verilog标准
// 顶层模块
module pl_reg_latch #(parameter W=8) (
    input wire gate, load,
    input wire [W-1:0] d,
    output wire [W-1:0] q
);
    // 直接使用组合逻辑，避免不必要的子模块实例化
    wire enable = gate & load; // 使用&替代&&，这是位操作符，更适合硬件实现
    
    // 优化的数据路径实现 - 使用借位减法器
    borrow_subtractor_path #(
        .WIDTH(W)
    ) data_unit (
        .d(d),
        .control_enable(enable),
        .q(q)
    );
    
endmodule

// 数据路径子模块 - 使用借位减法算法
module borrow_subtractor_path #(parameter WIDTH=8) (
    input wire [WIDTH-1:0] d,
    input wire control_enable,
    output reg [WIDTH-1:0] q
);
    // 内部借位信号
    reg [WIDTH:0] borrow;
    reg [WIDTH-1:0] result;
    reg [WIDTH-1:0] current_value;
    
    always @(*)
    begin
        if (control_enable) begin
            // 借位减法器实现
            current_value = q; // 当前值
            borrow[0] = 1'b0;  // 初始无借位
            
            for (integer i = 0; i < WIDTH; i = i + 1) begin
                result[i] = current_value[i] ^ d[i] ^ borrow[i];
                borrow[i+1] = (~current_value[i] & d[i]) | (~current_value[i] & borrow[i]) | (d[i] & borrow[i]);
            end
            
            q = result;
        end
        // 保持锁存行为，不添加else分支
    end
    
endmodule