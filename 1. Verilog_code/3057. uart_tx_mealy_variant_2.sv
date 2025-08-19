//SystemVerilog
module uart_tx_mealy(
    input wire clk, rst_n,
    input wire tx_req,
    input wire [7:0] tx_data,
    output reg tx_ack,
    output reg tx_out
);
    localparam IDLE=0, START=1, DATA=2, STOP=3;
    reg [1:0] state, next_state;
    reg [2:0] bit_index;
    reg [7:0] data_reg;
    reg req_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            bit_index <= 0;
            data_reg <= 0;
            req_reg <= 0;
            tx_ack <= 0;
            tx_out <= 1'b1;
        end else begin
            state <= next_state;
            req_reg <= tx_req;
            
            if (state == IDLE && tx_req && !req_reg) begin
                data_reg <= tx_data;
                tx_ack <= 1;
                tx_out <= 1'b1;
            end else if (state == IDLE && !tx_req && req_reg) begin
                tx_ack <= 0;
                tx_out <= 1'b1;
            end else if (state == START) begin
                tx_out <= 1'b0;
            end else if (state == DATA) begin
                tx_out <= data_reg[bit_index];
                bit_index <= (bit_index == 3'd7) ? 3'd0 : bit_index + 3'd1;
            end else if (state == STOP) begin
                tx_out <= 1'b1;
            end else begin
                tx_out <= 1'b1;
            end
        end
    end
    
    always @(*) begin
        if (state == IDLE && tx_req && !req_reg) begin
            next_state = START;
        end else if (state == IDLE && !tx_req) begin
            next_state = IDLE;
        end else if (state == START) begin
            next_state = DATA;
        end else if (state == DATA && bit_index == 3'd7) begin
            next_state = STOP;
        end else if (state == DATA && bit_index != 3'd7) begin
            next_state = DATA;
        end else if (state == STOP) begin
            next_state = IDLE;
        end else begin
            next_state = IDLE;
        end
    end
endmodule