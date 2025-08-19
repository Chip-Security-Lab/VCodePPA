//SystemVerilog
`timescale 1ns / 1ps

module UART_Sync_Basic #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIVISOR = 868  // 100MHz/115200
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire tx_valid,
    output reg  tx_ready,
    output reg  txd,
    input  wire rxd,
    output reg  [DATA_WIDTH-1:0] rx_data,
    output reg  rx_valid
);

// 状态机参数定义
localparam IDLE  = 4'b0001;
localparam START = 4'b0010;
localparam DATA  = 4'b0100;
localparam STOP  = 4'b1000;

reg [3:0] state;
reg [$clog2(CLK_DIVISOR)-1:0] baud_cnt;
reg [3:0] bit_cnt;
reg [DATA_WIDTH+1:0] tx_shift;
reg [2:0] rxd_sync;

// 带状进位加法器4位模块实例化信号
wire [3:0] bit_cnt_next;
wire bit_cnt_carry_out;
wire [3:0] baud_cnt_next;
wire baud_cnt_carry_out;

// 4位带状进位加法器实例，用于bit_cnt自增
CarryLookaheadAdder4 u_bit_cnt_adder (
    .A(bit_cnt),
    .B(4'b0001),
    .Cin(1'b0),
    .Sum(bit_cnt_next),
    .Cout(bit_cnt_carry_out)
);

// 适配baud_cnt位宽的带状进位加法器
localparam BAUD_CNT_WIDTH = $clog2(CLK_DIVISOR);
wire [BAUD_CNT_WIDTH-1:0] baud_cnt_adder_sum;
wire baud_cnt_adder_carry_out;

CarryLookaheadAdderN #(
    .WIDTH(BAUD_CNT_WIDTH)
) u_baud_cnt_adder (
    .A(baud_cnt),
    .B({{(BAUD_CNT_WIDTH-1){1'b0}}, 1'b1}),
    .Cin(1'b0),
    .Sum(baud_cnt_adder_sum),
    .Cout(baud_cnt_adder_carry_out)
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // 复位状态初始化
        state       <= IDLE;
        tx_ready    <= 1'b1;
        txd         <= 1'b1;
        baud_cnt    <= 0;
        bit_cnt     <= 0;
        rx_data     <= 0;
        rx_valid    <= 0;
        rxd_sync    <= 3'b111;
        tx_shift    <= 0;
    end else begin
        // 波特率生成器
        if (baud_cnt == CLK_DIVISOR-1) begin
            baud_cnt <= 0;
        end else begin
            baud_cnt <= baud_cnt_adder_sum;
        end

        // 扁平化状态机
        if (state == IDLE && tx_valid && tx_ready) begin
            state    <= START;
            tx_ready <= 1'b0;
            tx_shift <= {1'b1, tx_data, 1'b0}; // 添加开始位和停止位
        end else if (state == START && baud_cnt == 0) begin
            txd      <= tx_shift[0];
            tx_shift <= {1'b0, tx_shift[DATA_WIDTH+1:1]};
            bit_cnt  <= 0;
            state    <= DATA;
        end else if (state == DATA && baud_cnt == 0 && bit_cnt < DATA_WIDTH) begin
            bit_cnt  <= bit_cnt_next;
            txd      <= tx_shift[0];
            tx_shift <= {1'b0, tx_shift[DATA_WIDTH+1:1]};
            if (bit_cnt == DATA_WIDTH - 1) begin
                state <= STOP;
            end
        end else if (state == STOP && baud_cnt == 0) begin
            txd      <= 1'b1;
            state    <= IDLE;
            tx_ready <= 1'b1;
        end
    end
end

endmodule

// 4位带状进位加法器模块
module CarryLookaheadAdder4(
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire       Cin,
    output wire [3:0] Sum,
    output wire       Cout
);
    wire [3:0] G; // 生成进位
    wire [3:0] P; // 传播进位
    wire [3:1] C;

    assign G = A & B;
    assign P = A ^ B;

    assign C[1] = G[0] | (P[0] & Cin);
    assign C[2] = G[1] | (P[1] & C[1]);
    assign C[3] = G[2] | (P[2] & C[2]);
    assign Cout = G[3] | (P[3] & C[3]);

    assign Sum[0] = P[0] ^ Cin;
    assign Sum[1] = P[1] ^ C[1];
    assign Sum[2] = P[2] ^ C[2];
    assign Sum[3] = P[3] ^ C[3];
endmodule

// N位带状进位加法器模块
module CarryLookaheadAdderN #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] A,
    input  wire [WIDTH-1:0] B,
    input  wire             Cin,
    output wire [WIDTH-1:0] Sum,
    output wire             Cout
);
    wire [WIDTH-1:0] G;
    wire [WIDTH-1:0] P;
    wire [WIDTH:0]   C;

    assign G = A & B;
    assign P = A ^ B;
    assign C[0] = Cin;

    genvar i;
    generate
        for (i=0; i<WIDTH; i=i+1) begin : CLA_N
            assign C[i+1] = G[i] | (P[i] & C[i]);
            assign Sum[i] = P[i] ^ C[i];
        end
    endgenerate

    assign Cout = C[WIDTH];
endmodule