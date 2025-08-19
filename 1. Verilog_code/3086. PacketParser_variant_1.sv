//SystemVerilog
module PacketParser #(
    parameter CRC_POLY = 32'h04C11DB7
)(
    input clk, rst_n,
    input data_valid,
    input [7:0] data_in,
    output reg [31:0] crc_result,
    output reg packet_valid
);
    // 优化状态编码以提高性能
    localparam IDLE = 2'b00, HEADER = 2'b01, PAYLOAD = 2'b10, CRC_CHECK = 2'b11;
    reg [1:0] current_state, next_state;
    
    reg [31:0] crc_reg;
    reg [3:0] byte_counter;

    // 优化的CLA加法器 - 4位分组，减少逻辑深度
    function [31:0] fast_cla_adder;
        input [31:0] a, b;
        reg [31:0] p, g, c;
        reg [31:0] sum;
        integer i, j;
        begin
            // 计算生成和传播信号
            for (i = 0; i < 32; i = i + 1) begin
                p[i] = a[i] ^ b[i];  // 传播信号
                g[i] = a[i] & b[i];  // 生成信号
            end
            
            // 优化的分组进位计算
            c[0] = 0;  // 初始进位为0
            
            // 分组计算进位，降低逻辑深度
            for (i = 0; i < 32; i = i + 4) begin
                // 第一位进位
                c[i+1] = g[i] | (p[i] & c[i]);
                
                // 第二位进位
                if (i+2 < 32)
                    c[i+2] = g[i+1] | (p[i+1] & g[i]) | (p[i+1] & p[i] & c[i]);
                
                // 第三位进位
                if (i+3 < 32)
                    c[i+3] = g[i+2] | (p[i+2] & g[i+1]) | (p[i+2] & p[i+1] & g[i]) | 
                           (p[i+2] & p[i+1] & p[i] & c[i]);
                
                // 第四位进位（下一组的第一位）
                if (i+4 < 32)
                    c[i+4] = g[i+3] | (p[i+3] & g[i+2]) | (p[i+3] & p[i+2] & g[i+1]) | 
                           (p[i+3] & p[i+2] & p[i+1] & g[i]) | (p[i+3] & p[i+2] & p[i+1] & p[i] & c[i]);
            end
            
            // 计算和
            for (i = 0; i < 32; i = i + 1) begin
                sum[i] = p[i] ^ c[i];
            end
            
            fast_cla_adder = sum;
        end
    endfunction

    // 优化的CRC计算函数 - 一次处理多位减少循环次数
    function [31:0] calc_crc;
        input [7:0] data;
        input [31:0] crc;
        reg [31:0] result;
        reg [7:0] msb_xor;
        integer i;
        begin
            result = crc;
            
            // 预先计算数据位与CRC MSB的XOR结果
            msb_xor = data ^ {8{result[31]}};
            
            // 一次处理两位来减少循环迭代
            for (i = 0; i < 8; i = i + 2) begin
                // 处理第一位
                if (msb_xor[7-i] == 1'b1) begin
                    result = (result << 1) ^ CRC_POLY;
                end else begin
                    result = result << 1;
                end
                
                // 处理第二位 (如果有)
                if (i+1 < 8) begin
                    if ((msb_xor[6-i] ^ result[31]) == 1'b1) begin
                        result = (result << 1) ^ CRC_POLY;
                    end else begin
                        result = result << 1;
                    end
                end
            end
            
            calc_crc = result;
        end
    endfunction

    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // 字节计数器控制 - 优化比较链
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_counter <= 0;
        end else if (data_valid && (current_state == HEADER)) begin
            // 优化比较，使用比较器判断是否等于3
            byte_counter <= (byte_counter == 4'd3) ? 4'd0 : (byte_counter + 4'd1);
        end
    end

    // CRC寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_reg <= 32'hFFFFFFFF;
        end else if (current_state == IDLE && next_state == HEADER) begin
            // 重置CRC当进入新的数据包
            crc_reg <= 32'hFFFFFFFF;
        end else if (data_valid && (current_state == PAYLOAD)) begin
            crc_reg <= calc_crc(data_in, crc_reg);
        end
    end

    // CRC结果和包有效信号控制 - 优化比较逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_result <= 0;
            packet_valid <= 0;
        end else begin
            // 默认值
            packet_valid <= 0;
            
            // 优化条件检查，减少逻辑层级
            if (current_state == CRC_CHECK && data_valid) begin
                crc_result <= crc_reg;
                // 直接检查CRC是否为0
                packet_valid <= ~|crc_reg;
            end
        end
    end

    // 状态转移逻辑 - 优化比较结构
    always @(*) begin
        // 默认保持当前状态
        next_state = current_state;
        
        case(current_state)
            IDLE: begin
                // 优化边缘检测
                if (data_valid && (data_in == 8'h55))
                    next_state = HEADER;
            end
            
            HEADER: begin
                // 优化计数器比较
                if (data_valid && (byte_counter == 4'd3))
                    next_state = PAYLOAD;
            end
            
            PAYLOAD: begin
                // 优化终止标记检测
                if (data_valid && (data_in == 8'hAA))
                    next_state = CRC_CHECK;
            end
            
            CRC_CHECK: begin
                // 无条件返回IDLE
                next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule