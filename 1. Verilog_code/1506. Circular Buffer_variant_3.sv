//SystemVerilog
// IEEE 1364-2005
module circular_shift_buffer #(parameter SIZE = 8, WIDTH = 4) (
    input wire clk, reset, write_en,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] buffer [0:SIZE-1];
    reg [$clog2(SIZE)-1:0] read_ptr, write_ptr;
    reg [WIDTH-1:0] data_out_reg;
    
    // 预寄存控制信号 - 向后移动寄存器位置
    reg reset_r, write_en_r;
    reg [1:0] ctrl_state;
    
    // 将控制信号提前寄存
    always @(posedge clk) begin
        reset_r <= reset;
        write_en_r <= write_en;
    end
    
    // 使用已寄存的控制信号
    always @(*) begin
        if (reset_r)
            ctrl_state = 2'b01;
        else if (write_en_r)
            ctrl_state = 2'b10;
        else
            ctrl_state = 2'b00;
    end
    
    always @(posedge clk) begin
        case (ctrl_state)
            2'b01: begin // reset
                read_ptr <= 0;
                write_ptr <= 0;
            end
            2'b10: begin // write_en
                buffer[write_ptr] <= data_in;
                write_ptr <= (write_ptr == SIZE-1) ? 0 : write_ptr + 1;
                read_ptr <= (read_ptr == SIZE-1) ? 0 : read_ptr + 1;
            end
            default: begin // 无操作
                // 保持当前状态
            end
        endcase
        
        // 将输出寄存移到时钟域内，避免输出组合路径
        data_out_reg <= buffer[read_ptr];
    end
    
    // 直接使用寄存后的数据输出
    assign data_out = data_out_reg;
endmodule