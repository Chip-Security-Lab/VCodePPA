//SystemVerilog
module basic_sync_buffer (
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    input wire write_en,
    input wire valid_in,
    output wire ready_out,
    output reg [7:0] data_out,
    output reg valid_out
);
    // 输入寄存器，直接将输入数据寄存
    reg [7:0] data_in_reg;
    reg valid_in_reg;
    reg write_en_reg;
    
    // 输入数据和控制信号寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 8'b0;
            valid_in_reg <= 1'b0;
            write_en_reg <= 1'b0;
        end else if (ready_out) begin
            data_in_reg <= data_in;
            valid_in_reg <= valid_in;
            write_en_reg <= write_en;
        end
    end
    
    // 输出数据寄存器 - 已移动控制逻辑到寄存器前面
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end else if (write_en_reg) begin
            data_out <= data_in_reg;
        end
    end
    
    // 输出有效信号寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in_reg;
        end
    end
    
    // 流水线反压控制 - 始终准备接收新数据
    assign ready_out = 1'b1;
    
endmodule