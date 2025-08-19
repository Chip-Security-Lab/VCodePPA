//SystemVerilog
module ParamHamming_Encoder #(
    parameter DATA_WIDTH = 8
)(
    input clk,
    input en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH+4:0] code_out
);
    // 参数定义
    parameter PARITY_BITS = 4;
    
    // 寄存器声明
    reg [DATA_WIDTH-1:0] data_reg;
    reg [PARITY_BITS-1:0] parity;
    
    // 预计算变量，分解计算过程以平衡路径
    reg [DATA_WIDTH/2-1:0] parity_temp_0_low, parity_temp_0_high;
    reg [DATA_WIDTH/2-1:0] parity_temp_1_low, parity_temp_1_high;
    reg [DATA_WIDTH/2-1:0] parity_temp_2_low, parity_temp_2_high;
    reg [DATA_WIDTH/2-1:0] parity_temp_3_low, parity_temp_3_high;
    
    // 映射表，避免循环和条件判断
    wire [DATA_WIDTH+4:0] position_map;
    assign position_map = {
        4'b0000,             // 高位占位
        {DATA_WIDTH{1'b1}}   // 数据位位置
    };
    
    integer i;
    
    // 存储输入数据
    always @(posedge clk) begin
        if(en) begin
            data_reg <= data_in;
        end
    end
    
    // 计算第0位校验位 (分组)
    always @(posedge clk) begin
        if(en) begin
            parity_temp_0_low = 0;
            parity_temp_0_high = 0;
            for(i=0; i<DATA_WIDTH/2; i=i+1) begin
                if((i+1) & 1) 
                    parity_temp_0_low = parity_temp_0_low ^ data_in[i];
            end
            for(i=DATA_WIDTH/2; i<DATA_WIDTH; i=i+1) begin
                if((i+1) & 1) 
                    parity_temp_0_high = parity_temp_0_high ^ data_in[i];
            end
            parity[0] = ^parity_temp_0_low ^ ^parity_temp_0_high;
        end
    end
    
    // 计算第1位校验位 (分组)
    always @(posedge clk) begin
        if(en) begin
            parity_temp_1_low = 0;
            parity_temp_1_high = 0;
            for(i=0; i<DATA_WIDTH/2; i=i+1) begin
                if((i+1) & 2) 
                    parity_temp_1_low = parity_temp_1_low ^ data_in[i];
            end
            for(i=DATA_WIDTH/2; i<DATA_WIDTH; i=i+1) begin
                if((i+1) & 2) 
                    parity_temp_1_high = parity_temp_1_high ^ data_in[i];
            end
            parity[1] = ^parity_temp_1_low ^ ^parity_temp_1_high;
        end
    end
    
    // 计算第2位校验位 (分组)
    always @(posedge clk) begin
        if(en) begin
            parity_temp_2_low = 0;
            parity_temp_2_high = 0;
            for(i=0; i<DATA_WIDTH/2; i=i+1) begin
                if((i+1) & 4) 
                    parity_temp_2_low = parity_temp_2_low ^ data_in[i];
            end
            for(i=DATA_WIDTH/2; i<DATA_WIDTH; i=i+1) begin
                if((i+1) & 4) 
                    parity_temp_2_high = parity_temp_2_high ^ data_in[i];
            end
            parity[2] = ^parity_temp_2_low ^ ^parity_temp_2_high;
        end
    end
    
    // 计算第3位校验位 (分组)
    always @(posedge clk) begin
        if(en) begin
            parity_temp_3_low = 0;
            parity_temp_3_high = 0;
            for(i=0; i<DATA_WIDTH/2; i=i+1) begin
                if((i+1) & 8) 
                    parity_temp_3_low = parity_temp_3_low ^ data_in[i];
            end
            for(i=DATA_WIDTH/2; i<DATA_WIDTH; i=i+1) begin
                if((i+1) & 8) 
                    parity_temp_3_high = parity_temp_3_high ^ data_in[i];
            end
            parity[3] = ^parity_temp_3_low ^ ^parity_temp_3_high;
        end
    end
    
    // 组装汉明码输出
    always @(posedge clk) begin
        if(en) begin
            // 插入校验位
            code_out[0] <= parity[0];
            code_out[1] <= parity[1];
            code_out[3] <= parity[2];
            code_out[7] <= parity[3];
            
            // 插入数据位 - 固定位置映射
            code_out[2] <= data_in[0];
            code_out[4] <= data_in[1];
            code_out[5] <= data_in[2];
            code_out[6] <= data_in[3];
            code_out[8] <= data_in[4];
            code_out[9] <= data_in[5];
            code_out[10] <= data_in[6];
            code_out[11] <= data_in[7];
        end
    end
    
    // 处理额外的数据位(如果DATA_WIDTH>8)
    always @(posedge clk) begin
        if(en && (DATA_WIDTH > 8)) begin
            for(i=8; i<DATA_WIDTH; i=i+1) begin
                code_out[i+4] <= data_in[i]; // +4是汉明码中的偏移量
            end
        end
    end
endmodule