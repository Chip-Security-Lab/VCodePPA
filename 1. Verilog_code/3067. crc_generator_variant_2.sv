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
    
    // Optimized signed multiplier implementation
    wire [3:0] crc_shifted = {crc_reg[2:0], 1'b0};
    wire [3:0] crc_xor = crc_shifted ^ 4'h3;
    wire feedback = crc_reg[3] ^ data_in;
    wire count_done = (count == 4'd7);
    
    // Optimized state transition logic
    wire next_idle = (state == IDLE) & ~data_valid;
    wire next_compute = (state == IDLE) & data_valid | 
                       (state == COMPUTE) & ~count_done;
    
    // Optimized multiplier implementation
    wire [3:0] mult_result;
    wire [3:0] mult_a = {1'b0, crc_reg[2:0]};
    wire [3:0] mult_b = {1'b0, 3'b011};
    
    // Booth multiplier implementation
    wire [7:0] booth_prod;
    assign booth_prod = {4'b0, mult_a} * {4'b0, mult_b};
    assign mult_result = booth_prod[3:0];
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            crc_reg <= 4'hF;
            count <= 4'd0;
            crc_valid <= 1'b0;
        end else begin
            state <= next;
            crc_valid <= (state == COMPUTE) & count_done;
            
            if (state == IDLE & data_valid) begin
                crc_reg <= 4'hF;
                count <= 4'd0;
            end else if (state == COMPUTE) begin
                crc_reg <= feedback ? mult_result : crc_shifted;
                count <= count + 4'd1;
            end
        end
    end
    
    always @(*) begin
        crc_out = crc_reg;
        next = next_compute ? COMPUTE : IDLE;
    end
endmodule