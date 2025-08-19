//SystemVerilog
// IEEE 1364-2005 Verilog standard
module self_checking_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_index,
    output reg valid,
    output reg error
);
    reg [$clog2(WIDTH)-1:0] expected_priority;
    reg [WIDTH-1:0] priority_mask;
    wire any_data_valid = |data_in;
    
    // 先行借位实现的优先级查找逻辑
    // 使用先行借位的思想检测最高位的1
    function automatic [$clog2(WIDTH)-1:0] find_priority_with_borrow;
        input [WIDTH-1:0] data;
        reg [WIDTH-1:0] borrow_chain;
        reg [WIDTH-1:0] result_mask;
        integer i;
        begin
            // 初始化借位链
            borrow_chain = ~data;
            // 计算借位传播
            for (i = 1; i < WIDTH; i = i + 1) begin
                borrow_chain[i] = borrow_chain[i] & borrow_chain[i-1];
            end
            // 借位结果取反并移位得到结果掩码
            result_mask = ~borrow_chain & data;
            
            // 编码最高位的1
            find_priority_with_borrow = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (result_mask[i]) find_priority_with_borrow = i[$clog2(WIDTH)-1:0];
            end
        end
    endfunction
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_index <= 0;
            valid <= 0;
            error <= 0;
            expected_priority <= 0;
            priority_mask <= 0;
        end else begin
            valid <= any_data_valid;
            
            // 使用先行借位函数计算期望优先级
            expected_priority <= find_priority_with_borrow(data_in);
            
            // 生成一位热码优先级掩码用于验证
            priority_mask <= any_data_valid ? (1'b1 << find_priority_with_borrow(data_in)) : 0;
            
            // 分配输出
            priority_index <= find_priority_with_borrow(data_in);
            
            // 自检逻辑
            error <= any_data_valid && (data_in[find_priority_with_borrow(data_in)] == 1'b0);
        end
    end
endmodule