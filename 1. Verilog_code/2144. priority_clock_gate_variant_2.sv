//SystemVerilog
module priority_clock_gate (
    input  wire clk_in,
    input  wire [3:0] prio_vec,
    input  wire [3:0] req_vec,
    output wire [3:0] clk_out
);
    wire [3:0] grant_vec;
    wire [3:0] mask;
    
    // 创建优先级掩码，简化逻辑表达式
    assign mask[0] = 1'b1;
    assign mask[1] = ~(req_vec[0] & prio_vec[0]);
    assign mask[2] = ~(req_vec[0] & prio_vec[0] | req_vec[1] & prio_vec[1]);
    assign mask[3] = ~(req_vec[0] & prio_vec[0] | req_vec[1] & prio_vec[1] | req_vec[2] & prio_vec[2]);
    
    // 简化授权向量逻辑
    assign grant_vec = req_vec & mask;
    
    // 时钟门控逻辑
    assign clk_out = {4{clk_in}} & grant_vec;
endmodule