//SystemVerilog
module crc_adaptive #(parameter MAX_WIDTH=64)(
    input clk,
    input reset,  // 添加复位信号以提高可靠性
    input [MAX_WIDTH-1:0] data,
    input [5:0] width_sel,  // 输入有效位宽
    output reg [31:0] crc
);
    // 拆分长数据路径为多级流水线结构
    // 第一级：4位CRC计算
    reg [31:0] crc_stage1;
    reg [MAX_WIDTH-5:0] data_stage1;
    reg [5:0] width_remain1;
    wire [3:0] data_slice1 = data[3:0];
    
    // 第二级：8位CRC计算
    reg [31:0] crc_stage2;
    reg [MAX_WIDTH-13:0] data_stage2; 
    reg [5:0] width_remain2;
    wire [7:0] data_slice2 = data_stage1[7:0];
    
    // 第三级：16位CRC计算
    reg [31:0] crc_stage3;
    reg [MAX_WIDTH-29:0] data_stage3;
    reg [5:0] width_remain3;
    wire [15:0] data_slice3 = data_stage2[15:0];
    
    // 第四级：剩余位CRC计算
    reg [31:0] crc_final;
    wire [31:0] crc_next;
    
    // 优化的CRC计算函数 - 4位计算单元
    function [31:0] calc_crc_4bit;
        input [31:0] crc_in;
        input [3:0] data_in;
        reg [31:0] crc_temp;
        reg [2:0] j;
        begin
            crc_temp = crc_in;
            for (j = 0; j < 4; j = j + 1) begin
                if (crc_temp[31] ^ data_in[j]) begin
                    crc_temp = {crc_temp[30:0], 1'b0} ^ 32'h04C11DB7;
                end else begin
                    crc_temp = {crc_temp[30:0], 1'b0};
                end
            end
            calc_crc_4bit = crc_temp;
        end
    endfunction
    
    // 优化的CRC计算函数 - 8位计算单元
    function [31:0] calc_crc_8bit;
        input [31:0] crc_in;
        input [7:0] data_in;
        reg [31:0] crc_temp;
        reg [3:0] j;
        begin
            crc_temp = crc_in;
            for (j = 0; j < 8; j = j + 1) begin
                if (crc_temp[31] ^ data_in[j]) begin
                    crc_temp = {crc_temp[30:0], 1'b0} ^ 32'h04C11DB7;
                end else begin
                    crc_temp = {crc_temp[30:0], 1'b0};
                end
            end
            calc_crc_8bit = crc_temp;
        end
    endfunction
    
    // 优化的CRC计算函数 - 16位计算单元
    function [31:0] calc_crc_16bit;
        input [31:0] crc_in;
        input [15:0] data_in;
        reg [31:0] crc_temp;
        reg [4:0] j;
        begin
            crc_temp = crc_in;
            for (j = 0; j < 16; j = j + 1) begin
                if (crc_temp[31] ^ data_in[j]) begin
                    crc_temp = {crc_temp[30:0], 1'b0} ^ 32'h04C11DB7;
                end else begin
                    crc_temp = {crc_temp[30:0], 1'b0};
                end
            end
            calc_crc_16bit = crc_temp;
        end
    endfunction
    
    // 优化的CRC计算函数 - 变长计算单元（处理剩余位）
    function [31:0] calc_crc_remain;
        input [31:0] crc_in;
        input [MAX_WIDTH-29:0] data_in;
        input [5:0] width;
        reg [31:0] crc_temp;
        reg [5:0] j;
        begin
            crc_temp = crc_in;
            for (j = 0; j < width; j = j + 1) begin
                if (crc_temp[31] ^ data_in[j]) begin
                    crc_temp = {crc_temp[30:0], 1'b0} ^ 32'h04C11DB7;
                end else begin
                    crc_temp = {crc_temp[30:0], 1'b0};
                end
            end
            calc_crc_remain = crc_temp;
        end
    endfunction
    
    // 流水线计算逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 复位所有流水线寄存器
            crc <= 32'h0;
            crc_stage1 <= 32'h0;
            crc_stage2 <= 32'h0;
            crc_stage3 <= 32'h0;
            data_stage1 <= {MAX_WIDTH{1'b0}};
            data_stage2 <= {MAX_WIDTH{1'b0}};
            data_stage3 <= {MAX_WIDTH{1'b0}};
            width_remain1 <= 6'b0;
            width_remain2 <= 6'b0;
            width_remain3 <= 6'b0;
        end else begin
            // 第一级：处理前4位
            if (width_sel >= 4) begin
                crc_stage1 <= calc_crc_4bit(crc, data_slice1);
                data_stage1 <= data[MAX_WIDTH-1:4];
                width_remain1 <= width_sel - 4;
            end else begin
                crc_stage1 <= calc_crc_remain(crc, data, width_sel);
                data_stage1 <= {MAX_WIDTH{1'b0}};
                width_remain1 <= 0;
            end
            
            // 第二级：处理接下来8位
            if (width_remain1 >= 8) begin
                crc_stage2 <= calc_crc_8bit(crc_stage1, data_slice2);
                data_stage2 <= data_stage1[MAX_WIDTH-5-1:8];
                width_remain2 <= width_remain1 - 8;
            end else begin
                crc_stage2 <= calc_crc_remain(crc_stage1, data_stage1, width_remain1);
                data_stage2 <= {MAX_WIDTH{1'b0}};
                width_remain2 <= 0;
            end
            
            // 第三级：处理接下来16位
            if (width_remain2 >= 16) begin
                crc_stage3 <= calc_crc_16bit(crc_stage2, data_slice3);
                data_stage3 <= data_stage2[MAX_WIDTH-13-1:16];
                width_remain3 <= width_remain2 - 16;
            end else begin
                crc_stage3 <= calc_crc_remain(crc_stage2, data_stage2, width_remain2);
                data_stage3 <= {MAX_WIDTH{1'b0}};
                width_remain3 <= 0;
            end
            
            // 第四级：处理剩余位
            crc <= calc_crc_remain(crc_stage3, data_stage3, width_remain3);
        end
    end
endmodule