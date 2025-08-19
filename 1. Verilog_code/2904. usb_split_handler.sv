module usb_split_handler(
    input wire clk,
    input wire reset,
    input wire [3:0] hub_addr,
    input wire [3:0] port_num,
    input wire [7:0] transaction_type,
    input wire start_split,
    input wire complete_split,
    output reg [15:0] split_token,
    output reg token_valid,
    output reg [1:0] state
);
    localparam IDLE = 2'b00, START = 2'b01, WAIT = 2'b10, COMPLETE = 2'b11;
    reg [7:0] command_byte;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            token_valid <= 1'b0;
            split_token <= 16'h0000;
        end else begin
            case (state)
                IDLE: begin
                    if (start_split) begin
                        command_byte <= {transaction_type[1:0], 2'b00, port_num};
                        split_token <= {hub_addr, command_byte, 4'b0000}; // CRC5 omitted
                        token_valid <= 1'b1;
                        state <= START;
                    end else if (complete_split) begin
                        command_byte <= {transaction_type[1:0], 2'b10, port_num};
                        split_token <= {hub_addr, command_byte, 4'b0000}; // CRC5 omitted
                        token_valid <= 1'b1;
                        state <= COMPLETE;
                    end
                end
                START: begin
                    token_valid <= 1'b0;
                    state <= WAIT;
                end
                WAIT: begin
                    if (complete_split) begin
                        command_byte <= {transaction_type[1:0], 2'b10, port_num};
                        split_token <= {hub_addr, command_byte, 4'b0000}; // CRC5 omitted
                        token_valid <= 1'b1;
                        state <= COMPLETE;
                    end
                end
                COMPLETE: begin
                    token_valid <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule