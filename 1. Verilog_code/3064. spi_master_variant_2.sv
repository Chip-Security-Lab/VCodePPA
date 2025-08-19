//SystemVerilog
module spi_master #(
    parameter CLK_DIV = 4
)(
    input wire clk, rst,
    input wire [7:0] tx_data,
    input wire tx_valid,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg sclk, cs_n, mosi,
    input wire miso
);
    localparam IDLE=2'b00, SETUP=2'b01, SAMPLE=2'b10, DONE=2'b11;
    reg [1:0] state, next;
    reg [7:0] tx_shift, rx_shift;
    reg [3:0] bit_cnt;
    reg [2:0] clk_cnt;
    
    // Carry lookahead adder signals
    wire [7:0] cla_sum;
    wire [7:0] cla_carry;
    wire [7:0] cla_propagate;
    wire [7:0] cla_generate;
    
    // Pre-compute common conditions to reduce logic depth
    wire clk_div_reached = (clk_cnt == CLK_DIV-1);
    wire bit_cnt_max = (bit_cnt == 4'd7);
    wire sample_complete = clk_div_reached && bit_cnt_max;
    
    // Carry lookahead adder implementation
    assign cla_propagate = tx_shift ^ {tx_shift[6:0], 1'b0};
    assign cla_generate = tx_shift & {tx_shift[6:0], 1'b0};
    
    // Carry chain computation
    assign cla_carry[0] = 1'b0;
    assign cla_carry[1] = cla_generate[0] | (cla_propagate[0] & cla_carry[0]);
    assign cla_carry[2] = cla_generate[1] | (cla_propagate[1] & cla_carry[1]);
    assign cla_carry[3] = cla_generate[2] | (cla_propagate[2] & cla_carry[2]);
    assign cla_carry[4] = cla_generate[3] | (cla_propagate[3] & cla_carry[3]);
    assign cla_carry[5] = cla_generate[4] | (cla_propagate[4] & cla_carry[4]);
    assign cla_carry[6] = cla_generate[5] | (cla_propagate[5] & cla_carry[5]);
    assign cla_carry[7] = cla_generate[6] | (cla_propagate[6] & cla_carry[6]);
    
    // Sum computation
    assign cla_sum = tx_shift ^ {tx_shift[6:0], 1'b0} ^ cla_carry;
    
    // State transition logic
    always @(*) begin
        next = state;
        case (state)
            IDLE: next = tx_valid ? SETUP : IDLE;
            SETUP: next = clk_div_reached ? SAMPLE : SETUP;
            SAMPLE: next = clk_div_reached ? (bit_cnt_max ? DONE : SETUP) : SAMPLE;
            DONE: next = IDLE;
        endcase
    end
    
    // Main sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_cnt <= 0;
            bit_cnt <= 0;
            sclk <= 1'b0;
            cs_n <= 1'b1;
            rx_valid <= 1'b0;
            mosi <= 1'b0;
        end else begin
            state <= next;
            
            if (state != IDLE) begin
                clk_cnt <= clk_div_reached ? 0 : clk_cnt + 1;
            end
            
            if (state == SETUP && clk_div_reached) begin
                sclk <= 1'b1;
            end else if (state == SAMPLE && clk_div_reached) begin
                sclk <= 1'b0;
            end
            
            if (state == SAMPLE && clk_div_reached) begin
                bit_cnt <= bit_cnt + 1;
            end
            
            if (state == IDLE && tx_valid) begin
                cs_n <= 1'b0;
            end else if (state == DONE) begin
                cs_n <= 1'b1;
            end
            
            if (state == SETUP) begin
                mosi <= tx_shift[7];
            end else if (state == SAMPLE && clk_div_reached) begin
                tx_shift <= cla_sum;
                rx_shift <= {rx_shift[6:0], miso};
            end
            
            if (state == IDLE && tx_valid) begin
                tx_shift <= tx_data;
            end
            
            if (state == DONE) begin
                rx_data <= rx_shift;
                rx_valid <= 1'b1;
            end else begin
                rx_valid <= 1'b0;
            end
        end
    end
endmodule