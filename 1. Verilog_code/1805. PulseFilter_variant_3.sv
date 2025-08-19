//SystemVerilog
module PulseFilter #(parameter TIMEOUT=8) (
    input clk, rst,
    input in_pulse,
    output reg out_pulse
);
    reg [3:0] cnt;
    
    // 定义并行前缀减法器的内部信号
    wire [3:0] sub_in;
    wire [3:0] sub_out;
    wire [3:0] p_gen [0:3]; // 传播生成信号
    wire [3:0] g_gen [0:3]; // 组生成信号
    wire borrow_out;         // 借位输出
    
    // 输入处理
    assign sub_in = (cnt > 0) ? cnt : 4'b0000;
    
    // 第一阶段：生成初始的p和g信号
    assign p_gen[0] = sub_in ^ 4'b0001; // 与1进行异或
    assign g_gen[0] = ~sub_in & 4'b0001; // 与1进行与非
    
    // 第二阶段：并行前缀计算
    // 第一级传播
    assign p_gen[1][0] = p_gen[0][0];
    assign g_gen[1][0] = g_gen[0][0];
    
    assign p_gen[1][1] = p_gen[0][1] & p_gen[0][0];
    assign g_gen[1][1] = g_gen[0][1] | (p_gen[0][1] & g_gen[0][0]);
    
    assign p_gen[1][2] = p_gen[0][2];
    assign g_gen[1][2] = g_gen[0][2];
    
    assign p_gen[1][3] = p_gen[0][3];
    assign g_gen[1][3] = g_gen[0][3];
    
    // 第二级传播
    assign p_gen[2][0] = p_gen[1][0];
    assign g_gen[2][0] = g_gen[1][0];
    
    assign p_gen[2][1] = p_gen[1][1];
    assign g_gen[2][1] = g_gen[1][1];
    
    assign p_gen[2][2] = p_gen[1][2] & p_gen[1][0];
    assign g_gen[2][2] = g_gen[1][2] | (p_gen[1][2] & g_gen[1][0]);
    
    assign p_gen[2][3] = p_gen[1][3] & p_gen[1][1];
    assign g_gen[2][3] = g_gen[1][3] | (p_gen[1][3] & g_gen[1][1]);
    
    // 第三级传播
    assign p_gen[3][0] = p_gen[2][0];
    assign g_gen[3][0] = g_gen[2][0];
    
    assign p_gen[3][1] = p_gen[2][1];
    assign g_gen[3][1] = g_gen[2][1];
    
    assign p_gen[3][2] = p_gen[2][2];
    assign g_gen[3][2] = g_gen[2][2];
    
    assign p_gen[3][3] = p_gen[2][3] & p_gen[2][2];
    assign g_gen[3][3] = g_gen[2][3] | (p_gen[2][3] & g_gen[2][2]);
    
    // 第三阶段：计算最终结果
    assign sub_out[0] = p_gen[0][0];
    assign sub_out[1] = p_gen[0][1] ^ g_gen[3][0];
    assign sub_out[2] = p_gen[0][2] ^ g_gen[3][1];
    assign sub_out[3] = p_gen[0][3] ^ g_gen[3][2];
    assign borrow_out = g_gen[3][3];
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= 4'b0000;
            out_pulse <= 1'b0;
        end
        else if(in_pulse) begin
            cnt <= TIMEOUT;
            out_pulse <= 1'b1;
        end else begin
            cnt <= (cnt > 0) ? sub_out : 4'b0000;
            out_pulse <= (cnt != 0);
        end
    end
endmodule