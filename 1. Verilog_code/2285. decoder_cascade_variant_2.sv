//SystemVerilog
module decoder_cascade (
    input wire clk,         // 时钟信号
    input wire rst_n,       // 复位信号
    input wire en_in,       // 输入使能
    input wire [2:0] addr,  // 地址输入
    output wire [7:0] decoded, // 解码输出
    output wire en_out       // 输出使能
);
    // 内部连接信号
    wire en_in_stage1;
    wire [2:0] addr_stage1;
    wire en_stage2;
    wire [7:0] decoded_pre;
    wire [3:0] addr_decode_low;
    wire [3:0] addr_decode_high;

    // 实例化第一级流水线模块
    input_stage input_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .en_in(en_in),
        .addr(addr),
        .en_in_stage1(en_in_stage1),
        .addr_stage1(addr_stage1)
    );

    // 实例化地址解码模块
    address_decoder addr_decoder (
        .addr_stage1(addr_stage1),
        .addr_decode_low(addr_decode_low),
        .addr_decode_high(addr_decode_high)
    );

    // 实例化解码逻辑模块
    decoder_logic decode_logic (
        .en_in_stage1(en_in_stage1),
        .addr_decode_low(addr_decode_low),
        .addr_decode_high(addr_decode_high),
        .decoded_pre(decoded_pre),
        .en_stage2(en_stage2)
    );

    // 实例化输出寄存器模块
    output_stage output_regs (
        .clk(clk),
        .rst_n(rst_n),
        .decoded_pre(decoded_pre),
        .en_stage2(en_stage2),
        .decoded(decoded),
        .en_out(en_out)
    );

endmodule

// 第一级流水线模块 - 处理输入信号寄存
module input_stage (
    input wire clk,
    input wire rst_n,
    input wire en_in,
    input wire [2:0] addr,
    output reg en_in_stage1,
    output reg [2:0] addr_stage1
);
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_in_stage1 <= 1'b0;
            addr_stage1 <= 3'b000;
        end else begin
            en_in_stage1 <= en_in;
            addr_stage1 <= addr;
        end
    end
endmodule

// 地址解码模块 - 将地址解码为控制信号
module address_decoder (
    input wire [2:0] addr_stage1,
    output reg [3:0] addr_decode_low,
    output reg [3:0] addr_decode_high
);
    // 地址预解码 - 将解码逻辑分为两级，减少关键路径长度
    always @(*) begin
        // 先解码低位，将2位地址解码为4选1结构
        case (addr_stage1[1:0])
            2'b00: addr_decode_low = 4'b0001;
            2'b01: addr_decode_low = 4'b0010;
            2'b10: addr_decode_low = 4'b0100;
            2'b11: addr_decode_low = 4'b1000;
        endcase
        
        // 高位选择
        addr_decode_high = {3'b0, addr_stage1[2]};
    end
endmodule

// 解码逻辑模块 - 根据地址和控制信号生成预解码结果
module decoder_logic (
    input wire en_in_stage1,
    input wire [3:0] addr_decode_low,
    input wire [3:0] addr_decode_high,
    output reg [7:0] decoded_pre,
    output reg en_stage2
);
    // 合并解码结果
    always @(*) begin
        decoded_pre = 8'h00;
        en_stage2 = en_in_stage1;
        
        if (en_in_stage1) begin
            if (addr_decode_high[0] == 1'b0) begin
                // 低4位输出
                decoded_pre[3:0] = addr_decode_low;
                decoded_pre[7:4] = 4'b0000;
            end else begin
                // 高4位输出
                decoded_pre[3:0] = 4'b0000;
                decoded_pre[7:4] = addr_decode_low;
            end
        end
    end
endmodule

// 输出寄存器模块 - 最终输出阶段
module output_stage (
    input wire clk,
    input wire rst_n,
    input wire [7:0] decoded_pre,
    input wire en_stage2,
    output reg [7:0] decoded,
    output reg en_out
);
    // 输出寄存器 - 最终数据流阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 8'h00;
            en_out <= 1'b0;
        end else begin
            decoded <= decoded_pre;
            en_out <= en_stage2;
        end
    end
endmodule