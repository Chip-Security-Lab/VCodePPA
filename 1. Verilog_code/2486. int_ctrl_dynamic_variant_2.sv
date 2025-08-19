//SystemVerilog
module int_ctrl_dynamic #(
    parameter N_SRC = 8
)(
    input clk, rst,
    input [N_SRC-1:0] req,
    input [N_SRC*8-1:0] prio_map,
    output reg [2:0] curr_pri
);
    // 寄存器化输入信号
    reg [N_SRC-1:0] req_reg;
    reg [N_SRC*8-1:0] prio_map_reg;
    
    // 中间信号声明
    reg [2:0] calc_pri;
    reg priority_found;
    
    // 输入信号寄存器化 - 前向寄存器重定时
    always @(posedge clk) begin
        if (rst) begin
            req_reg <= {N_SRC{1'b0}};
            prio_map_reg <= {(N_SRC*8){1'b0}};
        end
        else begin
            req_reg <= req;
            prio_map_reg <= prio_map;
        end
    end
    
    // 优先级计算逻辑 - 组合逻辑块
    // 将复杂的嵌套循环从时序逻辑中分离出来
    always @(*) begin
        calc_pri = 3'b0;
        priority_found = 1'b0;
        
        // 从最高优先级开始扫描
        for (integer i = 7; i >= 0 && !priority_found; i = i - 1) begin
            for (integer j = 0; j < N_SRC && !priority_found; j = j + 1) begin
                if (req_reg[j] & prio_map_reg[i*N_SRC+j]) begin
                    calc_pri = i[2:0];
                    priority_found = 1'b1;
                end
            end
        end
    end
    
    // 优先级寄存器更新 - 时序逻辑块
    always @(posedge clk) begin
        if (rst) begin
            curr_pri <= 3'b0;
        end
        else begin
            curr_pri <= calc_pri;
        end
    end
    
endmodule