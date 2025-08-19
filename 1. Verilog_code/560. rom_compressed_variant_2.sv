//SystemVerilog
module rom_compressed #(parameter AW=8)(
    input wire clk,                // 时钟信号
    input wire rst_n,              // 复位信号，低电平有效
    input wire [AW-1:0] addr,      // 地址输入
    input wire addr_valid,         // 输入有效信号
    output wire addr_ready,        // 输入就绪信号
    output wire [31:0] data,       // 数据输出
    output wire data_valid,        // 输出有效信号
    input wire data_ready          // 输出就绪信号
);
    // 内部信号和寄存器
    reg [31:0] data_reg;           // 数据输出寄存器
    reg data_valid_reg;            // 输出有效寄存器
    reg addr_ready_reg;            // 输入就绪寄存器
    wire [31:0] mult_result;       // 乘法结果
    wire [31:0] operand_a;
    wire [31:0] operand_b;
    reg [AW-1:0] addr_captured;    // 捕获的地址
    reg processing;                // 处理状态
    
    // 控制逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_valid_reg <= 1'b0;
            addr_ready_reg <= 1'b1;  // 初始状态为就绪
            processing <= 1'b0;
            addr_captured <= {AW{1'b0}};
        end else begin
            // 处理输入握手
            if (addr_ready_reg && addr_valid && !processing) begin
                addr_captured <= addr;  // 捕获地址
                addr_ready_reg <= 1'b0; // 不再接受新输入
                processing <= 1'b1;     // 进入处理状态
            end
            
            // 处理输出握手
            if (processing && !data_valid_reg) begin
                data_valid_reg <= 1'b1;  // 数据准备好
            end else if (data_valid_reg && data_ready) begin
                data_valid_reg <= 1'b0;  // 数据已被接收
                processing <= 1'b0;      // 结束处理
                addr_ready_reg <= 1'b1;  // 准备接受新输入
            end
        end
    end
    
    // 设置乘法器输入
    assign operand_a = {{(32-AW){addr_captured[AW-1]}}, addr_captured};
    assign operand_b = {24'hFFFF00, addr_captured};
    
    // Baugh-Wooley乘法器实例化
    baugh_wooley_multiplier bw_mult (
        .a(operand_a),
        .b(operand_b),
        .result(mult_result)
    );
    
    // 计算数据输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 32'b0;
        end else if (processing && !data_valid_reg) begin
            data_reg <= {addr_captured, ~addr_captured, 8'hFF ^ addr_captured, addr_captured | 8'h0F} ^ 
                        mult_result[15:0] ^ {16'h0, mult_result[31:16]};
        end
    end
    
    // 输出赋值
    assign data = data_reg;
    assign data_valid = data_valid_reg;
    assign addr_ready = addr_ready_reg;
endmodule

// Baugh-Wooley 32位乘法器模块
module baugh_wooley_multiplier (
    input [31:0] a,
    input [31:0] b,
    output [31:0] result
);
    reg [31:0] result_temp;
    reg [63:0] pp [31:0]; // 部分积
    reg [63:0] sum;
    integer i, j;
    
    always @(*) begin
        // 初始化部分积
        for (i = 0; i < 31; i = i + 1) begin
            for (j = 0; j < 31; j = j + 1) begin
                pp[i][j] = a[j] & b[i];
            end
            // Baugh-Wooley算法处理符号位
            pp[i][31] = ~(a[31] & b[i]);
            
            // 扩展符号
            for (j = 32; j < 64; j = j + 1) begin
                pp[i][j] = 1'b0;
            end
            // 第i个部分积左移i位
            pp[i] = pp[i] << i;
        end
        
        // 处理最后一个部分积(i=31)
        for (j = 0; j < 31; j = j + 1) begin
            pp[31][j] = ~(a[j] & b[31]);
        end
        pp[31][31] = a[31] & b[31];
        
        // 扩展符号
        for (j = 32; j < 64; j = j + 1) begin
            pp[31][j] = 1'b0;
        end
        // 左移31位
        pp[31] = pp[31] << 31;
        
        // 部分积相加
        sum = 64'b1; // Baugh-Wooley修正位
        for (i = 0; i < 32; i = i + 1) begin
            sum = sum + pp[i];
        end
        
        // 取结果的低32位
        result_temp = sum[31:0];
    end
    
    assign result = result_temp;
endmodule