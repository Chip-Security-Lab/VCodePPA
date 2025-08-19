module dual_mode_spi(
    input clk, rst_n,
    input mode,         // 0: Standard, 1: Dual IO
    input [7:0] tx_data,
    input start,
    output reg [7:0] rx_data,
    output reg done,
    
    output reg sck,
    output reg cs_n,
    inout io0,          // MOSI in standard mode
    inout io1           // MISO in standard mode
);
    reg [7:0] tx_shift, rx_shift;
    reg [2:0] bit_count;
    reg io0_out, io1_out;
    reg io0_oe, io1_oe;   // Output enable
    
    // Tri-state buffer control
    assign io0 = io0_oe ? io0_out : 1'bz;
    assign io1 = io1_oe ? io1_out : 1'bz;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_shift <= 8'h00; rx_shift <= 8'h00;
            bit_count <= 3'h0; sck <= 1'b0;
            cs_n <= 1'b1; done <= 1'b0;
            io0_oe <= 1'b0; io1_oe <= 1'b0;
        end else if (start && cs_n) begin
            tx_shift <= tx_data;
            bit_count <= mode ? 3'h3 : 3'h7; // 4 or 8 bits
            cs_n <= 1'b0;
            io0_oe <= 1'b1;
            io1_oe <= mode ? 1'b1 : 1'b0;
        end else if (!cs_n) begin
            sck <= ~sck;
            if (sck) begin // Rising edge
                if (mode) begin
                    rx_shift <= {rx_shift[5:0], io1, io0};
                    bit_count <= (bit_count == 0) ? 0 : bit_count - 1;
                end else begin
                    rx_shift <= {rx_shift[6:0], io1};
                    bit_count <= (bit_count == 0) ? 0 : bit_count - 1;
                end
            end else begin // Falling edge
                if (mode) begin
                    io0_out <= tx_shift[1];
                    io1_out <= tx_shift[0];
                    tx_shift <= {tx_shift[5:0], 2'b00};
                end else begin
                    io0_out <= tx_shift[7];
                    tx_shift <= {tx_shift[6:0], 1'b0};
                end
                if (bit_count == 0) begin
                    cs_n <= 1'b1;
                    done <= 1'b1;
                    rx_data <= rx_shift;
                    io0_oe <= 1'b0;
                    io1_oe <= 1'b0;
                end
            end
        end else done <= 1'b0;
    end
endmodule