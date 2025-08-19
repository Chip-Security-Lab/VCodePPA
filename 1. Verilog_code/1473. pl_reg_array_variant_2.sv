//SystemVerilog
module pl_reg_array #(parameter DW=8, AW=4) (
    input clk, we,
    input [AW-1:0] addr,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    reg [AW-1:0] addr_r;
    
    // 引入缓冲寄存器
    reg we_buf1, we_buf2;
    reg [AW-1:0] addr_buf1, addr_buf2;
    reg [DW-1:0] data_in_buf1, data_in_buf2;
    
    // 第一级缓冲
    always @(posedge clk) begin
        we_buf1 <= we;
        addr_buf1 <= addr;
        data_in_buf1 <= data_in;
    end
    
    // 第二级缓冲，分散负载
    always @(posedge clk) begin
        we_buf2 <= we_buf1;
        addr_buf2 <= addr_buf1;
        data_in_buf2 <= data_in_buf1;
    end
    
    // 使用缓冲信号进行内存操作
    always @(posedge clk) begin
        if (we_buf2) mem[addr_buf2] <= data_in_buf2;
        addr_r <= addr_buf2;
    end
    
    // 条件求和减法算法实现
    reg [DW-1:0] mem_data;
    reg [DW-1:0] subtracted_data;
    reg [DW:0] borrow;
    reg [DW-1:0] minuend, subtrahend;
    reg perform_subtract;
    
    always @(posedge clk) begin
        mem_data <= mem[addr_r];
        // 设置减法操作的标志和操作数
        perform_subtract <= 1'b1;
        minuend <= mem[addr_r];
        subtrahend <= 8'h01; // 示例：减去1
    end
    
    always @(posedge clk) begin
        // 条件求和减法实现
        if (perform_subtract) begin
            borrow[0] <= 0;
            for (int i = 0; i < DW; i++) begin
                borrow[i+1] <= (~minuend[i] & subtrahend[i]) | (~minuend[i] & borrow[i]) | (subtrahend[i] & borrow[i]);
                subtracted_data[i] <= minuend[i] ^ subtrahend[i] ^ borrow[i];
            end
            data_out <= subtracted_data;
        end else begin
            data_out <= mem_data;
        end
    end
endmodule