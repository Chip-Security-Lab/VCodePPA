//SystemVerilog
module uart_tx_mealy(
    input wire clk, rst_n,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_busy, tx_out
);
    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state, next_state;
    reg [2:0] bit_index;
    reg [7:0] data_reg;
    wire bit_index_max;
    
    assign bit_index_max = (bit_index == 3'd7);
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            bit_index <= 0;
            data_reg <= 0;
        end else begin
            state <= next_state;
            if (state == IDLE && tx_start)
                data_reg <= tx_data;
            if (state == DATA)
                bit_index <= bit_index_max ? 3'd0 : bit_index + 3'd1;
        end
    
    always @(*) begin
        tx_busy = |state;
        
        case (state)
            IDLE: begin 
                tx_out = 1'b1; 
                next_state = tx_start ? START : IDLE; 
            end
            START: begin 
                tx_out = 1'b0; 
                next_state = DATA; 
            end
            DATA: begin 
                tx_out = data_reg[bit_index]; 
                next_state = bit_index_max ? STOP : DATA;
            end
            STOP: begin 
                tx_out = 1'b1; 
                next_state = IDLE; 
            end
        endcase
    end
endmodule