//SystemVerilog
module async_arith_shift_right (
    input            clk,      // 时钟信号
    input            rst_n,    // 低电平有效复位信号
    input      [15:0] data_i,  // 输入数据
    input      [3:0]  shamt_i, // 移位量
    input            valid_i,  // 输入有效信号
    output           ready_o,  // 输出就绪信号
    output     [15:0] data_o,  // 输出数据
    output           valid_o   // 输出有效信号
);
    // 内部信号声明
    reg             processing_r;
    reg      [15:0] data_r;
    reg             valid_r;
    wire     [15:0] shift_result;
    wire            start_process;
    wire            process_done;
    
    // 组合逻辑部分
    // 就绪信号生成
    assign ready_o = !processing_r;
    
    // 处理触发条件
    assign start_process = !processing_r && valid_i;
    
    // 完成一个周期后的处理结束信号
    assign process_done = processing_r;
    
    // 算术右移组合逻辑
    assign shift_result = $signed(data_i) >>> shamt_i;
    
    // 输出连接
    assign data_o = data_r;
    assign valid_o = valid_r;
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processing_r <= 1'b0;
        end else begin
            if (start_process) begin
                processing_r <= 1'b1;
            end else if (process_done) begin
                processing_r <= 1'b0;
            end
        end
    end
    
    // 数据寄存器和有效标志
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r <= 16'b0;
            valid_r <= 1'b0;
        end else begin
            valid_r <= 1'b0; // 默认复位valid输出
            
            if (start_process) begin
                data_r <= shift_result;
            end
            
            if (process_done) begin
                valid_r <= 1'b1;
            end
        end
    end
endmodule