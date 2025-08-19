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
    reg [WIDTH-1:0] data_in_reg;
    reg [DEPTH-1:0] match_flags_next;
    reg [DEPTH-1:0] match_flags_pipe;
    
    // 写入逻辑
    always @(posedge clk) begin
        if (write_en)
            entries[write_addr] <= write_data;
    end
    
    // 输入数据寄存器
    always @(posedge clk) begin
        if (search_en)
            data_in_reg <= data_in;
    end
    
    // 并行比较逻辑 - 使用借位减法器算法
    genvar i;
    generate
        for (i=0; i<DEPTH; i=i+1) begin : compare_chain
            wire [WIDTH:0] borrow_result;
            wire [WIDTH-1:0] diff;
            wire [WIDTH-1:0] entry_data;
            wire [WIDTH-1:0] search_data;
            
            // 获取当前条目和搜索数据
            assign entry_data = entries[i];
            assign search_data = data_in_reg;
            
            // 借位减法器实现
            assign {borrow_result, diff} = {1'b0, entry_data} - {1'b0, search_data};
            
            // 匹配标志生成 - 当差值为0且无借位时表示匹配
            always @(*) begin
                match_flags_next[i] = (diff == 0) && (borrow_result == 0);
            end
        end
    endgenerate
    
    // 流水线寄存器
    always @(posedge clk) begin
        if (search_en)
            match_flags_pipe <= match_flags_next;
    end
    
    // 输出寄存器
    always @(posedge clk) begin
        if (search_en)
            match_flags <= match_flags_pipe;
    end
endmodule