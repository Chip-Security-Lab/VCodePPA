//SystemVerilog
module async_hamming_decoder(
    input clk,                  // 时钟信号
    input rst_n,                // 复位信号
    
    // Valid-Ready 输入接口
    input [11:0] encoded_in,    // 编码数据输入
    input  valid_in,            // 数据有效信号
    output ready_out,           // 准备接收信号
    
    // Valid-Ready 输出接口
    output [7:0] data_out,      // 解码数据输出
    output single_err,          // 单比特错误指示
    output double_err,          // 双比特错误指示
    output valid_out,           // 输出数据有效信号
    input  ready_in             // 下游准备接收信号
);

    // 内部信号
    reg [11:0] encoded_data;
    reg [7:0] data_out_reg;
    reg single_err_reg, double_err_reg;
    reg valid_out_reg;
    reg processing;
    
    // 握手控制逻辑
    assign ready_out = !processing || (valid_out && ready_in);
    assign valid_out = valid_out_reg;
    
    // 计算逻辑
    wire [3:0] syndrome;
    wire parity_check;
    wire single_err_next, double_err_next;
    wire [7:0] data_out_next;
    
    // 校验计算
    assign syndrome[0] = encoded_data[0] ^ encoded_data[2] ^ encoded_data[4] ^ encoded_data[6] ^ encoded_data[8] ^ encoded_data[10];
    assign syndrome[1] = encoded_data[1] ^ encoded_data[2] ^ encoded_data[5] ^ encoded_data[6] ^ encoded_data[9] ^ encoded_data[10];
    assign syndrome[2] = encoded_data[3] ^ encoded_data[4] ^ encoded_data[5] ^ encoded_data[6];
    assign syndrome[3] = encoded_data[7] ^ encoded_data[8] ^ encoded_data[9] ^ encoded_data[10];
    
    // 奇偶校验
    assign parity_check = ^encoded_data;
    
    // 错误检测
    assign single_err_next = |syndrome & ~parity_check;
    assign double_err_next = |syndrome & parity_check;
    
    // 数据输出
    assign data_out_next = {encoded_data[10:7], encoded_data[6:4], encoded_data[2]};
    
    // 输出连接
    assign data_out = data_out_reg;
    assign single_err = single_err_reg;
    assign double_err = double_err_reg;
    
    // 控制逻辑和寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_data <= 12'b0;
            data_out_reg <= 8'b0;
            single_err_reg <= 1'b0;
            double_err_reg <= 1'b0;
            valid_out_reg <= 1'b0;
            processing <= 1'b0;
        end else begin
            // 握手逻辑
            if (valid_in && ready_out && !processing) begin
                // 捕获输入数据
                encoded_data <= encoded_in;
                processing <= 1'b1;
                valid_out_reg <= 1'b0;
            end
            
            // 处理阶段
            if (processing && !valid_out_reg) begin
                // 计算并设置输出
                data_out_reg <= data_out_next;
                single_err_reg <= single_err_next;
                double_err_reg <= double_err_next;
                valid_out_reg <= 1'b1;
            end
            
            // 完成传输
            if (valid_out_reg && ready_in) begin
                valid_out_reg <= 1'b0;
                processing <= 1'b0;
            end
        end
    end

endmodule