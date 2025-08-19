module Comparator_Lookahead #(parameter WIDTH = 32) (
    input  [WIDTH-1:0]  num_p,
    input  [WIDTH-1:0]  num_q,
    output              p_gt_q
);
    // 分组并行比较
    localparam GROUP = 4;
    wire [WIDTH/GROUP:0] carry_chain;
    
    assign carry_chain[0] = 1'b0;
    generate
        for (genvar i=0; i<WIDTH; i=i+GROUP) begin : BLOCK
            wire [GROUP-1:0] p_seg = num_p[i+:GROUP];
            wire [GROUP-1:0] q_seg = num_q[i+:GROUP];
            
            // 当前组比较结果
            assign carry_chain[i/GROUP+1] = (p_seg > q_seg) | 
                                           ((p_seg == q_seg) & 
                                            carry_chain[i/GROUP]);
        end
    endgenerate
    
    assign p_gt_q = carry_chain[WIDTH/GROUP];
endmodule