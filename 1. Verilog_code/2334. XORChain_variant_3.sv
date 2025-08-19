//SystemVerilog
module XORChain (
    input  wire        clk,
    input  wire        rst_n,
    // Valid-Ready输入接口
    input  wire [7:0]  din,
    input  wire        valid_in,
    output wire        ready_out,
    // Valid-Ready输出接口
    output reg  [7:0]  dout,
    output wire        valid_out,
    input  wire        ready_in
);

    reg [7:0] prev;
    reg processing;
    
    // 为高扇出信号添加缓冲寄存器
    reg valid_out_reg;
    reg [3:0] valid_out_buffer1, valid_out_buffer2;
    
    // 为高扇出的位信号添加缓冲
    reg b0_buffer1, b0_buffer2;
    reg [7:0] dout_internal;
    
    // Ready信号生成 - 当不在处理状态或输出已被接收时可以接收新数据
    assign ready_out = !processing || (valid_out_reg && ready_in);
    
    // 使用缓冲后的valid_out信号
    assign valid_out = valid_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev <= 8'b0;
            dout_internal <= 8'b0;
            valid_out_reg <= 1'b0;
            processing <= 1'b0;
            
            // 重置缓冲寄存器
            valid_out_buffer1 <= 4'b0;
            valid_out_buffer2 <= 4'b0;
            b0_buffer1 <= 1'b0;
            b0_buffer2 <= 1'b0;
            dout <= 8'b0;
        end
        else begin
            // 输出被接收，清除有效标志
            if (valid_out_reg && ready_in) begin
                valid_out_reg <= 1'b0;
            end
            
            // 新数据到达且可以接收
            if (valid_in && ready_out) begin
                dout_internal <= prev ^ din;
                prev <= din;
                valid_out_reg <= 1'b1;
                processing <= 1'b1;
            end
            
            // 处理完成且输出被接收
            if (processing && valid_out_reg && ready_in) begin
                processing <= 1'b0;
            end
            
            // 更新缓冲寄存器
            valid_out_buffer1 <= {4{valid_out_reg}};
            valid_out_buffer2 <= {4{valid_out_reg}};
            
            // 更新b0缓冲寄存器
            b0_buffer1 <= dout_internal[0];
            b0_buffer2 <= dout_internal[0];
            
            // 更新输出寄存器
            dout <= dout_internal;
        end
    end

endmodule