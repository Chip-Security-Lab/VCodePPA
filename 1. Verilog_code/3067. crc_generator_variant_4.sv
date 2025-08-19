//SystemVerilog
module crc_generator(
    input wire clk, rst, data_in, data_valid,
    output reg [3:0] crc_out,
    output reg crc_valid
);
    localparam IDLE=1'b0, COMPUTE=1'b1;
    reg state, next;
    reg [3:0] crc_reg;
    reg [3:0] count;
    
    wire feedback = crc_reg[3] ^ data_in;
    wire [3:0] shifted_crc = {crc_reg[2:0], 1'b0};
    wire [3:0] crc_update = feedback ? (shifted_crc ^ 4'h3) : shifted_crc;
    wire count_done = (count == 4'd7);
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            crc_reg <= 4'hF;
            count <= 4'd0;
            crc_valid <= 1'b0;
        end else begin
            state <= next;
            crc_valid <= (state == COMPUTE) & count_done;
            
            case ({state, data_valid, count_done})
                3'b000: begin  // IDLE, ~data_valid
                    crc_reg <= crc_reg;
                    count <= count;
                end
                3'b010: begin  // IDLE, data_valid
                    crc_reg <= 4'hF;
                    count <= 4'd0;
                end
                3'b100: begin  // COMPUTE, ~count_done
                    crc_reg <= crc_update;
                    count <= count + 4'd1;
                end
                3'b101: begin  // COMPUTE, count_done
                    crc_reg <= crc_reg;
                    count <= count;
                end
                default: begin
                    crc_reg <= crc_reg;
                    count <= count;
                end
            endcase
        end
    end
    
    always @(*) begin
        crc_out = crc_reg;
        next = (state == IDLE & data_valid) | (state == COMPUTE & ~count_done) ? COMPUTE : IDLE;
    end
endmodule