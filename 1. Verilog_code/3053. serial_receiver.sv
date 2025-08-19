module serial_receiver(
    input wire clk, rst, rx_in,
    output reg [7:0] data_out,
    output reg valid
);
    localparam IDLE=3'd0, START=3'd1, DATA=3'd2, STOP=3'd3;
    reg [2:0] state, next_state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    always @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end
    
    always @(*) begin
        valid = 1'b0;
        next_state = state;
        
        case (state)
            IDLE: if (!rx_in) next_state = START;
            START: next_state = DATA;
            DATA: if (bit_count == 3'd7) next_state = STOP;
            STOP: begin valid = rx_in; next_state = IDLE; end
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin bit_count <= 0; shift_reg <= 0; end
        else if (state == DATA) begin
            shift_reg <= {rx_in, shift_reg[7:1]};
            bit_count <= bit_count + 1;
        end else if (state == STOP) begin
            data_out <= shift_reg;
            bit_count <= 0;
        end
    end
endmodule