//SystemVerilog
module crc_generator(
    input wire clk, rst, data_in, data_req,
    output reg [3:0] crc_out,
    output reg crc_ack
);
    localparam IDLE=1'b0, COMPUTE=1'b1;
    reg state, next;
    reg [3:0] crc_reg;
    reg [3:0] count;
    reg req_reg;
    
    wire feedback = crc_reg[3] ^ data_in;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            crc_reg <= 4'hF;
            count <= 4'd0;
            crc_ack <= 1'b0;
            req_reg <= 1'b0;
        end else begin
            state <= next;
            req_reg <= data_req;
            crc_ack <= (state == COMPUTE) && (count == 4'd7);
            
            if (state == IDLE) begin
                if (data_req && !req_reg) begin
                    crc_reg <= 4'hF;
                    count <= 4'd0;
                end
            end else if (state == COMPUTE) begin
                if (feedback) begin
                    crc_reg <= {crc_reg[2:0], 1'b0} ^ 4'h3;
                end else begin
                    crc_reg <= {crc_reg[2:0], 1'b0};
                end
                count <= count + 4'd1;
            end
        end
    end
    
    always @(*) begin
        crc_out = crc_reg;
        
        case (state)
            IDLE: begin
                if (data_req && !req_reg) begin
                    next = COMPUTE;
                end else begin
                    next = IDLE;
                end
            end
            COMPUTE: begin
                if (count == 4'd7) begin
                    next = IDLE;
                end else begin
                    next = COMPUTE;
                end
            end
        endcase
    end
endmodule