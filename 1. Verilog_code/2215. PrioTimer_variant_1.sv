//SystemVerilog
module PrioTimer #(parameter N=4) (
    input clk, rst_n,
    input [N-1:0] req,
    output reg [$clog2(N)-1:0] grant
);
    // 计数器寄存器
    reg [7:0] cnt [0:N-1];
    // 流水线寄存器 - 第一级
    reg [7:0] cnt_stage1 [0:N-1];
    reg [N-1:0] req_stage1;
    // 流水线寄存器 - 第二级
    reg [7:0] cnt_stage2 [0:N-1];
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    // 临时变量
    integer i;
    reg [$clog2(N)-1:0] grant_temp;
    
    // 流水线第一级 - 更新计数器
    always @(posedge clk) begin
        case (rst_n)
            1'b0: begin
                for(i=0; i<N; i=i+1)
                    cnt[i] <= 8'h00;
                valid_stage1 <= 1'b0;
                req_stage1 <= {N{1'b0}};
            end
            
            1'b1: begin
                for(i=0; i<N; i=i+1)
                    cnt[i] <= req[i] ? (cnt[i] + 8'h01) : cnt[i];
                
                // 传递到下一级
                for(i=0; i<N; i=i+1)
                    cnt_stage1[i] <= cnt[i];
                req_stage1 <= req;
                valid_stage1 <= 1'b1;
            end
        endcase
    end
    
    // 流水线第二级 - 存储中间结果
    always @(posedge clk) begin
        case ({rst_n, valid_stage1})
            2'b00, 2'b01: begin  // rst_n = 0
                for(i=0; i<N; i=i+1)
                    cnt_stage2[i] <= 8'h00;
                valid_stage2 <= 1'b0;
            end
            
            2'b11: begin  // rst_n = 1, valid_stage1 = 1
                for(i=0; i<N; i=i+1)
                    cnt_stage2[i] <= cnt_stage1[i];
                valid_stage2 <= 1'b1;
            end
            
            2'b10: begin  // rst_n = 1, valid_stage1 = 0
                // 保持当前值
            end
        endcase
    end
    
    // 流水线第三级 - 优先级选择
    always @(posedge clk) begin
        case ({rst_n, valid_stage2})
            2'b00, 2'b01: begin  // rst_n = 0
                grant <= {$clog2(N){1'b0}};
            end
            
            2'b11: begin  // rst_n = 1, valid_stage2 = 1
                grant_temp = {$clog2(N){1'b0}}; // 默认值
                
                for(i=N-1; i>=0; i=i-1)
                    if(cnt_stage2[i] > 8'h7F) 
                        grant_temp = i[$clog2(N)-1:0];
                
                grant <= grant_temp;
            end
            
            2'b10: begin  // rst_n = 1, valid_stage2 = 0
                // 保持当前值
            end
        endcase
    end
endmodule