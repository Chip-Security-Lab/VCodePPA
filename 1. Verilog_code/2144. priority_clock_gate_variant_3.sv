//SystemVerilog
module priority_clock_gate (
    input  wire clk_in,
    input  wire [3:0] prio_vec,
    input  wire [3:0] req_vec,
    output wire [3:0] clk_out
);
    wire [3:0] grant_vec;
    
    // 优化的优先级逻辑
    assign grant_vec[0] = req_vec[0];
    assign grant_vec[1] = req_vec[1] & ~(req_vec[0] & prio_vec[0]);
    assign grant_vec[2] = req_vec[2] & ~((req_vec[0] & prio_vec[0]) | (req_vec[1] & prio_vec[1]));
    assign grant_vec[3] = req_vec[3] & ~((req_vec[0] & prio_vec[0]) | (req_vec[1] & prio_vec[1]) | (req_vec[2] & prio_vec[2]));
    
    // 时钟门控逻辑
    assign clk_out = grant_vec & {4{clk_in}};
endmodule