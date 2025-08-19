//SystemVerilog
//IEEE 1364-2005
module RepeatDetector #(parameter WIN=8) (
    input clk, rst_n,
    input [7:0] data_in,
    input valid_in,
    output ready_out,
    output reg valid_out,
    output reg [15:0] code_out
);
    // 历史数据存储
    reg [7:0] history [0:WIN-1];
    reg [3:0] ptr;
    
    // 流水线寄存器 - 阶段1
    reg [7:0] data_stage1;
    reg valid_stage1;
    reg [3:0] ptr_stage1;
    reg [7:0] history_data [0:1]; // 存储需要比较的历史数据
    
    // 流水线寄存器 - 阶段2
    reg [7:0] data_stage2;
    reg valid_stage2;
    reg [7:0] prev_data_stage2; // 移到阶段2的比较寄存器
    
    // 流水线寄存器 - 阶段3
    reg [7:0] data_stage3;
    reg valid_stage3;
    reg repeat_detected_stage3;
    
    // 流水线控制信号
    assign ready_out = 1'b1; // 当前设计始终可接收新数据
    
    integer i;
    
    // 重置逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // 复位历史数据存储
            for(i=0; i<WIN; i=i+1)
                history[i] <= 8'h0;
            ptr <= 4'h0;
            
            // 复位流水线寄存器
            data_stage1 <= 8'h0;
            valid_stage1 <= 1'b0;
            ptr_stage1 <= 4'h0;
            history_data[0] <= 8'h0;
            history_data[1] <= 8'h0;
            
            data_stage2 <= 8'h0;
            valid_stage2 <= 1'b0;
            prev_data_stage2 <= 8'h0;
            
            data_stage3 <= 8'h0;
            valid_stage3 <= 1'b0;
            repeat_detected_stage3 <= 1'b0;
            
            valid_out <= 1'b0;
            code_out <= 16'h0;
        end
    end
    
    // 流水线阶段1: 数据接收和历史数据准备
    always @(posedge clk) begin
        if(rst_n) begin
            if(valid_in) begin
                // 存储当前数据
                history[ptr] <= data_in;
                
                // 传递到阶段1
                data_stage1 <= data_in;
                ptr_stage1 <= ptr;
                valid_stage1 <= 1'b1;
                
                // 获取比较所需的数据
                if(ptr > 0)
                    history_data[0] <= history[ptr-1];
                else
                    history_data[0] <= history[WIN-1];
                    
                history_data[1] <= data_in;
                
                // 更新指针
                ptr <= (ptr == WIN-1) ? 0 : ptr + 1;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段2: 传递历史数据
    always @(posedge clk) begin
        if(rst_n) begin
            if(valid_stage1) begin
                data_stage2 <= data_stage1;
                valid_stage2 <= valid_stage1;
                prev_data_stage2 <= history_data[0];
            end
            else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段3: 重复检测
    always @(posedge clk) begin
        if(rst_n) begin
            if(valid_stage2) begin
                data_stage3 <= data_stage2;
                valid_stage3 <= valid_stage2;
                
                // 检测重复 - 被切分到单独的阶段
                repeat_detected_stage3 <= (data_stage2 == prev_data_stage2);
            end
            else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // 流水线阶段4: 输出生成
    always @(posedge clk) begin
        if(rst_n) begin
            valid_out <= valid_stage3;
            
            if(valid_stage3) begin
                // 使用三元运算符简化代码而不影响关键路径
                code_out <= repeat_detected_stage3 ? {8'hFF, data_stage3} : {8'h00, data_stage3};
            end
        end
    end
endmodule