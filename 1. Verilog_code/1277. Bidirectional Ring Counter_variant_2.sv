//SystemVerilog
module bidir_ring_counter(
    input wire clk,
    input wire rst,
    input wire dir, // 0: right, 1: left
    output wire [3:0] q_out
);
    // 内部寄存器
    reg [3:0] q_internal;
    // 为高扇出信号添加缓冲寄存器
    reg [3:0] q_buffer1, q_buffer2;
    
    // 组合{rst, dir}作为case语句的选择变量
    reg [1:0] control;
    
    always @(*) begin
        control = {rst, dir};
    end
    
    always @(posedge clk) begin
        case(control)
            2'b10, 2'b11: // rst为1，不管dir是什么值
                q_internal <= 4'b0001;
            2'b01: // rst为0，dir为1
                q_internal <= {q_internal[2:0], q_internal[3]}; // Right shift
            2'b00: // rst为0，dir为0
                q_internal <= {q_internal[0], q_internal[3:1]}; // Left shift
            default:
                q_internal <= 4'b0001; // 为了完整性，添加默认情况
        endcase
    end
    
    // 缓冲寄存器，分散驱动负载
    always @(posedge clk) begin
        q_buffer1 <= q_internal;
        q_buffer2 <= q_internal;
    end
    
    // 将输出分配给缓冲寄存器
    // q_out的低两位由q_buffer1驱动，高两位由q_buffer2驱动
    assign q_out[1:0] = q_buffer1[1:0];
    assign q_out[3:2] = q_buffer2[3:2];
    
endmodule