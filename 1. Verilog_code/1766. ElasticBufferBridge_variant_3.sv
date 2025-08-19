//SystemVerilog
module ElasticBufferBridge #(
    parameter DEPTH=8
)(
    input clk, rst_n,
    input [7:0] data_in,
    input wr_en, rd_en,
    output [7:0] data_out,
    output full, empty
);
    localparam PTR_WIDTH = $clog2(DEPTH);
    
    reg [7:0] buffer [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr, rd_ptr;
    reg [PTR_WIDTH:0] count;
    
    // 寄存数据输出以提高时序性能
    reg [7:0] data_out_reg;
    
    // 初始化
    initial begin
        wr_ptr = 0;
        rd_ptr = 0;
        count = 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            // 写操作
            if (wr_en && !full) begin
                buffer[wr_ptr] <= data_in;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
                
                // 当只有写无读时增加计数
                if (!rd_en || empty)
                    count <= count + 1;
            end
            
            // 读操作
            if (rd_en && !empty) begin
                data_out_reg <= buffer[rd_ptr];
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
                
                // 当只有读无写时减少计数
                if (!wr_en || full)
                    count <= count - 1;
            end
            
            // 同时读写时计数不变
            if (wr_en && rd_en && !full && !empty) begin
                // 计数保持不变，指针已在各自条件中更新
            end
        end
    end
    
    // 使用预先计算的计数而非复杂比较
    assign full = (count == DEPTH);
    assign empty = (count == 0);
    assign data_out = data_out_reg;
endmodule