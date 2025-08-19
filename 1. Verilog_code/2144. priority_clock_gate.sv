module priority_clock_gate (
    input  wire clk_in,
    input  wire [3:0] prio_vec,
    input  wire [3:0] req_vec,
    output wire [3:0] clk_out
);
    wire [3:0] grant_vec;
    
    assign grant_vec[0] = req_vec[0];
    assign grant_vec[1] = req_vec[1] & ~(req_vec[0] & prio_vec[0]);
    assign grant_vec[2] = req_vec[2] & ~|(req_vec[1:0] & prio_vec[1:0]);
    assign grant_vec[3] = req_vec[3] & ~|(req_vec[2:0] & prio_vec[2:0]);
    
    assign clk_out = {4{clk_in}} & grant_vec;
endmodule