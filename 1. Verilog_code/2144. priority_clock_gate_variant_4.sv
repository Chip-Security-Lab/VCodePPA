//SystemVerilog
module priority_clock_gate (
    input  wire clk_in,
    input  wire [3:0] prio_vec,
    input  wire [3:0] req_vec,
    output wire [3:0] clk_out
);
    wire [3:0] grant_vec;
    wire [2:0] block_sig;
    
    // 优化布尔表达式，减少逻辑深度和门数量
    assign block_sig[0] = req_vec[0] & prio_vec[0];
    assign block_sig[1] = req_vec[1] & prio_vec[1];
    assign block_sig[2] = req_vec[2] & prio_vec[2];
    
    // 简化的授权逻辑，去除冗余计算
    assign grant_vec[0] = req_vec[0];
    assign grant_vec[1] = req_vec[1] & ~block_sig[0];
    assign grant_vec[2] = req_vec[2] & ~(block_sig[0] | block_sig[1]);
    assign grant_vec[3] = req_vec[3] & ~(block_sig[0] | block_sig[1] | block_sig[2]);
    
    // 时钟门控逻辑
    assign clk_out = grant_vec & {4{clk_in}};
endmodule