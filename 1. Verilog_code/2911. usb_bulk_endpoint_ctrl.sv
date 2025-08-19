module usb_bulk_endpoint_ctrl #(
    parameter MAX_PACKET_SIZE = 64,
    parameter BUFFER_DEPTH = 8
)(
    input wire clk_i, rst_n_i,
    input wire [7:0] data_i,
    input wire data_valid_i,
    input wire token_received_i,
    input wire [3:0] endpoint_i,
    output reg [7:0] data_o,
    output reg data_valid_o,
    output reg buffer_full_o,
    output reg buffer_empty_o,
    output reg [1:0] response_o
);
    localparam IDLE = 2'b00, RX = 2'b01, TX = 2'b10, STALL = 2'b11;
    reg [1:0] state_r, next_state;
    reg [$clog2(BUFFER_DEPTH)-1:0] write_ptr, read_ptr;
    reg [$clog2(BUFFER_DEPTH):0] count;
    reg [7:0] buffer [0:BUFFER_DEPTH-1];
    
    always @(posedge clk_i or negedge rst_n_i) begin
        if (!rst_n_i) begin
            state_r <= IDLE;
            write_ptr <= 0;
            read_ptr <= 0;
            count <= 0;
            buffer_full_o <= 1'b0;
            buffer_empty_o <= 1'b1;
        end else begin
            state_r <= next_state;
            if (data_valid_i && !buffer_full_o && state_r == RX) begin
                buffer[write_ptr] <= data_i;
                write_ptr <= (write_ptr == BUFFER_DEPTH-1) ? 0 : write_ptr + 1;
                count <= count + 1;
            end
            buffer_full_o <= (count == BUFFER_DEPTH);
            buffer_empty_o <= (count == 0);
        end
    end
endmodule