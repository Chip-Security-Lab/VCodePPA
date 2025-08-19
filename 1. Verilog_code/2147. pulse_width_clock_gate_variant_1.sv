//SystemVerilog
module pulse_width_clock_gate (
    input  wire       clk_in,
    input  wire       rst_n,
    // Valid-Ready 输入接口
    input  wire       trigger_valid,
    input  wire [3:0] width,
    output wire       trigger_ready,
    // Valid-Ready 输出接口
    output wire       clk_out_valid,
    output wire       clk_out,
    input  wire       clk_out_ready
);
    // 增加流水线寄存器
    reg [3:0] counter_stage1;
    reg [3:0] counter_stage2;
    reg enable_stage1;
    reg enable_stage2;
    reg enable_stage3;
    reg [3:0] width_stage1;
    
    // 握手控制寄存器
    reg trigger_accepted;
    reg output_valid;
    reg output_stall;
    
    // 预计算信号
    wire counter_zero_stage1;
    wire counter_one_stage1;
    wire counter_zero_stage2;
    wire counter_one_stage2;
    wire load_counter;
    wire decrement_counter;
    
    // 握手逻辑
    assign trigger_ready = ~output_stall;
    assign load_counter = trigger_valid && trigger_ready && ~trigger_accepted;
    
    // 第一级流水线 - 寄存输入信号和预计算
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            width_stage1 <= 4'd0;
            trigger_accepted <= 1'b0;
        end else begin
            if (trigger_valid && trigger_ready) begin
                width_stage1 <= width;
                trigger_accepted <= 1'b1;
            end else if (counter_zero_stage2) begin
                trigger_accepted <= 1'b0;
            end
        end
    end
    
    // 计算各级计数器状态
    assign counter_zero_stage1 = (counter_stage1 == 4'd0);
    assign counter_one_stage1 = (counter_stage1 == 4'd1);
    assign counter_zero_stage2 = (counter_stage2 == 4'd0);
    assign counter_one_stage2 = (counter_stage2 == 4'd1);
    
    // 计算控制信号
    assign decrement_counter = !counter_zero_stage2;
    
    // 第二级流水线 - 计数器逻辑处理
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage1 <= 4'd0;
        end else if (load_counter) begin
            counter_stage1 <= width_stage1;
        end else if (decrement_counter && !output_stall) begin
            counter_stage1 <= counter_stage2 - 1'b1;
        end
    end
    
    // 第三级流水线 - 计数器和使能寄存
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_stage2 <= 4'd0;
            enable_stage1 <= 1'b0;
        end else if (!output_stall) begin
            counter_stage2 <= counter_stage1;
            enable_stage1 <= load_counter ? 1'b1 : 
                            decrement_counter ? !counter_one_stage2 : enable_stage1;
        end
    end
    
    // 第四级流水线 - 使能信号多级传递以减少扇出负载
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
            enable_stage3 <= 1'b0;
            output_valid <= 1'b0;
            output_stall <= 1'b0;
        end else begin
            if (!output_stall) begin
                enable_stage2 <= enable_stage1;
                enable_stage3 <= enable_stage2;
                output_valid <= enable_stage2;
            end
            
            // 检测输出背压
            if (output_valid && !clk_out_ready) begin
                output_stall <= 1'b1;
            end else if (clk_out_ready) begin
                output_stall <= 1'b0;
            end
        end
    end
    
    // 时钟门控输出
    assign clk_out = clk_in & enable_stage3;
    assign clk_out_valid = output_valid;
endmodule