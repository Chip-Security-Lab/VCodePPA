//SystemVerilog
module parallel_codec #(
    parameter DW=16, AW=4, DEPTH=8
)(
    input clk, rst_n,
    input valid_in,
    output ready_out,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output valid_out,
    input ready_in
);
    // 内部状态寄存器
    reg [DW-1:0] buffer [0:DEPTH-1];
    reg [AW-1:0] wr_ptr, rd_ptr;
    reg [DW-1:0] din_stage1;
    reg valid_stage1;
    reg [DW-1:0] data_stage2;
    reg valid_stage2;
    reg [DW-1:0] data_stage3;
    reg valid_stage3;
    reg valid_out_reg;
    reg [DW-1:0] dout_reg;
    
    // 组合逻辑信号
    wire fifo_empty, fifo_full;
    wire stage1_ready, stage2_ready, stage3_ready;
    wire write_enable, read_enable;
    wire stage1_valid_next, stage2_valid_next, stage3_valid_next;
    wire output_valid_next;
    
    // FIFO状态组合逻辑
    assign fifo_empty = (wr_ptr == rd_ptr);
    assign fifo_full = ((wr_ptr + 1'b1) == rd_ptr);
    
    // 反压控制组合逻辑
    assign stage3_ready = ready_in || ~valid_stage3;
    assign stage2_ready = stage3_ready || ~valid_stage2;
    assign stage1_ready = stage2_ready || ~valid_stage1;
    
    // 输入就绪信号组合逻辑
    assign ready_out = stage1_ready && ~fifo_full;
    
    // 数据流控制组合逻辑
    assign write_enable = valid_in && ready_out;
    assign read_enable = ~fifo_empty && stage1_ready;
    
    // 有效信号传递组合逻辑
    assign stage1_valid_next = read_enable;
    assign stage2_valid_next = stage2_ready ? valid_stage1 : valid_stage2;
    assign stage3_valid_next = stage3_ready ? valid_stage2 : valid_stage3;
    assign output_valid_next = ready_in ? valid_stage3 : valid_out_reg;
    
    // 输出信号连接
    assign valid_out = valid_out_reg;
    assign dout = dout_reg;
    
    // Stage 1: 输入缓冲时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            wr_ptr <= {AW{1'b0}};
            rd_ptr <= {AW{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            // 写入缓冲区时序逻辑
            if (write_enable) begin
                buffer[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end
            
            // 读取缓冲区时序逻辑
            valid_stage1 <= stage1_valid_next;
            if (read_enable) begin
                din_stage1 <= buffer[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end
    
    // Stage 2: 处理阶段时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid_stage2 <= 1'b0;
            data_stage2 <= {DW{1'b0}};
        end else begin
            valid_stage2 <= stage2_valid_next;
            if (valid_stage1 && stage2_ready) begin
                // 可替换为实际处理逻辑
                data_stage2 <= din_stage1;
            end
        end
    end
    
    // Stage 3: 输出准备时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid_stage3 <= 1'b0;
            data_stage3 <= {DW{1'b0}};
        end else begin
            valid_stage3 <= stage3_valid_next;
            if (valid_stage2 && stage3_ready) begin
                data_stage3 <= data_stage2;
            end
        end
    end
    
    // 输出寄存器时序逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            valid_out_reg <= 1'b0;
            dout_reg <= {DW{1'b0}};
        end else begin
            valid_out_reg <= output_valid_next;
            if (valid_stage3 && ready_in) begin
                dout_reg <= data_stage3;
            end
        end
    end
    
endmodule