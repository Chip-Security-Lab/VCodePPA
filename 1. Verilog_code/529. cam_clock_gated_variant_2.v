module cam_clock_gated #(parameter WIDTH=8, DEPTH=32)(
    input clk,
    input search_en,
    input write_en,                         
    input [$clog2(DEPTH)-1:0] write_addr,   
    input [WIDTH-1:0] write_data,           
    input [WIDTH-1:0] data_in,
    output reg [DEPTH-1:0] match_flags
);
    reg [WIDTH-1:0] entries [0:DEPTH-1];
    
    // 添加流水线寄存器
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] computation_result [0:DEPTH-1];
    reg [DEPTH-1:0] match_flags_pre;
    reg search_en_reg;
    
    // 写入逻辑保持不变
    always @(posedge clk) begin
        if (write_en)
            entries[write_addr] <= write_data;
    end
    
    // 第一阶段：寄存输入数据和控制信号
    always @(posedge clk) begin
        data_in_reg <= data_in;
        search_en_reg <= search_en;
    end
    
    // 第二阶段：计算补码并存储中间结果
    integer i;
    always @(posedge clk) begin
        if (search_en_reg) begin
            for(i=0; i<DEPTH; i=i+1) begin
                computation_result[i] <= entries[i] + (~data_in_reg + 1'b1);
            end
        end
    end
    
    // 第三阶段：比较结果，生成匹配标志
    always @(posedge clk) begin
        for(i=0; i<DEPTH; i=i+1) begin
            match_flags[i] <= (computation_result[i] == 0);
        end
    end
endmodule