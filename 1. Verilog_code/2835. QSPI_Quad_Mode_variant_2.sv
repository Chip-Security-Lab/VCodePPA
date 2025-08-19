//SystemVerilog
module QSPI_Quad_Mode #(
    parameter DDR_EN = 0
)(
    inout [3:0] io,
    input wire sck,
    input ddr_clk,
    output reg [31:0] rx_fifo,
    input [1:0] mode // 00:SPI, 01:dual, 10:quad
);

// Stage 1: IO direction and data capture
reg [3:0] io_dir_stage1;
reg [3:0] rx_data_stage1;
reg [3:0] tx_data_stage1;

// Stage 2: Data alignment and output logic
reg [3:0] rx_data_stage2;
reg [31:0] rx_fifo_stage2;

// Stage 3: FIFO shift and output register
reg [31:0] rx_fifo_stage3;

// IO tri-state control
assign io[0] = (io_dir_stage1[0]) ? tx_data_stage1[0] : 1'bz;
assign io[1] = (io_dir_stage1[1]) ? tx_data_stage1[1] : 1'bz;
assign io[2] = (io_dir_stage1[2]) ? tx_data_stage1[2] : 1'bz;
assign io[3] = (io_dir_stage1[3]) ? tx_data_stage1[3] : 1'bz;

// Stage 1: Capture IO direction and raw data
always @(posedge sck) begin
    case(mode)
        2'b00: io_dir_stage1 <= 4'b0001; // SPI
        2'b01: io_dir_stage1 <= 4'b0011; // Dual
        2'b10: io_dir_stage1 <= 4'b1111; // Quad
        default: io_dir_stage1 <= 4'b0000;
    endcase

    // Placeholder for transmit data (could be updated as needed)
    tx_data_stage1 <= 4'b0000;

    // Capture IO data
    case(mode)
        2'b00: begin
            rx_data_stage1[0] <= io[1];
            rx_data_stage1[3:1] <= rx_data_stage1[3:1];
        end
        2'b01: begin
            rx_data_stage1[1:0] <= io[1:0];
            rx_data_stage1[3:2] <= rx_data_stage1[3:2];
        end
        2'b10: begin
            rx_data_stage1 <= io;
        end
        default: begin
            rx_data_stage1 <= rx_data_stage1;
        end
    endcase
end

// Stage 2: Align captured data and prepare FIFO input
always @(posedge sck) begin
    case(mode)
        2'b00: begin
            rx_data_stage2 <= rx_data_stage1;
            rx_fifo_stage2 <= rx_fifo_stage3;
        end
        2'b01: begin
            rx_data_stage2 <= rx_data_stage1;
            rx_fifo_stage2 <= rx_fifo_stage3;
        end
        2'b10: begin
            rx_data_stage2 <= rx_data_stage1;
            rx_fifo_stage2 <= {rx_fifo_stage3[27:0], rx_data_stage1};
        end
        default: begin
            rx_data_stage2 <= rx_data_stage1;
            rx_fifo_stage2 <= rx_fifo_stage3;
        end
    endcase
end

// Stage 3: Output FIFO register
always @(posedge sck) begin
    rx_fifo_stage3 <= rx_fifo_stage2;
end

// Output assignment
always @(posedge sck) begin
    rx_fifo <= rx_fifo_stage3;
end

endmodule