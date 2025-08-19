//SystemVerilog
module shift_reg_barrel_shifter #(
    parameter WIDTH = 16
)(
    input                          clk,
    input                          rst_n,          // 复位信号
    input                          valid_in,       // 输入有效信号
    output                         ready_in,       // 输入就绪信号
    input      [WIDTH-1:0]         data_in,
    input      [$clog2(WIDTH)-1:0] shift_amount,
    output                         valid_out,      // 输出有效信号
    input                          ready_out,      // 输出就绪信号
    output     [WIDTH-1:0]         data_out
);
    // 定义位移位数为常量
    localparam LOG2_WIDTH = $clog2(WIDTH);
    
    // 数据流水线寄存器
    reg [WIDTH-1:0] stage0_data, stage1_data, stage2_data, stage3_data, stage4_data;
    
    // 流水线控制信号
    reg stage0_valid, stage1_valid, stage2_valid, stage3_valid, stage4_valid, output_valid;
    wire stage0_ready, stage1_ready, stage2_ready, stage3_ready, stage4_ready;
    
    // 保存每级的移位量
    reg [$clog2(WIDTH)-1:0] stage0_shift, stage1_shift, stage2_shift, stage3_shift, stage4_shift;
    
    // 向后传播ready信号
    assign stage4_ready = ready_out || !output_valid;
    assign stage3_ready = stage4_ready || !stage4_valid;
    assign stage2_ready = stage3_ready || !stage3_valid;
    assign stage1_ready = stage2_ready || !stage2_valid;
    assign stage0_ready = stage1_ready || !stage1_valid;
    assign ready_in = stage0_ready || !stage0_valid;
    
    // 输出有效信号
    assign valid_out = output_valid;
    
    // 流水线第0级 - 输入阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage0_valid <= 1'b0;
            stage0_data <= {WIDTH{1'b0}};
            stage0_shift <= {LOG2_WIDTH{1'b0}};
        end else if (ready_in && valid_in) begin
            stage0_valid <= 1'b1;
            stage0_data <= data_in;
            stage0_shift <= shift_amount;
        end else if (stage0_ready) begin
            stage0_valid <= 1'b0;
        end
    end
    
    // 流水线第1级 - 1位移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_valid <= 1'b0;
            stage1_data <= {WIDTH{1'b0}};
            stage1_shift <= {LOG2_WIDTH{1'b0}};
        end else if (stage0_ready && stage0_valid) begin
            stage1_valid <= 1'b1;
            stage1_data <= stage0_shift[0] ? {stage0_data[WIDTH-2:0], 1'b0} : stage0_data;
            stage1_shift <= stage0_shift;
        end else if (stage1_ready) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 流水线第2级 - 2位移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_valid <= 1'b0;
            stage2_data <= {WIDTH{1'b0}};
            stage2_shift <= {LOG2_WIDTH{1'b0}};
        end else if (stage1_ready && stage1_valid) begin
            stage2_valid <= 1'b1;
            if (LOG2_WIDTH > 1)
                stage2_data <= stage1_shift[1] ? {stage1_data[WIDTH-3:0], 2'b0} : stage1_data;
            else
                stage2_data <= stage1_data;
            stage2_shift <= stage1_shift;
        end else if (stage2_ready) begin
            stage2_valid <= 1'b0;
        end
    end
    
    // 流水线第3级 - 4位移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_valid <= 1'b0;
            stage3_data <= {WIDTH{1'b0}};
            stage3_shift <= {LOG2_WIDTH{1'b0}};
        end else if (stage2_ready && stage2_valid) begin
            stage3_valid <= 1'b1;
            if (LOG2_WIDTH > 2)
                stage3_data <= stage2_shift[2] ? {stage2_data[WIDTH-5:0], 4'b0} : stage2_data;
            else
                stage3_data <= stage2_data;
            stage3_shift <= stage2_shift;
        end else if (stage3_ready) begin
            stage3_valid <= 1'b0;
        end
    end
    
    // 流水线第4级 - 8位移位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_valid <= 1'b0;
            stage4_data <= {WIDTH{1'b0}};
            stage4_shift <= {LOG2_WIDTH{1'b0}};
        end else if (stage3_ready && stage3_valid) begin
            stage4_valid <= 1'b1;
            if (LOG2_WIDTH > 3)
                stage4_data <= stage3_shift[3] ? {stage3_data[WIDTH-9:0], 8'b0} : stage3_data;
            else
                stage4_data <= stage3_data;
            stage4_shift <= stage3_shift;
        end else if (stage4_ready) begin
            stage4_valid <= 1'b0;
        end
    end
    
    // 输出阶段 - 16位移位和最终输出
    reg [WIDTH-1:0] output_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            output_valid <= 1'b0;
            output_data <= {WIDTH{1'b0}};
        end else if (stage4_ready && stage4_valid) begin
            output_valid <= 1'b1;
            
            if (LOG2_WIDTH > 4)
                output_data <= stage4_shift[4] ? {stage4_data[WIDTH-17:0], 16'b0} : stage4_data;
            else
                output_data <= stage4_data;
        end else if (ready_out) begin
            output_valid <= 1'b0;
        end
    end
    
    // 输出赋值
    assign data_out = output_data;
    
endmodule