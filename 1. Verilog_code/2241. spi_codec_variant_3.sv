//SystemVerilog
// Top-level module
module spi_codec #(parameter DATA_WIDTH=8) (
    input clk, rst_n, en,
    input mosi, cs_n,
    output [DATA_WIDTH-1:0] rx_data,
    output data_valid
);
    // Internal signals
    wire mosi_sync, cs_n_sync, en_sync;
    wire [2:0] bit_cnt;
    
    // Input synchronizer module instance
    spi_input_sync input_sync_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mosi_in(mosi),
        .cs_n_in(cs_n),
        .en_in(en),
        .mosi_out(mosi_sync),
        .cs_n_out(cs_n_sync),
        .en_out(en_sync)
    );
    
    // Data processing module instance
    spi_data_processor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) data_proc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .mosi(mosi_sync),
        .cs_n(cs_n_sync),
        .en(en_sync),
        .rx_data(rx_data),
        .bit_cnt(bit_cnt),
        .data_valid(data_valid)
    );
    
endmodule

// Input synchronizer module
module spi_input_sync (
    input clk, rst_n,
    input mosi_in, cs_n_in, en_in,
    output reg mosi_out, cs_n_out, en_out
);
    // Register all inputs to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mosi_out <= 1'b0;
            cs_n_out <= 1'b1;
            en_out <= 1'b0;
        end else begin
            mosi_out <= mosi_in;
            cs_n_out <= cs_n_in;
            en_out <= en_in;
        end
    end
endmodule

// Data processing module
module spi_data_processor #(parameter DATA_WIDTH=8) (
    input clk, rst_n,
    input mosi, cs_n, en,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg [2:0] bit_cnt,
    output reg data_valid
);
    // SPI data bit counter and shift register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt <= 3'b000;
            rx_data <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else if (en && !cs_n) begin
            // Shift in data MSB first
            rx_data <= {rx_data[DATA_WIDTH-2:0], mosi};
            
            // Update bit counter
            bit_cnt <= (bit_cnt == DATA_WIDTH-1) ? 3'b000 : bit_cnt + 1'b1;
            
            // Assert data_valid when full byte received
            data_valid <= (bit_cnt == DATA_WIDTH-1);
        end else begin
            data_valid <= 1'b0;
        end
    end
endmodule