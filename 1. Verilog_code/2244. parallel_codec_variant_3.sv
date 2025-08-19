//SystemVerilog
module parallel_codec #(
    parameter DW=16, AW=4, DEPTH=8
)(
    input clk, 
    input rst_n,  // 添加复位信号
    input valid,
    input ready,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg ack
);
    // 流水线缓冲区和控制信号
    reg [DW-1:0] buffer [0:DEPTH-1];
    reg [AW-1:0] wr_ptr, rd_ptr;
    
    // 流水线阶段1 - 写入控制信号
    reg valid_stage1, write_enable_stage1;
    reg [DW-1:0] din_stage1;
    reg [AW-1:0] wr_ptr_stage1;
    
    // 流水线阶段2 - 读取控制信号
    reg buffer_not_empty_stage2;
    reg read_enable_stage2;
    reg [AW-1:0] rd_ptr_stage2;
    reg [DW-1:0] dout_stage2;
    
    // 前级组合逻辑
    wire buffer_not_empty;
    wire write_enable;
    wire read_enable;
    
    assign buffer_not_empty = (wr_ptr != rd_ptr);
    assign write_enable = valid && ready;
    assign read_enable = buffer_not_empty && ready;
    
    // 第一级流水线 - 写入阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            write_enable_stage1 <= 1'b0;
            din_stage1 <= {DW{1'b0}};
            wr_ptr_stage1 <= {AW{1'b0}};
            wr_ptr <= {AW{1'b0}};
        end else begin
            valid_stage1 <= valid;
            write_enable_stage1 <= write_enable;
            din_stage1 <= din;
            wr_ptr_stage1 <= wr_ptr;
            
            if (write_enable) begin
                buffer[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end
        end
    end
    
    // 第二级流水线 - 读取阶段
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_not_empty_stage2 <= 1'b0;
            read_enable_stage2 <= 1'b0;
            rd_ptr_stage2 <= {AW{1'b0}};
            rd_ptr <= {AW{1'b0}};
            dout_stage2 <= {DW{1'b0}};
            ack <= 1'b0;
            dout <= {DW{1'b0}};
        end else begin
            buffer_not_empty_stage2 <= buffer_not_empty;
            read_enable_stage2 <= read_enable;
            rd_ptr_stage2 <= rd_ptr;
            
            // 流水线确认信号
            ack <= buffer_not_empty_stage2;
            
            if (read_enable) begin
                dout_stage2 <= buffer[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end
            
            // 最终输出阶段
            if (read_enable_stage2) begin
                dout <= dout_stage2;
            end
        end
    end
endmodule