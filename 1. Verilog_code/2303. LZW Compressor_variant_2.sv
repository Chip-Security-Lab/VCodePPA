//SystemVerilog
module lzw_compressor #(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 8
)(
    input                       clock,
    input                       reset,
    input                       data_valid,
    input      [DATA_WIDTH-1:0] data_in,
    output reg                  out_valid,
    output reg [ADDR_WIDTH-1:0] code_out
);
    // 字典存储
    reg [DATA_WIDTH-1:0] dictionary [0:(2**ADDR_WIDTH)-1];
    reg [ADDR_WIDTH-1:0] dict_ptr;
    
    // 寄存输入数据，减少关键路径延迟
    reg                  data_valid_r;
    reg [DATA_WIDTH-1:0] data_in_r;
    
    // 字典状态信号预计算与流水线化
    reg [ADDR_WIDTH-1:0] next_dict_ptr;
    reg                  dict_full;
    
    // 初始化逻辑
    integer i;
    
    // 预计算下一个字典状态，减少主时序路径延迟
    always @(posedge clock) begin
        if (reset) begin
            next_dict_ptr <= 257; // 预计算初始状态下一个指针值
            dict_full <= 1'b0;
        end
        else begin
            // 提前计算下一个周期可能使用的值
            next_dict_ptr <= (dict_ptr == (2**ADDR_WIDTH)-2) ? dict_ptr : dict_ptr + 1'b1;
            dict_full <= (dict_ptr == (2**ADDR_WIDTH)-2) || dict_full;
        end
    end
    
    // 主处理逻辑
    always @(posedge clock) begin
        if (reset) begin
            // 复位处理
            dict_ptr <= 256; // 初始化字典指针（前256项为单字节值）
            out_valid <= 1'b0;
            data_valid_r <= 1'b0;
            
            // 初始化字典，存储单字节值 - 可并行处理
            for (i = 0; i < 256; i = i + 1)
                dictionary[i] <= i[DATA_WIDTH-1:0];
        end 
        else begin
            // 寄存输入信号，缩短关键路径
            data_valid_r <= data_valid;
            data_in_r <= data_in;
            
            // 根据输入状态更新输出
            out_valid <= data_valid; // 直接映射，减少逻辑层级
            
            if (data_valid) begin
                // 简化数据通路 - 直接更新
                code_out <= data_in;
                
                // 字典更新逻辑 - 使用已计算的next_dict_ptr
                if (!dict_full)
                    dict_ptr <= next_dict_ptr;
            end
        end
    end
endmodule