//SystemVerilog
module reflected_input_crc(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire data_valid,  // Changed to valid signal
    output wire data_ready, // Added ready signal
    output wire [15:0] crc_out
);
    // 内部连接信号
    wire [7:0] reflected_data;
    wire [15:0] next_crc;
    reg [15:0] crc_reg;
    
    // Ready信号生成 - 本模块始终准备接收数据
    assign data_ready = 1'b1;

    // 组合逻辑部分：数据位反转
    data_reflector u_data_reflector(
        .data_in(data_in),
        .reflected_data(reflected_data)
    );

    // 组合逻辑部分：CRC计算
    crc_calculator u_crc_calculator(
        .crc_current(crc_reg),
        .reflected_data(reflected_data),
        .data_valid(data_valid && data_ready), // 握手成功条件
        .next_crc(next_crc)
    );

    // 时序逻辑部分：CRC寄存器更新
    always @(posedge clk) begin
        if (reset)
            crc_reg <= 16'hFFFF;
        else if (data_valid && data_ready) // 只在握手成功时更新
            crc_reg <= next_crc;
    end

    // 输出赋值
    assign crc_out = crc_reg;
endmodule

// 数据位反转模块
module data_reflector(
    input wire [7:0] data_in,
    output wire [7:0] reflected_data
);
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin: reflect
            assign reflected_data[i] = data_in[7-i];
        end
    endgenerate
endmodule

// CRC计算模块
module crc_calculator(
    input wire [15:0] crc_current,
    input wire [7:0] reflected_data,
    input wire data_valid,
    output wire [15:0] next_crc
);
    parameter [15:0] POLY = 16'h8005;
    
    // 优化CRC计算逻辑，减少组合逻辑路径
    wire [15:0] stage1, stage2;
    
    // 分解计算步骤以降低关键路径延迟
    assign stage1 = {crc_current[14:0], 1'b0};
    assign stage2 = crc_current[15] ^ reflected_data[0] ? stage1 ^ POLY : stage1;
    
    // 只在valid高时更新
    assign next_crc = data_valid ? stage2 : crc_current;
endmodule