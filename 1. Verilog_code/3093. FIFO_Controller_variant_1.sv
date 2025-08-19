//SystemVerilog
module FIFO_Controller #(
    parameter DEPTH = 16,
    parameter DATA_WIDTH = 8,
    parameter AF_THRESH = 12,
    parameter AE_THRESH = 4
)(
    input clk, rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output full,
    output empty,
    output almost_full,
    output almost_empty
);
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [4:0] wr_ptr, rd_ptr;
    reg [4:0] count;
    
    // 寄存输入信号以降低输入到第一级寄存器的延迟
    reg wr_en_reg, rd_en_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg full_reg, empty_reg;
    
    // 计算full和empty状态的组合逻辑提前到输入寄存器前
    wire will_be_full = ((count == DEPTH-1) && wr_en && !rd_en) || (full && !(rd_en && !wr_en));
    wire will_be_empty = ((count == 1) && rd_en && !wr_en) || (empty && !(wr_en && !rd_en));
    
    // 寄存输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_en_reg <= 0;
            rd_en_reg <= 0;
            data_in_reg <= 0;
            full_reg <= 0;
            empty_reg <= 1; // 复位时FIFO为空
        end else begin
            wr_en_reg <= wr_en;
            rd_en_reg <= rd_en;
            data_in_reg <= data_in;
            full_reg <= will_be_full;
            empty_reg <= will_be_empty;
        end
    end
    
    // 状态输出逻辑使用寄存的状态
    assign full = full_reg;
    assign empty = empty_reg;
    assign almost_full = (count >= AF_THRESH);
    assign almost_empty = (count <= AE_THRESH);
    
    // 主要FIFO逻辑使用寄存后的信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            case({wr_en_reg && !full_reg, rd_en_reg && !empty_reg})
                2'b10: begin
                    mem[wr_ptr] <= data_in_reg;
                    wr_ptr <= wr_ptr + 1;
                    count <= count + 1;
                end
                2'b01: begin
                    data_out <= mem[rd_ptr];
                    rd_ptr <= rd_ptr + 1;
                    count <= count - 1;
                end
                2'b11: begin
                    mem[wr_ptr] <= data_in_reg;
                    data_out <= mem[rd_ptr];
                    wr_ptr <= wr_ptr + 1;
                    rd_ptr <= rd_ptr + 1;
                end
                default: begin
                    // 保持当前状态
                end
            endcase
        end
    end
endmodule