//SystemVerilog
module QSPI_Quad_Mode #(
    parameter DDR_EN = 0
)(
    inout [3:0] io,
    input wire sck,
    input wire ddr_clk,
    output reg [31:0] rx_fifo,
    input [1:0] mode // 00:SPI, 01:dual, 10:quad
);

    // Pipeline registers for IO direction and data
    reg [3:0] io_dir_stage1, io_dir_stage2, io_dir_stage3, io_dir_stage4;
    reg [3:0] tx_data_stage1, tx_data_stage2, tx_data_stage3, tx_data_stage4;
    reg [3:0] rx_data_stage1, rx_data_stage2, rx_data_stage3, rx_data_stage4;
    reg [31:0] rx_fifo_stage1, rx_fifo_stage2, rx_fifo_stage3, rx_fifo_stage4, rx_fifo_stage5;

    // Pipeline registers for valid and mode
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    reg [1:0] mode_stage1, mode_stage2, mode_stage3, mode_stage4;

    // IO tri-state assignment (driven by stage4 for extra pipeline depth)
    assign io[0] = (io_dir_stage4[0]) ? tx_data_stage4[0] : 1'bz;
    assign io[1] = (io_dir_stage4[1]) ? tx_data_stage4[1] : 1'bz;
    assign io[2] = (io_dir_stage4[2]) ? tx_data_stage4[2] : 1'bz;
    assign io[3] = (io_dir_stage4[3]) ? tx_data_stage4[3] : 1'bz;

    // Stage 1: Mode decode and IO direction setup
    always @(posedge sck) begin
        case (mode)
            2'b00: begin // SPI
                io_dir_stage1 <= 4'b0001;
                tx_data_stage1 <= 4'b0000;
                rx_data_stage1[0] <= io[1];
                rx_data_stage1[3:1] <= 3'b000;
            end
            2'b01: begin // Dual
                io_dir_stage1 <= 4'b0011;
                tx_data_stage1 <= 4'b0000;
                rx_data_stage1[1:0] <= io[1:0];
                rx_data_stage1[3:2] <= 2'b00;
            end
            2'b10: begin // Quad
                io_dir_stage1 <= 4'b1111;
                tx_data_stage1 <= 4'b0000;
                rx_data_stage1 <= io;
            end
            default: begin
                io_dir_stage1 <= 4'b0000;
                tx_data_stage1 <= 4'b0000;
                rx_data_stage1 <= 4'b0000;
            end
        endcase
        mode_stage1 <= mode;
        valid_stage1 <= 1'b1;
    end

    // Stage 2: Register IO direction, data, mode, and valid
    always @(posedge sck) begin
        io_dir_stage2 <= io_dir_stage1;
        tx_data_stage2 <= tx_data_stage1;
        rx_data_stage2 <= rx_data_stage1;
        mode_stage2 <= mode_stage1;
        valid_stage2 <= valid_stage1;
    end

    // Stage 3: Separate IO direction/data/mode pipeline from FIFO logic
    always @(posedge sck) begin
        io_dir_stage3 <= io_dir_stage2;
        tx_data_stage3 <= tx_data_stage2;
        rx_data_stage3 <= rx_data_stage2;
        mode_stage3 <= mode_stage2;
        valid_stage3 <= valid_stage2;
    end

    // Stage 4: Further pipeline for IO and FIFO
    always @(posedge sck) begin
        io_dir_stage4 <= io_dir_stage3;
        tx_data_stage4 <= tx_data_stage3;
        rx_data_stage4 <= rx_data_stage3;
        mode_stage4 <= mode_stage3;
        valid_stage4 <= valid_stage3;
    end

    // Stage 5: FIFO update (only in quad mode, pipelined)
    always @(posedge sck) begin
        if (valid_stage4) begin
            if (mode_stage4 == 2'b10) begin
                rx_fifo_stage1 <= {rx_fifo[27:0], rx_data_stage4};
            end else begin
                rx_fifo_stage1 <= rx_fifo;
            end
        end else begin
            rx_fifo_stage1 <= rx_fifo;
        end
        valid_stage5 <= valid_stage4;
    end

    // Stage 6: FIFO output pipeline stage
    always @(posedge sck) begin
        rx_fifo_stage2 <= rx_fifo_stage1;
        rx_fifo_stage3 <= rx_fifo_stage2;
        rx_fifo_stage4 <= rx_fifo_stage3;
        rx_fifo_stage5 <= rx_fifo_stage4;
        rx_fifo <= rx_fifo_stage5;
    end

endmodule