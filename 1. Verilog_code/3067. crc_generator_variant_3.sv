//SystemVerilog
module crc_generator(
    input wire clk, rst, data_in, data_valid,
    output reg [3:0] crc_out,
    output reg crc_valid
);
    localparam IDLE=1'b0, COMPUTE=1'b1;
    reg state;
    reg [3:0] crc_reg;
    reg [3:0] count;
    reg [3:0] crc_out_reg;
    reg crc_valid_reg;
    
    // CRC-4-ITU polynomial: x^4 + x + 1 (0x3)
    wire feedback = crc_reg[3] ^ data_in;
    wire [3:0] next_crc;
    wire [3:0] next_count;
    wire next_crc_valid;
    wire next;
    
    // Combinational logic
    assign next_crc = (state == IDLE && data_valid) ? 4'hF :
                     (state == COMPUTE) ? 
                     (feedback ? {crc_reg[2:0], 1'b0} ^ 4'h3 : {crc_reg[2:0], 1'b0}) :
                     crc_reg;
                     
    assign next_count = (state == IDLE && data_valid) ? 4'd0 :
                       (state == COMPUTE) ? count + 4'd1 :
                       count;
                       
    assign next_crc_valid = (state == COMPUTE) && (count == 4'd7);
    
    assign next = (state == IDLE) ? (data_valid ? COMPUTE : IDLE) :
                 (state == COMPUTE) ? ((count == 4'd7) ? IDLE : COMPUTE) :
                 state;
    
    // Sequential logic
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            crc_reg <= 4'hF;
            count <= 4'd0;
            crc_valid_reg <= 1'b0;
            crc_out_reg <= 4'hF;
        end else begin
            state <= next;
            crc_reg <= next_crc;
            count <= next_count;
            crc_valid_reg <= next_crc_valid;
            crc_out_reg <= crc_reg;
        end
    end
    
    // Output assignment
    assign crc_out = crc_out_reg;
    assign crc_valid = crc_valid_reg;
endmodule