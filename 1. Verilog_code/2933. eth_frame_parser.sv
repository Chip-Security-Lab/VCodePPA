module eth_frame_parser #(parameter BYTE_WIDTH = 8) (
    input wire clock,
    input wire reset,
    input wire data_valid,
    input wire [BYTE_WIDTH-1:0] rx_byte,
    output reg [47:0] dest_addr,
    output reg [47:0] src_addr,
    output reg [15:0] eth_type,
    output reg frame_valid
);
    localparam S_IDLE = 3'd0, S_PREAMBLE = 3'd1, S_SFD = 3'd2;
    localparam S_DEST = 3'd3, S_SRC = 3'd4, S_TYPE = 3'd5, S_DATA = 3'd6;
    
    reg [2:0] state;
    reg [3:0] byte_count;
    
    always @(posedge clock) begin
        if (reset) begin
            state <= S_IDLE;
            byte_count <= 4'd0;
            frame_valid <= 1'b0;
        end else if (data_valid) begin
            case (state)
                S_IDLE: state <= (rx_byte == 8'h55) ? S_PREAMBLE : S_IDLE;
                S_PREAMBLE: state <= (rx_byte == 8'h55) ? S_PREAMBLE : 
                                    (rx_byte == 8'hD5) ? S_SFD : S_IDLE;
                S_SFD: begin
                    state <= S_DEST;
                    byte_count <= 4'd0;
                end
                S_DEST: begin
                    dest_addr <= {dest_addr[39:0], rx_byte};
                    byte_count <= byte_count + 1;
                    if (byte_count == 5) begin
                        state <= S_SRC;
                        byte_count <= 4'd0;
                    end
                end
                S_SRC: begin
                    src_addr <= {src_addr[39:0], rx_byte};
                    byte_count <= byte_count + 1;
                    if (byte_count == 5) begin
                        state <= S_TYPE;
                        byte_count <= 4'd0;
                    end
                end
                S_TYPE: begin
                    eth_type <= {eth_type[7:0], rx_byte};
                    byte_count <= byte_count + 1;
                    if (byte_count == 1) begin
                        state <= S_DATA;
                        frame_valid <= 1'b1;
                    end
                end
                default: frame_valid <= 1'b0;
            endcase
        end
    end
endmodule