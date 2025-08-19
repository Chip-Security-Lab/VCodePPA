//SystemVerilog
module priority_buffer (
    input wire clk,
    input wire rst,  // 添加复位信号
    input wire [7:0] data_a, data_b, data_c,
    input wire valid_a, valid_b, valid_c,
    output reg [7:0] data_out,
    output reg [1:0] source,
    output reg valid_out,  // 添加输出有效信号
    input wire ready_in    // 添加输入就绪信号
);
    // 第一级流水线：输入寄存器阶段
    reg [7:0] data_a_stage1, data_b_stage1, data_c_stage1;
    reg valid_a_stage1, valid_b_stage1, valid_c_stage1;
    reg stage1_valid;
    
    // 第二级流水线：优先级选择阶段
    reg [7:0] selected_data_stage2;
    reg [1:0] selected_source_stage2;
    reg stage2_valid;
    
    // 流水线控制逻辑
    wire stage1_ready, stage2_ready;
    assign stage2_ready = ready_in || !valid_out;
    assign stage1_ready = stage2_ready || !stage2_valid;
    
    // 第一级流水线寄存器
    always @(posedge clk) begin
        if (rst) begin
            data_a_stage1 <= 8'h00;
            data_b_stage1 <= 8'h00;
            data_c_stage1 <= 8'h00;
            valid_a_stage1 <= 1'b0;
            valid_b_stage1 <= 1'b0;
            valid_c_stage1 <= 1'b0;
            stage1_valid <= 1'b0;
        end else if (stage1_ready) begin
            data_a_stage1 <= data_a;
            data_b_stage1 <= data_b;
            data_c_stage1 <= data_c;
            valid_a_stage1 <= valid_a;
            valid_b_stage1 <= valid_b;
            valid_c_stage1 <= valid_c;
            stage1_valid <= valid_a || valid_b || valid_c;
        end
    end
    
    // 第二级流水线：优先级选择逻辑
    always @(posedge clk) begin
        if (rst) begin
            selected_data_stage2 <= 8'h00;
            selected_source_stage2 <= 2'b00;
            stage2_valid <= 1'b0;
        end else if (stage2_ready) begin
            if (stage1_valid) begin
                if (valid_a_stage1) begin
                    selected_data_stage2 <= data_a_stage1;
                    selected_source_stage2 <= 2'b00;
                end else if (valid_b_stage1) begin
                    selected_data_stage2 <= data_b_stage1;
                    selected_source_stage2 <= 2'b01;
                end else if (valid_c_stage1) begin
                    selected_data_stage2 <= data_c_stage1;
                    selected_source_stage2 <= 2'b10;
                end else begin
                    selected_data_stage2 <= 8'h00;
                    selected_source_stage2 <= 2'b00;
                end
                stage2_valid <= 1'b1;
            end else begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // 输出寄存器阶段
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 8'h00;
            source <= 2'b00;
            valid_out <= 1'b0;
        end else if (ready_in) begin
            if (stage2_valid) begin
                data_out <= selected_data_stage2;
                source <= selected_source_stage2;
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule