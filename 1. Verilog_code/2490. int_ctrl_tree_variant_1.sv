//SystemVerilog
module int_ctrl_tree #(
    parameter LEVEL = 3
)(
    input [2**LEVEL-1:0] req_vec,
    output [LEVEL-1:0] grant_code
);
    generate
        if(LEVEL == 1) begin
            // 优化基本情况的逻辑，直接使用最高位作为grant_code
            assign grant_code = req_vec[1];
        end
        else begin
            wire [2**(LEVEL-1)-1:0] upper_req, lower_req;
            wire upper_valid;
            wire [LEVEL-2:0] upper_code, lower_code;
            
            // 分割请求向量
            assign upper_req = req_vec[2**LEVEL-1:2**(LEVEL-1)];
            assign lower_req = req_vec[2**(LEVEL-1)-1:0];
            
            // 使用补码加法实现归约或运算 (|upper_req)
            // 使用补码的特性来检测非零值
            wire [2**(LEVEL-1):0] upper_req_complement;
            wire [2**(LEVEL-1):0] upper_req_sum;
            
            // 将upper_req取反加1得到其补码
            assign upper_req_complement = {1'b1, ~upper_req} + 1'b1;
            // 当原始值非零时，补码相加结果最高位为1
            assign upper_req_sum = {1'b0, upper_req} + upper_req_complement;
            // 非零检测
            assign upper_valid = ~upper_req_sum[2**(LEVEL-1)];
            
            // 递归实例化子树
            int_ctrl_tree #(.LEVEL(LEVEL-1)) upper_tree (
                .req_vec(upper_req),
                .grant_code(upper_code)
            );
            
            int_ctrl_tree #(.LEVEL(LEVEL-1)) lower_tree (
                .req_vec(lower_req),
                .grant_code(lower_code)
            );
            
            // 优化多路复用器结构，使用位连接和条件逻辑
            // 当upper_valid为1时选择upper_code，否则选择lower_code
            assign grant_code[LEVEL-2:0] = upper_valid ? upper_code : lower_code;
            assign grant_code[LEVEL-1] = upper_valid;
        end
    endgenerate
endmodule