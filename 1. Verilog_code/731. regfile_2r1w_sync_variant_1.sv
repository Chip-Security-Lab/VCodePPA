//SystemVerilog
module regfile_2r1w_sync #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 32
)(
    input clk,
    input rst_n,
    input wr_en,
    input [ADDR_WIDTH-1:0] rd_addr0,
    input [ADDR_WIDTH-1:0] rd_addr1,
    input [ADDR_WIDTH-1:0] wr_addr,
    input [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data0,
    output reg [DATA_WIDTH-1:0] rd_data1
);
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
integer i;

// 创建控制信号组合
reg [1:0] ctrl_state;
always @(*) begin
    ctrl_state = {rst_n, wr_en};
end

// 为高扇出信号添加缓冲寄存器
reg [DATA_WIDTH-1:0] wr_data_buf;
reg [ADDR_WIDTH-1:0] wr_addr_buf;

always @(posedge clk) begin
    if (rst_n == 1'b0) begin
        wr_data_buf <= 0;
        wr_addr_buf <= 0;
    end else if (wr_en) begin
        wr_data_buf <= wr_data;
        wr_addr_buf <= wr_addr;
    end
end

always @(posedge clk) begin
    case(ctrl_state)
        2'b00, 2'b01: begin // !rst_n
            i = 0; // 初始化放在循环前
            while (i < DEPTH) begin
                mem[i] <= 0;
                i = i + 1; // 迭代步骤放在循环体末尾
            end
        end
        2'b11: begin // rst_n && wr_en
            mem[wr_addr_buf] <= wr_data_buf;
        end
        default: begin // 2'b10: rst_n && !wr_en
            // 保持当前值，不做任何操作
        end
    endcase
end

always @(posedge clk) begin
    rd_data0 <= mem[rd_addr0];
    rd_data1 <= mem[rd_addr1];
end
endmodule