//SystemVerilog
module Timer_Cascade #(parameter STAGES=2) (
    input clk, rst, en,
    output cascade_done
);
    genvar i;
    wire [STAGES:0] carry;
    assign carry[0] = en;
    assign cascade_done = carry[STAGES];
    
    generate 
        for(i=0; i<STAGES; i=i+1) begin: stage
            reg [3:0] cnt;
            wire cnt_max;
            
            // 优化的计数器逻辑 - 使用非阻塞赋值并优化条件判断
            always @(posedge clk or posedge rst) begin
                if (rst) 
                    cnt <= 4'b0000;
                else if (carry[i]) 
                    cnt <= cnt + 4'b0001;
            end
            
            // 优化的进位检测 - 使用比较器结构直接检测4'hF
            assign cnt_max = (cnt == 4'hF);
            // 优化的进位逻辑 - 使用AND门结构减少逻辑深度
            assign carry[i+1] = carry[i] & cnt_max;
        end
    endgenerate
endmodule