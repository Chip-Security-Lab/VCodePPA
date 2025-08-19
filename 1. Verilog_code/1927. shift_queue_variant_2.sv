//SystemVerilog
module shift_queue #(parameter DW=8, DEPTH=4) (
    input wire clk,
    input wire load,
    input wire shift,
    input wire [DW*DEPTH-1:0] data_in,
    output reg [DW-1:0] data_out
);
    // 原始队列寄存器
    reg [DW-1:0] queue_array [0:DEPTH-1];

    // 一级缓冲寄存器（用于高扇出缓冲）
    reg [DW-1:0] queue_buffer [0:DEPTH-1];
    reg [$clog2(DEPTH):0] idx_reg, idx_buffer;

    // 控制信号缓冲
    reg load_buf, shift_buf;

    integer loop_idx;

    // 控制信号一级缓冲，减小扇出
    always @(posedge clk) begin
        load_buf  <= load;
        shift_buf <= shift;
    end

    // idx缓冲，避免直接大扇出
    always @(posedge clk) begin
        idx_buffer <= idx_reg;
    end

    // queue一级缓冲，减小大扇出
    always @(posedge clk) begin
        for (loop_idx = 0; loop_idx < DEPTH; loop_idx = loop_idx + 1) begin
            queue_buffer[loop_idx] <= queue_array[loop_idx];
        end
    end

    // 主时序逻辑
    always @(posedge clk) begin
        if (load_buf) begin
            for (idx_reg = 0; idx_reg < DEPTH; idx_reg = idx_reg + 1) begin
                queue_array[idx_reg] <= data_in[(DW*idx_reg) +: DW];
            end
            data_out <= data_out; // 保持data_out稳定
        end else if (shift_buf) begin
            data_out <= queue_buffer[DEPTH-1];
            if (DEPTH > 1) begin
                for (idx_reg = DEPTH-1; idx_reg > 0; idx_reg = idx_reg - 1) begin
                    queue_array[idx_reg] <= queue_buffer[idx_reg-1];
                end
            end
            queue_array[0] <= {DW{1'b0}};
        end else begin
            data_out <= data_out; // 保持data_out稳定
        end
    end
endmodule