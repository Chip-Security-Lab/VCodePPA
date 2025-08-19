//SystemVerilog
module QoSArbiter #(parameter QW=4) (
    input clk, rst_n,
    input [4*QW-1:0] qos,
    input [3:0] req,
    output reg [3:0] grant
);
    // 优化后的信号定义
    wire [QW-1:0] qos_array [0:3];
    reg [QW-1:0] qos_array_stage1 [0:3];
    reg valid_stage1, valid_stage2;
    reg [3:0] req_stage1, req_stage2;
    reg [QW-1:0] max_qos_stage2;
    reg [1:0] max_index_stage2;
    
    // 优化后的比较结果寄存器
    reg [QW-1:0] max01, max23;
    reg [1:0] max01_index, max23_index;
    
    // 提取QoS值
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin: qos_extract
            assign qos_array[g] = qos[g*QW +: QW];
        end
    endgenerate
    
    // 优化后的第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            req_stage1 <= 4'b0;
            max01 <= {QW{1'b0}};
            max23 <= {QW{1'b0}};
            max01_index <= 2'b00;
            max23_index <= 2'b00;
            qos_array_stage1[0] <= {QW{1'b0}};
            qos_array_stage1[1] <= {QW{1'b0}};
            qos_array_stage1[2] <= {QW{1'b0}};
            qos_array_stage1[3] <= {QW{1'b0}};
        end
        else begin
            valid_stage1 <= 1'b1;
            req_stage1 <= req;
            
            // 优化后的并行比较逻辑
            max01 <= (qos_array[0] >= qos_array[1]) ? qos_array[0] : qos_array[1];
            max01_index <= (qos_array[0] >= qos_array[1]) ? 2'b00 : 2'b01;
            
            max23 <= (qos_array[2] >= qos_array[3]) ? qos_array[2] : qos_array[3];
            max23_index <= (qos_array[2] >= qos_array[3]) ? 2'b10 : 2'b11;
            
            // 保存QoS值
            qos_array_stage1[0] <= qos_array[0];
            qos_array_stage1[1] <= qos_array[1];
            qos_array_stage1[2] <= qos_array[2];
            qos_array_stage1[3] <= qos_array[3];
        end
    end
    
    // 优化后的第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            req_stage2 <= 4'b0;
            max_qos_stage2 <= {QW{1'b0}};
            max_index_stage2 <= 2'b00;
        end
        else begin
            valid_stage2 <= valid_stage1;
            req_stage2 <= req_stage1;
            
            // 优化后的最终比较逻辑
            max_qos_stage2 <= (max01 >= max23) ? max01 : max23;
            max_index_stage2 <= (max01 >= max23) ? max01_index : max23_index;
        end
    end
    
    // 优化后的输出级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= 4'b0;
        end
        else if (valid_stage2) begin
            grant <= req_stage2 & (4'b0001 << max_index_stage2);
        end
        else begin
            grant <= 4'b0;
        end
    end
endmodule