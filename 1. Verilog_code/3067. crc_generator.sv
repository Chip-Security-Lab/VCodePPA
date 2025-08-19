module crc_generator(
    input wire clk, rst, data_in, data_valid,
    output reg [3:0] crc_out,
    output reg crc_valid
);
    localparam IDLE=1'b0, COMPUTE=1'b1;
    reg state, next;
    reg [3:0] crc_reg;
    reg [3:0] count;
    
    // CRC-4-ITU polynomial: x^4 + x + 1 (0x3)
    wire feedback = crc_reg[3] ^ data_in;
    
    always @(posedge clk)
        if (rst) begin
            state <= IDLE;
            crc_reg <= 4'hF; // Initial value
            count <= 4'd0;
            crc_valid <= 1'b0;
        end else begin
            state <= next;
            crc_valid <= (state == COMPUTE) && (count == 4'd7);
            
            if (state == IDLE && data_valid) begin
                crc_reg <= 4'hF;
                count <= 4'd0;
            end else if (state == COMPUTE) begin
                crc_reg <= {crc_reg[2:0], 1'b0};
                if (feedback) crc_reg <= {crc_reg[2:0], 1'b0} ^ 4'h3;
                count <= count + 4'd1;
            end
        end
    
    always @(*) begin
        crc_out = crc_reg;
        
        case (state)
            IDLE: next = data_valid ? COMPUTE : IDLE;
            COMPUTE: next = (count == 4'd7) ? IDLE : COMPUTE;
        endcase
    end
endmodule