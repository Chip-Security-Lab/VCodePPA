//SystemVerilog
module bidir_ring_counter(
    input wire clk,
    input wire rst,
    input wire dir, // 0: right, 1: left
    output wire [3:0] q_out
);
    // 寄存器定义
    reg [3:0] q_reg;
    reg [1:0] ctrl_reg;
    reg dir_reg;
    reg rst_reg;
    
    // 组合逻辑输出和输出缓冲
    reg [3:0] q_next;
    reg [3:0] q_out_buf1;
    reg [3:0] q_out_buf2;
    
    // 将输入信号寄存到时钟域内，前向重定时
    always @(posedge clk) begin
        dir_reg <= dir;
        rst_reg <= rst;
        ctrl_reg <= {rst, dir};
    end
    
    // 组合逻辑部分，使用已寄存的控制信号
    always @(*) begin
        case (ctrl_reg)
            2'b10, 2'b11: // Reset has priority regardless of dir
                q_next = 4'b0001;
            2'b01:        // No reset, direction left
                q_next = {q_reg[2:0], q_reg[3]}; // Left shift
            2'b00:        // No reset, direction right
                q_next = {q_reg[0], q_reg[3:1]}; // Right shift
            default:      // For simulation completeness
                q_next = q_reg;
        endcase
    end
    
    // 主寄存器更新
    always @(posedge clk) begin
        q_reg <= q_next;
    end
    
    // 输出缓冲寄存器
    always @(posedge clk) begin
        q_out_buf1 <= q_reg;
        q_out_buf2 <= q_reg;
    end
    
    // 扇出分布 - 每个缓冲驱动一半输出位
    assign q_out[1:0] = q_out_buf1[1:0];
    assign q_out[3:2] = q_out_buf2[3:2];
endmodule