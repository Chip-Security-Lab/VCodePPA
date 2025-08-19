//SystemVerilog
module AdaptiveITRC #(parameter WIDTH=4) (
    input wire clk, rst,
    input wire [WIDTH-1:0] irq_in,
    input wire ack,
    output reg irq_out,
    output reg [1:0] irq_id
);
    // 流水线阶段信号
    reg [WIDTH-1:0] irq_in_stage1, irq_in_stage2;
    reg [1:0] priority_order_stage1 [0:WIDTH-1];
    reg [1:0] priority_order_stage2 [0:WIDTH-1];
    reg [3:0] occurrence_count [0:WIDTH-1];
    reg [1:0] priority_order [0:WIDTH-1];
    
    // 阶段控制信号
    reg valid_stage1, valid_stage2;
    reg ack_stage1, ack_stage2;
    
    // 中间结果信号
    reg irq_out_stage1, irq_out_stage2;
    reg [1:0] irq_id_stage1, irq_id_stage2;
    
    // 第一级流水线 - 选择器处理
    wire irq_check0, irq_check1, irq_check2, irq_check3;
    reg [1:0] selected_id;
    reg selected_valid;
    
    assign irq_check0 = irq_in[priority_order[0]];
    assign irq_check1 = irq_in[priority_order[1]];
    assign irq_check2 = irq_in[priority_order[2]];
    assign irq_check3 = irq_in[priority_order[3]];
    
    // 优先级选择逻辑 - 第一阶段
    always @(posedge clk) begin
        if (rst) begin
            selected_valid <= 0;
            selected_id <= 0;
            irq_in_stage1 <= 0;
            valid_stage1 <= 0;
            for (int i = 0; i < WIDTH; i++) begin
                priority_order_stage1[i] <= i;
            end
        end else begin
            irq_in_stage1 <= irq_in;
            valid_stage1 <= 1;
            for (int i = 0; i < WIDTH; i++) begin
                priority_order_stage1[i] <= priority_order[i];
            end
            
            // 优先级选择处理
            selected_valid <= 0;
            if (irq_check0) begin
                selected_valid <= 1;
                selected_id <= priority_order[0];
            end else if (irq_check1) begin
                selected_valid <= 1;
                selected_id <= priority_order[1];
            end else if (irq_check2) begin
                selected_valid <= 1;
                selected_id <= priority_order[2];
            end else if (irq_check3) begin
                selected_valid <= 1;
                selected_id <= priority_order[3];
            end
        end
    end
    
    // 第二级流水线 - 计数器更新
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 0;
            irq_out_stage1 <= 0;
            irq_id_stage1 <= 0;
            irq_in_stage2 <= 0;
            ack_stage1 <= 0;
            for (int i = 0; i < WIDTH; i++) begin
                priority_order_stage2[i] <= i;
            end
        end else begin
            valid_stage2 <= valid_stage1;
            irq_out_stage1 <= selected_valid;
            irq_id_stage1 <= selected_id;
            irq_in_stage2 <= irq_in_stage1;
            ack_stage1 <= ack;
            
            for (int i = 0; i < WIDTH; i++) begin
                priority_order_stage2[i] <= priority_order_stage1[i];
            end
            
            // 更新计数器
            if (valid_stage1) begin
                if (irq_in_stage1[0]) occurrence_count[0] <= occurrence_count[0] + 1;
                if (irq_in_stage1[1]) occurrence_count[1] <= occurrence_count[1] + 1;
                if (irq_in_stage1[2]) occurrence_count[2] <= occurrence_count[2] + 1;
                if (irq_in_stage1[3]) occurrence_count[3] <= occurrence_count[3] + 1;
            end
        end
    end
    
    // 第三级流水线 - 优先级更新和输出
    always @(posedge clk) begin
        if (rst) begin
            irq_out <= 0;
            irq_id <= 0;
            irq_out_stage2 <= 0;
            irq_id_stage2 <= 0;
            ack_stage2 <= 0;
            for (int i = 0; i < WIDTH; i++) begin
                occurrence_count[i] <= 0;
                priority_order[i] <= i;
            end
        end else begin
            irq_out_stage2 <= irq_out_stage1;
            irq_id_stage2 <= irq_id_stage1;
            ack_stage2 <= ack_stage1;
            
            // 输出结果
            irq_out <= irq_out_stage2;
            irq_id <= irq_id_stage2;
            if (ack_stage2) irq_out <= 0;
            
            // 更新优先级
            if (valid_stage2) begin
                // 更新第一优先级
                if (occurrence_count[0] > occurrence_count[1] && 
                    occurrence_count[0] > occurrence_count[2] && 
                    occurrence_count[0] > occurrence_count[3]) begin
                    priority_order[0] <= 0;
                    priority_order[1] <= (priority_order_stage2[1] != 0) ? priority_order_stage2[1] : 1;
                    priority_order[2] <= (priority_order_stage2[2] != 0) ? priority_order_stage2[2] : 2;
                    priority_order[3] <= (priority_order_stage2[3] != 0) ? priority_order_stage2[3] : 3;
                end else if (occurrence_count[1] > occurrence_count[0] && 
                           occurrence_count[1] > occurrence_count[2] && 
                           occurrence_count[1] > occurrence_count[3]) begin
                    priority_order[0] <= 1;
                    priority_order[1] <= (priority_order_stage2[1] != 1) ? priority_order_stage2[1] : 0;
                    priority_order[2] <= (priority_order_stage2[2] != 1) ? priority_order_stage2[2] : 2;
                    priority_order[3] <= (priority_order_stage2[3] != 1) ? priority_order_stage2[3] : 3;
                end else if (occurrence_count[2] > occurrence_count[0] && 
                           occurrence_count[2] > occurrence_count[1] && 
                           occurrence_count[2] > occurrence_count[3]) begin
                    priority_order[0] <= 2;
                    priority_order[1] <= (priority_order_stage2[1] != 2) ? priority_order_stage2[1] : 0;
                    priority_order[2] <= (priority_order_stage2[2] != 2) ? priority_order_stage2[2] : 1;
                    priority_order[3] <= (priority_order_stage2[3] != 2) ? priority_order_stage2[3] : 3;
                end else if (occurrence_count[3] > occurrence_count[0] && 
                           occurrence_count[3] > occurrence_count[1] && 
                           occurrence_count[3] > occurrence_count[2]) begin
                    priority_order[0] <= 3;
                    priority_order[1] <= (priority_order_stage2[1] != 3) ? priority_order_stage2[1] : 0;
                    priority_order[2] <= (priority_order_stage2[2] != 3) ? priority_order_stage2[2] : 1;
                    priority_order[3] <= (priority_order_stage2[3] != 3) ? priority_order_stage2[3] : 2;
                end
            end
        end
    end
    
    // 初始化
    initial begin
        for (int i = 0; i < WIDTH; i++) begin
            occurrence_count[i] = 0;
            priority_order[i] = i;
            priority_order_stage1[i] = i;
            priority_order_stage2[i] = i;
        end
        
        irq_out = 0;
        irq_id = 0;
        irq_out_stage1 = 0;
        irq_id_stage1 = 0;
        irq_out_stage2 = 0;
        irq_id_stage2 = 0;
        
        valid_stage1 = 0;
        valid_stage2 = 0;
        ack_stage1 = 0;
        ack_stage2 = 0;
        
        selected_valid = 0;
        selected_id = 0;
    end
endmodule