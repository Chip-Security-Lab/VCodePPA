//SystemVerilog
module UART_DualClock #(
    parameter DATA_WIDTH = 9,
    parameter FIFO_DEPTH = 16,
    parameter SYNC_STAGES = 3
)(
    input  wire tx_clk,
    input  wire rx_clk,
    input  wire sys_rst,
    // 系统接口
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire wr_en,
    output wire full,
    // 物理接口
    output wire txd,
    input  wire rxd,
    // 状态指示
    output wire frame_error,
    output wire parity_error
);

    // Internal signals
    wire                        wr_en_sampled;
    wire [DATA_WIDTH-1:0]       data_in_sampled;
    wire [$clog2(FIFO_DEPTH):0] wr_ptr_next, wr_ptr_reg;
    wire [$clog2(FIFO_DEPTH):0] rd_ptr_next, rd_ptr_reg;
    wire [DATA_WIDTH:0]         fifo_write_data;
    wire [DATA_WIDTH:0]         wr_ptr_gray_comb, rd_ptr_gray_comb;
    wire                        full_comb;
    wire                        frame_error_comb;
    wire                        parity_error_comb;
    wire                        txd_comb;
    wire                        frame_err_reg, parity_err_reg;

    // Input Registers for write enable and data in
    UART_DualClock_input_regs #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_input_regs (
        .clk              (tx_clk),
        .rst              (sys_rst),
        .wr_en_in         (wr_en),
        .data_in_in       (data_in),
        .wr_en_out        (wr_en_sampled),
        .data_in_out      (data_in_sampled)
    );

    // FIFO Write Data Combination
    assign fifo_write_data = {UART_DualClock_parity_gen(data_in_sampled[DATA_WIDTH-2:0]), data_in_sampled};

    // Write Pointer Next Combination
    assign wr_ptr_next = (wr_en_sampled && !full_comb) ? (wr_ptr_reg + 1'b1) : wr_ptr_reg;

    // Gray Code Combination
    assign wr_ptr_gray_comb = UART_DualClock_bin2gray(wr_ptr_reg);
    assign rd_ptr_gray_comb = UART_DualClock_bin2gray(rd_ptr_reg);

    // Full Flag Combination
    assign full_comb = ((wr_ptr_reg[$clog2(FIFO_DEPTH)] != rd_ptr_reg[$clog2(FIFO_DEPTH)]) &&
                        (wr_ptr_reg[$clog2(FIFO_DEPTH)-1:0] == rd_ptr_reg[$clog2(FIFO_DEPTH)-1:0]));

    // Output assignments
    assign full         = full_comb;
    assign frame_error  = frame_err_reg;
    assign parity_error = parity_err_reg;
    assign txd          = txd_comb;

    // FIFO Memory and Write Pointer Sequential Logic
    UART_DualClock_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_fifo (
        .clk              (tx_clk),
        .rst              (sys_rst),
        .wr_en            (wr_en_sampled),
        .full             (full_comb),
        .fifo_write_data  (fifo_write_data),
        .wr_ptr_next      (wr_ptr_next),
        .wr_ptr_reg_out   (wr_ptr_reg),
        .fifo_mem_out     (), // Not used externally
        .txd_out          (txd_comb)
    );

    // Read Pointer and Error Registers Sequential Logic
    UART_DualClock_rxdomain #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) u_rxdomain (
        .clk              (rx_clk),
        .rst              (sys_rst),
        .rd_ptr_reg_out   (rd_ptr_reg),
        .frame_err_reg_out(frame_err_reg),
        .parity_err_reg_out(parity_err_reg)
        // Add connections as needed for rxd, data output, etc.
    );

    // Functions
    function [DATA_WIDTH:0] UART_DualClock_bin2gray;
        input [DATA_WIDTH:0] bin;
        begin
            UART_DualClock_bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function UART_DualClock_parity_gen;
        input [DATA_WIDTH-2:0] data;
        begin
            UART_DualClock_parity_gen = ^data;
        end
    endfunction

endmodule

// Input Register Module
module UART_DualClock_input_regs #(
    parameter DATA_WIDTH = 9
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               wr_en_in,
    input  wire [DATA_WIDTH-1:0] data_in_in,
    output reg                wr_en_out,
    output reg [DATA_WIDTH-1:0] data_in_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_en_out   <= 1'b0;
            data_in_out <= {DATA_WIDTH{1'b0}};
        end else begin
            wr_en_out   <= wr_en_in;
            data_in_out <= data_in_in;
        end
    end
endmodule

// FIFO Write Pointer and Memory Module
module UART_DualClock_fifo #(
    parameter DATA_WIDTH = 9,
    parameter FIFO_DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  wr_en,
    input  wire                  full,
    input  wire [DATA_WIDTH:0]   fifo_write_data,
    input  wire [$clog2(FIFO_DEPTH):0] wr_ptr_next,
    output reg  [$clog2(FIFO_DEPTH):0] wr_ptr_reg_out,
    output wire [DATA_WIDTH:0]   fifo_mem_out [0:FIFO_DEPTH-1],
    output reg                   txd_out
);
    reg [DATA_WIDTH:0] fifo_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr_reg;

    assign fifo_mem_out = fifo_mem;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr_reg   <= 0;
            txd_out      <= 1'b1;
        end else begin
            if (wr_en && !full) begin
                fifo_mem[wr_ptr_reg[$clog2(FIFO_DEPTH)-1:0]] <= fifo_write_data;
                wr_ptr_reg <= wr_ptr_next;
            end
            // txd_out logic can be updated here as needed
        end
    end

    always @(*) begin
        wr_ptr_reg_out = wr_ptr_reg;
    end
endmodule

// RX Domain: Read Pointer and Error Registers
module UART_DualClock_rxdomain #(
    parameter DATA_WIDTH = 9,
    parameter FIFO_DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,
    output reg  [$clog2(FIFO_DEPTH):0] rd_ptr_reg_out,
    output reg                   frame_err_reg_out,
    output reg                   parity_err_reg_out
);
    reg [$clog2(FIFO_DEPTH):0] rd_ptr_reg;
    reg frame_err_reg, parity_err_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rd_ptr_reg      <= 0;
            frame_err_reg   <= 1'b0;
            parity_err_reg  <= 1'b0;
        end else begin
            // Add RX domain logic here for pointer and error update
            // For now, keep as is for structural separation
        end
    end

    always @(*) begin
        rd_ptr_reg_out      = rd_ptr_reg;
        frame_err_reg_out   = frame_err_reg;
        parity_err_reg_out  = parity_err_reg;
    end
endmodule