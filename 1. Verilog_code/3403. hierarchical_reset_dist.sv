module hierarchical_reset_dist(
    input wire global_rst,
    input wire [1:0] domain_select,
    output wire [7:0] subsystem_rst
);
    wire [3:0] domain_rst;
    assign domain_rst[0] = global_rst;
    assign domain_rst[1] = global_rst;
    assign domain_rst[2] = global_rst & domain_select[0];
    assign domain_rst[3] = global_rst & domain_select[1];
    
    assign subsystem_rst[1:0] = {2{domain_rst[0]}};
    assign subsystem_rst[3:2] = {2{domain_rst[1]}};
    assign subsystem_rst[5:4] = {2{domain_rst[2]}};
    assign subsystem_rst[7:6] = {2{domain_rst[3]}};
endmodule