module int_ctrl_tree #(
    parameter LEVEL = 3
)(
    input [2**LEVEL-1:0] req_vec,
    output [LEVEL-1:0] grant_code
);
    generate
        if(LEVEL == 1) begin
            assign grant_code = req_vec[1] ? 1'b1 : 1'b0;
        end
        else begin
            wire [2**(LEVEL-1)-1:0] upper_req = req_vec[2**(LEVEL)-1:2**(LEVEL-1)];
            wire [2**(LEVEL-1)-1:0] lower_req = req_vec[2**(LEVEL-1)-1:0];
            wire upper_valid = |upper_req;
            wire [LEVEL-2:0] upper_code, lower_code;
            
            int_ctrl_tree #(.LEVEL(LEVEL-1)) upper_tree (
                .req_vec(upper_req),
                .grant_code(upper_code)
            );
            
            int_ctrl_tree #(.LEVEL(LEVEL-1)) lower_tree (
                .req_vec(lower_req),
                .grant_code(lower_code)
            );
            
            assign grant_code = {upper_valid, upper_valid ? upper_code : lower_code};
        end
    endgenerate
endmodule