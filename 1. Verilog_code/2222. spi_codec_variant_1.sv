//SystemVerilog
module spi_codec #(parameter DATA_WIDTH = 8)
(
    input wire clk_i, rst_ni, enable_i,
    input wire [DATA_WIDTH-1:0] tx_data_i,
    input wire miso_i,
    output wire sclk_o, cs_no, mosi_o,
    output reg [DATA_WIDTH-1:0] rx_data_o,
    output reg tx_done_o, rx_done_o
);
    // Main control registers
    reg [$clog2(DATA_WIDTH):0] bit_counter;
    reg [DATA_WIDTH-1:0] tx_shift_reg, rx_shift_reg;
    reg spi_active, sclk_enable;
    
    // Pipeline stage 1 registers
    reg enable_i_p1;
    reg spi_active_p1;
    reg sclk_enable_p1;
    reg [DATA_WIDTH-1:0] tx_shift_reg_p1;
    
    // Pipeline stage 2 registers
    reg enable_i_p2;
    reg spi_active_p2;
    reg sclk_enable_p2;
    reg [DATA_WIDTH-1:0] tx_shift_reg_p2;
    
    // Pipeline registers for data path 
    reg [DATA_WIDTH-1:0] rx_shift_reg_p1;
    reg [$clog2(DATA_WIDTH):0] bit_counter_p1;
    reg miso_i_p1;
    
    // Clock generation logic - pipelined with 2 stages
    assign sclk_o = enable_i_p2 & sclk_enable_p2 ? clk_i : 1'b0;
    assign cs_no = ~spi_active_p2;
    assign mosi_o = tx_shift_reg_p2[DATA_WIDTH-1];
    
    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            // Reset pipeline registers stage 1
            enable_i_p1 <= 1'b0;
            spi_active_p1 <= 1'b0;
            sclk_enable_p1 <= 1'b0;
            tx_shift_reg_p1 <= {DATA_WIDTH{1'b0}};
            rx_shift_reg_p1 <= {DATA_WIDTH{1'b0}};
            bit_counter_p1 <= 0;
            miso_i_p1 <= 1'b0;
            
            // Reset pipeline registers stage 2
            enable_i_p2 <= 1'b0;
            spi_active_p2 <= 1'b0;
            sclk_enable_p2 <= 1'b0;
            tx_shift_reg_p2 <= {DATA_WIDTH{1'b0}};
            
            // Reset main registers
            bit_counter <= 0;
            spi_active <= 1'b0;
            sclk_enable <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            rx_data_o <= 0;
            tx_done_o <= 1'b0;
            rx_done_o <= 1'b0;
        end else begin
            // Pipeline register updates - stage 1
            enable_i_p1 <= enable_i;
            spi_active_p1 <= spi_active;
            sclk_enable_p1 <= sclk_enable;
            tx_shift_reg_p1 <= tx_shift_reg;
            rx_shift_reg_p1 <= rx_shift_reg;
            bit_counter_p1 <= bit_counter;
            miso_i_p1 <= miso_i;
            
            // Pipeline register updates - stage 2
            enable_i_p2 <= enable_i_p1;
            spi_active_p2 <= spi_active_p1;
            sclk_enable_p2 <= sclk_enable_p1;
            tx_shift_reg_p2 <= tx_shift_reg_p1;
            
            // Transaction state machine
            if (enable_i && !spi_active) begin
                // Start new transaction
                tx_shift_reg <= tx_data_i;
                bit_counter <= 0;
                spi_active <= 1'b1;
                sclk_enable <= 1'b1;
                tx_done_o <= 1'b0;
                rx_done_o <= 1'b0;
            end else if (spi_active && bit_counter < DATA_WIDTH) begin
                // Split the shift operations to reduce logic depth
                // Shift tx register
                tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                
                // Shift rx register with pipelined MISO input
                rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], miso_i_p1};
                
                // Increment bit counter
                bit_counter <= bit_counter + 1'b1;
            end else if (bit_counter == DATA_WIDTH) begin
                // Transaction completion with pipelined data path
                spi_active <= 1'b0;
                sclk_enable <= 1'b0;
                rx_data_o <= {rx_shift_reg[DATA_WIDTH-2:0], miso_i_p1};
                tx_done_o <= 1'b1;
                rx_done_o <= 1'b1;
                bit_counter <= bit_counter + 1'b1;
            end
        end
    end
endmodule